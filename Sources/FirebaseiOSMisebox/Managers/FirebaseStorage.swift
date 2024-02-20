//
//  File.swift
//  
//
//  Created by Daniel Watson on 20.02.2024.
//

import FirebaseStorage
import SwiftUI

class FirebaseStorageManager {
    static let shared = FirebaseStorageManager()

    private init() {}

    func uploadImage(imageData: Data, inDirectory directory: String, completion: @escaping (Result<String, Error>) -> Void) async {
        let uid = generateShortUID(length: 6)
        let fileName = "\(uid).jpg"
        let storageRef = Storage.storage().reference()
        let imagePath = "\(directory)/\(fileName)"
        let imageRef = storageRef.child(imagePath)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        do {
            _ = try await imageRef.putDataAsync(imageData, metadata: metadata)
            let downloadURL = try await imageRef.downloadURL()
            completion(.success(downloadURL.absoluteString))
        } catch {
            completion(.failure(error))
        }
    }

    private func generateShortUID(length: Int) -> String {
        return UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(length).lowercased()
    }

    // Additional storage utility methods can be added here
}

