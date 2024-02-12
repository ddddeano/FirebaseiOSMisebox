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

    public func signOut() async {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error)")
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
    
    @discardableResult
    func signInWithGoogle(tokens: GoogleSignInResultModel) async throws -> FirebaseUser {
        let credential = GoogleAuthProvider.credential(withIDToken: tokens.idToken, accessToken: tokens.accessToken)
        let authResult = try await Auth.auth().signIn(with: credential)
        return FirebaseUser(user: authResult.user)
    }
    
    @discardableResult
    public func linkGoogleAccount(_ idToken: String, _ accessToken: String) async throws -> FirebaseUser {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "AuthenticationManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No current user available for linking."])
        }
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        let authResult = try await currentUser.link(with: credential)
        return FirebaseUser(user: authResult.user)
    }
}

// MARK: - Helpers
extension AuthenticationManager {
    
    public enum AuthenticationMethod {
        case anon
        case email
        case google
        case apple
        case other
    }
    
    public struct GoogleSignInResultModel {
        let idToken: String
        let accessToken: String
        let name: String?
        let email: String?
    }
}

