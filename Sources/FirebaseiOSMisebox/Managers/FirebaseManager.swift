//
//  File.swift
//  
//
//  Created by Daniel Watson on 22.01.24.
//

import Foundation
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
     
    public func fetchDataDocument<T: FirestoreDataProtocol>(collection: String, documentID: String, completion: @escaping (Result<T, Error>) -> Void) {
          let docRef = db.collection(collection).document(documentID)
          docRef.getDocument { documentSnapshot, error in
              if let error = error {
                  completion(.failure(error))
                  return
              }
              guard let documentSnapshot = documentSnapshot,
                    let dataModel = T(documentSnapshot: documentSnapshot) else {
                  completion(.failure(FirestoreError.documentNotFound))
                  return
              }
              completion(.success(dataModel))
          }
      }
  
    public func fetchDocument<T: FirestoreEntity>(for entity: T) async throws -> T? {
          let docRef = documentReference(forCollection: entity.collection, documentID: entity.id)
          let documentSnapshot = try await docRef.getDocument()
          
          if documentSnapshot.exists {
              return T(documentSnapshot: documentSnapshot)
          } else {
              return nil
          }
      }
    @discardableResult
    public func updateDocument<T: FirestoreEntity>(for entity: T, merge: Bool = true) async -> Result<Void, Error> {
        let docRef = documentReference(forCollection: entity.collection, documentID: entity.id)
        let updateData = entity.toFirestore()
        
        do {
            try await docRef.setData(updateData, merge: merge)
            return .success(())
        } catch let error {
            print("FirestoreManager[updateDocument] Error updating document: \(error.localizedDescription)")
            return .failure(error)
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
    @discardableResult
    public func updateDocumentField(collection: String, documentID: String, data: [String: Any], merge: Bool = true) async -> Result<Void, Error> {
            let docRef = db.collection(collection).document(documentID)
            
            do {
                try await docRef.setData(data, merge: merge)
                print("[FirestoreManager] Document successfully updated.")
                return .success(())
            } catch let error {
                print("[FirestoreManager] Error updating document: \(error.localizedDescription)")
                return .failure(error)
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
    // simple version, eg for posts
    @discardableResult
    public func addDocument(toCollection collection: String, withData data: [String: Any]) async throws -> DocumentReference {
          do {
              let documentReference = try await db.collection(collection).addDocument(data: data)
              print("Document added with ID: \(documentReference.documentID)")
              return documentReference
          } catch let error {
              print("Error adding document: \(error.localizedDescription)")
              throw error
          }
      }
    public func setDoc<T: FirestoreEntity>(entity: T) async throws {
        let docRef = db.collection(entity.collection).document(entity.id)
        print("Document Reference: \(docRef.path)")
        try await docRef.setData(entity.toFirestore())
    }
    
    public func isFieldValueUnique(inCollection collection: String, fieldName: String, fieldValue: String) async throws -> Bool {
          let querySnapshot = try await db.collection(collection).whereField(fieldName, isEqualTo: fieldValue).getDocuments()
          // If the query returns no documents, the field value is unique
          return querySnapshot.documents.isEmpty
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
    
    public func listenToPosts<T: FeedPost>(forRoles roles: [String], completion: @escaping (Result<[T], Error>) -> Void) -> ListenerRegistration {
        // Print the roles we're querying for, for debugging purposes
        print("Listening to posts for roles: \(roles)")
        
        let query = db.collection("posts").whereField("role", in: roles)
        
        return query.addSnapshotListener { querySnapshot, error in
            // Debugging: Check if there's an error
            if let error = error {
                print("Error fetching posts: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            // Debugging: Check the snapshot state
            guard let snapshot = querySnapshot else {
                print("Snapshot is nil. There might be a problem with the query or Firestore permissions.")
                completion(.failure(NSError(domain: "FeedManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Snapshot is nil."])))
                return
            }
            
            // Debugging: Print the number of documents fetched
            print("Fetched \(snapshot.documents.count) documents for roles: \(roles)")
            
            let posts: [T] = snapshot.documents.compactMap { documentSnapshot in
                // Debugging: Print each document id fetched
                print("Processing document with id: \(documentSnapshot.documentID)")
                return T(document: documentSnapshot)
            }
            
            // Debugging: Check if posts are successfully mapped
            if posts.isEmpty && !snapshot.documents.isEmpty {
                print("Posts are empty after mapping, but documents were fetched. Check the FeedPost initializer.")
            }
            
            completion(.success(posts))
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

public protocol FeedPost: Identifiable {
    init?(document: DocumentSnapshot)
    func toFirestore() -> [String: Any]
}

public protocol FirestoreDataProtocol {
    init?(documentSnapshot: DocumentSnapshot)
    func update(with data: [String: Any])
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

