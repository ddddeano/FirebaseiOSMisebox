//
//  File.swift
//  
//
//  Created by Daniel Watson on 22.01.24.
//

import Foundation
import Combine
import Firebase
import FirebaseStorage
import FirebaseFirestore

public class FirestoreManager {
    private let db = Firestore.firestore()
    public init() {}

    public enum FirestoreError: Error {
        case unknown, invalidSnapshot, networkError, documentNotFound
    }
    
    private func documentReference(forCollection collection: String, documentID: String) -> DocumentReference {
         return db.collection(collection).document(documentID)
     }
     
    func fetchDocument<T: FirestoreEntity>(for entity: T) async throws -> T? {
          let docRef = documentReference(forCollection: entity.collection, documentID: entity.id)
          let documentSnapshot = try await docRef.getDocument()
          
          if documentSnapshot.exists {
              return T(documentSnapshot: documentSnapshot)
          } else {
              return nil
          }
      }
    
    public func updateDocument<T: FirestoreEntity>(for entity: T, merge: Bool = true) async throws {
        let docRef = documentReference(forCollection: entity.collection, documentID: entity.id)
        let updateData = entity.toFirestore()
        
        do {
            try await docRef.setData(updateData, merge: merge)
        } catch let error {
            print("FirestoreManager[updateDocument] Error updating document: \(error.localizedDescription)")
            throw error
        }
    }


    public func updateDocumentData<T: FirestoreEntity, U: Updatable>(for entity: T, with updateData: U, merge: Bool = true) async throws {
        let docRef = documentReference(forCollection: entity.collection, documentID: entity.id)
        let data = updateData.toFirestore()
        
        do {
            try await docRef.setData(data, merge: merge)
        } catch let error {
            print("FirestoreUpdateManager[updateDocument] Error updating document: \(error.localizedDescription)")
            throw error
        }
    }
    
    public func checkDocumentExists(collection: String, documentID: String) async throws -> Bool {
        let docRef = db.collection(collection).document(documentID)
        let documentSnapshot = try await docRef.getDocument()
        return documentSnapshot.exists
    }
    
    // Add a new document to the specified collection
    public func createDoc<T: FirestoreEntity>(entity: T) async throws -> String {
        do {
            let document = try await db.collection(entity.collection).addDocument(data: entity.toFirestore())
            return document.documentID
        } catch {
            throw error // Re-throw the error to be handled by the caller
        }
    }
    
    public func setDoc<T: FirestoreEntity>(entity: T) async throws {
        let docRef = db.collection(entity.collection).document(entity.id)
        print("Document Reference: \(docRef.path)")
        try await docRef.setData(entity.toFirestore())
    }
    
    
    /*@discardableResult
    public func createFeedEntry<T: Postable>(entry: T) async throws -> String {
        do {
            let document = try await db.collection("posts").addDocument(data: entry.toFeedEntry())
            print("Post entry created successfully. Document ID: \(document.documentID)")
            print("Entry details: \(entry.toFeedEntry())")
            return document.documentID
        } catch {
            print("Error creating feed entry: \(error)")
            throw error
        }
    }*/
    
    public func addDocumentListener<T: Listenable>(for entity: T, completion: @escaping (Result<T, Error>) -> Void) -> ListenerRegistration {
        let docRef = db.collection(entity.collection).document(entity.id)
        print("Setting up listener for document: \(entity.collection)/\(entity.id)")
        return docRef.addSnapshotListener { documentSnapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Firestore error for document \(entity.collection)/\(entity.id): \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                guard let document = documentSnapshot else {
                    print("DocumentSnapshot is nil for document \(entity.collection)/\(entity.id)")
                    completion(.failure(NSError(domain: "FirestoreManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "DocumentSnapshot is nil"])))
                    return
                }
                if !document.exists {
                    print("Document \(entity.collection)/\(entity.id) does not exist.")
                    completion(.failure(NSError(domain: "FirestoreManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Document does not exist"])))
                    return
                }
                guard let data = document.data() else {
                    print("No data found in document \(entity.collection)/\(entity.id)")
                    completion(.failure(NSError(domain: "FirestoreManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data found"])))
                    return
                }
                print("[addDocumentListener]Received document data for \(entity.collection)/\(entity.id): \(data)")
                var updatedEntity = entity
                updatedEntity.update(with: data)
                completion(.success(updatedEntity))
            }
        }
    }

    
    public func addCollectionListener<T: FirestoreEntity>(collection: String, completion: @escaping (Result<[T], Error>) -> Void) -> ListenerRegistration {
        let collectionRef = db.collection(collection)
        return collectionRef.addSnapshotListener { querySnapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let snapshot = querySnapshot else {
                completion(.failure(NSError(domain: "FirestoreManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Snapshot is nil"])))
                return
            }
            var entities = [T]()
            for document in snapshot.documents {
                if let entity = T(documentSnapshot: document) {
                    entities.append(entity)
                }
            }
            completion(.success(entities))
        }
    }
    
    public func deleteDocument(collection: String, documentID: String) async throws {
        let docRef = db.collection(collection).document(documentID)
        do {
            try await docRef.delete()
        } catch {
            print("Firestore error in deleteDocument: \(error)")
        }
    }
    
    public func fetchBucket(bucket: String) async throws -> [String] {
        let storage = Storage.storage()
        let storageReference = storage.reference().child(bucket) // Adjust the path as necessary
        
        let result = try await storageReference.listAll()
        
        return try await withThrowingTaskGroup(of: String?.self, returning: [String].self) { group in
            var urls = [String]()
            
            for item in result.items {
                group.addTask {
                    let url = try? await item.downloadURL()
                    return url?.absoluteString
                }
            }
            
            for try await url in group {
                if let url = url {
                    urls.append(url)
                }
            }
            return urls
        }
    }
}

public protocol FirestoreEntity {
    var doc: String { get }
    var collection: String { get }
    var id: String { get set }
    init?(documentSnapshot: DocumentSnapshot)
    func toFirestore() -> [String: Any]
}

public protocol Listenable: FirestoreEntity {
    mutating func update(with data: [String: Any])
}

public func fireObject<T>(from dictionaryData: [String: Any], using initializer: (Dictionary<String, Any>) -> T?) -> T? {
    return initializer(dictionaryData)
}
public func fireArray<T>(from arrayData: [[String: Any]], using initializer: (Dictionary<String, Any>) -> T?) -> [T] {
    return arrayData.compactMap(initializer)
}

