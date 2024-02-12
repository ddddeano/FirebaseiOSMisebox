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
// MARK: - Account Creation
extension AuthenticationManager {
    @discardableResult
    public func signInWithGoogle(tokens: GoogleSignInResultModel) async throws -> FirebaseUser {
        let credential = GoogleAuthProvider.credential(withIDToken: tokens.idToken, accessToken: tokens.accessToken)
        let authResult = try await Auth.auth().signIn(with: credential)
        return FirebaseUser(user: authResult.user)
    }
}

// MARK: - Account Linking
extension AuthenticationManager {
    
    @discardableResult
    func linkEmail(email: String, password: String) async throws -> FirebaseUser {
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        return try await linkCredential(credential: credential)
    }
    
    func linkGoogle(tokens: GoogleSignInResultModel) async throws -> FirebaseUser {
        let credential = GoogleAuthProvider.credential(withIDToken: tokens.idToken, accessToken: tokens.accessToken)
        return try await linkCredential(credential: credential)
    }
    
    func linkApple(tokens: SignInWithAppleResult) async throws -> FirebaseUser {
        let credential = OAuthProvider.credential(withProviderID: AuthProviderOption.apple.rawValue, idToken: tokens.token, rawNonce: tokens.nonce)
        return try await linkCredential(credential: credential)
    }
    
    private func linkCredential(credential: AuthCredential) async throws -> FirebaseUser {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badURL)
        }
        
        let authDataResult = try await user.link(with: credential)
        return FirebaseUser(user: authDataResult.user)
    }
}

// MARK: - Helpers
extension AuthenticationManager {
    
    public enum AuthenticationMethod {
        case anon
        case email
        case google
        case apple
    }
    
    public struct GoogleSignInResultModel {
        public let idToken: String
        public let accessToken: String
        public let name: String?
        public let email: String?
    }
    public enum AuthProviderOption: String {
        case email = "password"
        case google = "google.com"
        case apple = "apple.com"
    }
}

