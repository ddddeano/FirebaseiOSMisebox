//  StaticFirestoreManager.swift
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
    
    public static func updateArray(
        collection: String,
        documentID: String,
        arrayName: String,
        matchKey: String,
        matchValue: String,
        updateKey: String,
        newValue: Any
    ) async throws {
        let documentRef = documentReference(forCollection: collection, documentID: documentID)
        let snapshot = try await documentRef.getDocument()
        
        guard var array = snapshot.data()?[arrayName] as? [[String: Any]] else {
            throw FirestoreError.invalidSnapshot
        }
        
        for (index, var dict) in array.enumerated() where dict[matchKey] as? String == matchValue {
            dict[updateKey] = newValue
            array[index] = dict
        }
        
        try await documentRef.updateData([arrayName: array])
    }
}
