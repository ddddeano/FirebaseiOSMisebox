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
        let authResultData = try await Auth.auth().signInAnonymously()
        return FirebaseUser(user: authResultData.user)
    }

    public func signOut() throws {
        try Auth.auth().signOut()
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
    
    public enum AuthenticationMethod {
        case anon
        case email(String, String) // Email, Password
        case google(String, String) // ID Token, Access Token
        case apple(String, String) // ID Token, Raw Nonce
        case other(String) // For extending with other providers in the future
    }
    
    @discardableResult
    public func linkAccount(method: AuthenticationMethod) async throws -> FirebaseUser {
        switch method {
        case .email(let email, let password):
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            return try await performLinking(credential: credential)
        
        case .google(let idToken, let accessToken):
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            return try await performLinking(credential: credential)
        
        case .apple(let idToken, let rawNonce):
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idToken, rawNonce: rawNonce)
            return try await performLinking(credential: credential)
        
        case .anon, .other:
            throw NSError(domain: "AuthenticationManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unsupported method for linking."])
        }
    }
    
    private func performLinking(credential: AuthCredential) async throws -> FirebaseUser {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "AuthenticationManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No current user available for linking."])
        }
        let authResult = try await currentUser.link(with: credential)
        return FirebaseUser(user: authResult.user)
    }
}
