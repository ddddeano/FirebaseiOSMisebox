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
    
    // MARK: - Enums
    
    public enum FirestoreError: Error {
        case unknown, invalidSnapshot, networkError, documentNotFound
    }
    
    public static func documentReference(forCollection collection: String, documentID: String) -> DocumentReference {
        return db.collection(collection).document(documentID)
    }
    public static func getDependentArray(forCollection collection: String, documentID: String, fieldName: String) async throws -> [[String: Any]] {
        let documentRef = db.collection(collection).document(documentID)
        let documentSnapshot = try await documentRef.getDocument()
        

        let dependentArray = documentSnapshot.data()?[fieldName] as? [[String: Any]] ?? []
        
        return dependentArray
    }
}
