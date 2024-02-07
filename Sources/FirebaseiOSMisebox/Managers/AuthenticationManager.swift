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
            // User is already signed in
            return FirebaseUser(user: currentUser)
        } else {
            // No user signed in, proceed with anonymous sign-in
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
             // Handle any additional cleanup or state reset here
         } catch let signOutError as NSError {
             print("Error signing out: %@", signOutError)
             // Handle errors (e.g., update state, send notifications)
         }
     }
}

// MARK: Sign IN Email

extension AuthenticationManager {
    public func createUser(email: String, password: String) async throws -> FirebaseUser {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        return FirebaseUser(user: authResult.user)
    }

    public func signInUser(email: String, password: String) async throws -> FirebaseUser {
        let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
        return FirebaseUser(user: authResult.user)
    }
    
    public func linkEmailToUser(email: String, password: String, user: User) async throws -> FirebaseUser {
        do {
            let linkedUser = try await linkEmail(email: email, password: password)
            return linkedUser
        } catch {
            print("Error linking email to user: \(error.localizedDescription)")
            throw error
        }
    }
    @discardableResult
    public func linkEmail(email: String, password: String) async throws -> FirebaseUser {
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        guard let currentUser = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }
        let authResult = try await currentUser.link(with: credential)
        return FirebaseUser(user: authResult.user)
    }
}

// MARK: Sign IN SSO

extension AuthenticationManager {
 
    public struct GoogleSignInResultModel {
        public let idToken: String
        public let accessToken: String
        
        public init (idToken: String, accessToken: String) {
            self.idToken = idToken
            self.accessToken = accessToken
        }
    }
    
    public func signInWithGoogle(tokens: GoogleSignInResultModel) async throws -> FirebaseUser {
        let credential = GoogleAuthProvider.credential(withIDToken: tokens.idToken, accessToken: tokens.accessToken)
        return try await signIn(credential: credential)
    }
    public func signIn(credential: AuthCredential) async throws -> FirebaseUser {
        let authDataResult = try await Auth.auth().signIn(with: credential)
        return FirebaseUser(user: authDataResult.user)
    }
}
