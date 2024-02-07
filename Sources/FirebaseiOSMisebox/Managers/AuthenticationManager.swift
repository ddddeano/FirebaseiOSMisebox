//
//  File.swift
//  
//
//  Created by Daniel Watson on 22.01.24.
//

import Foundation
import Firebase
import FirebaseAuth

public class AuthenticationManager: ObservableObject {
    
    public struct FirebaseUser {
        public let uid: String
        public let email: String?
        public let photoUrl: String?
        public let isAnon: Bool

        public init(user: User) {
            self.uid = user.uid
            self.email = user.email
            self.photoUrl = user.photoURL?.absoluteString
            self.isAnon = user.isAnonymous
        }
    }
    
    @Published public var authError: Error?
    
    public init() {}
    
    public func authenticate() async throws -> FirebaseUser {
        if let currentUser = Auth.auth().currentUser {
            return FirebaseUser(user: currentUser)
        } else {
            return try await signInAnon()
        }
    }
    
    @discardableResult
    public func signInAnon() async throws -> FirebaseUser {
        let authResultData =  try await Auth.auth().signInAnonymously()
        return FirebaseUser(user: authResultData.user)
    }

 
    public func signOut() {
         do {
             try Auth.auth().signOut()
         } catch let signOutError as NSError {
             print("Error signing out: %@", signOutError)
         }
     }
    public func deleteCurrentUser() async throws {
          guard let user = Auth.auth().currentUser else {
              throw URLError(.badURL)
          }
          try await user.delete()
      }
}

// MARK: - Account Linking
extension AuthenticationManager {
    
    public enum AuthProviderOption: String {
          case email = "password"
          case google = "google.com"
          case apple = "apple.com"
      }
    @discardableResult
    public func linkEmail(email: String, password: String) async throws -> FirebaseUser {
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        return try await linkAccount(credential: credential)
    }

    @discardableResult
    public func linkGoogle(idToken: String, accessToken: String) async throws -> FirebaseUser {
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        return try await linkAccount(credential: credential)
    }

    @discardableResult
    public func linkApple(idToken: String, rawNonce: String) async throws -> FirebaseUser {
        let credential = OAuthProvider.credential(withProviderID: AuthProviderOption.apple.rawValue,
                                                   idToken: idToken,
                                                   rawNonce: rawNonce)
        return try await linkAccount(credential: credential)
    }

    private func linkAccount(credential: AuthCredential) async throws -> FirebaseUser {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "AuthenticationManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No current user available for linking."])
        }
        let authResult = try await currentUser.link(with: credential)
        return FirebaseUser(user: authResult.user)
    }
}
