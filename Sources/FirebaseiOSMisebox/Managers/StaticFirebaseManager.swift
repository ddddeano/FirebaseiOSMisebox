//
//  File.swift
//  
//
//  Created by Daniel Watson on 05.02.2024.
//

import Foundation
import FirebaseFirestore

public class StaticFirestoreManager {
    private static let db = Firestore.firestore()
    
    public enum FirestoreError: Error {
        case unknown, invalidSnapshot, networkError, documentNotFound
    }
    
    public static func documentReference(forCollection collection: String, documentID: String) -> DocumentReference {
        return db.collection(collection).document(documentID)
    }
        
    public static func getDocumentSnapshot(collection: String, documentID: String) async throws -> DocumentSnapshot {
        let documentRef = documentReference(forCollection: collection, documentID: documentID)
        return try await documentRef.getDocument()
    }
    
    public static func getFieldData<T>(collection: String, documentID: String, fieldName: String) async throws -> T? {
        let snapshot = try await getDocumentSnapshot(collection: collection, documentID: documentID)
        return snapshot.data()?[fieldName] as? T
    }
        
    public static func updateArray<T>(
        collection: String,
        documentID: String,
        arrayName: String,
        updateBlock: @escaping ([T]) -> [T]
    ) async throws {
        let snapshot = try await getDocumentSnapshot(collection: collection, documentID: documentID)
        
        guard var array = snapshot.data()?[arrayName] as? [T] else {
            throw FirestoreError.invalidSnapshot
        }
        
        array = updateBlock(array)
        
        let documentRef = documentReference(forCollection: collection, documentID: documentID)
        try await documentRef.updateData([arrayName: array])
    }
}
