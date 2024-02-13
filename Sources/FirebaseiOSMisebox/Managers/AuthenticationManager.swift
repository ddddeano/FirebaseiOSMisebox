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

// MARK: - Account Processing

extension AuthenticationManager {
    @discardableResult
    public func signInOrCreateWithEmail(email: String, password: String) async throws -> FirebaseUser {
        do {
            return try await signInUser(email: email, password: password)
        } catch let error as NSError {
            if error.code == AuthErrorCode.userNotFound.rawValue {
                return try await createWithEmail(email: email, password: password)
            } else {
                throw error
            }
        }
    }
}

// MARK: - Account Creation
extension AuthenticationManager {
    @discardableResult
    public func createWithEmail(email: String, password: String) async throws -> FirebaseUser {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        return FirebaseUser(user: authResult.user)
    }

    @discardableResult
    public func withGoogle(tokens: GoogleSignInResultModel) async throws -> FirebaseUser {
        let credential = GoogleAuthProvider.credential(withIDToken: tokens.idToken, accessToken: tokens.accessToken)
        let authResult = try await Auth.auth().signIn(with: credential)
        return FirebaseUser(user: authResult.user)
    }
}

// MARK: - Account Return
extension AuthenticationManager {
    public func signInUser(email: String, password: String) async throws -> FirebaseUser {
        let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
        return FirebaseUser(user: authResult.user)
    }
}
// MARK: - Account Linking
extension AuthenticationManager {
    
    @discardableResult
    public func linkEmail(email: String, password: String) async throws -> FirebaseUser {
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        return try await linkCredential(credential: credential)
    }
    @discardableResult
    public func linkGoogle(tokens: GoogleSignInResultModel) async throws -> FirebaseUser {
        let credential = GoogleAuthProvider.credential(withIDToken: tokens.idToken, accessToken: tokens.accessToken)
        return try await linkCredential(credential: credential)
    }
    @discardableResult
    public func linkApple(tokens: SignInWithAppleResult) async throws -> FirebaseUser {
        let credential = OAuthProvider.credential(withProviderID: AuthenticationMethod.apple.rawValue, idToken: tokens.token, rawNonce: tokens.nonce)
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
    
    public enum AuthenticationMethod: String {
        case anon = "anonymous"
        case email = "email"
        case google = "google.com"
        case apple = "apple.com"
    }

    
    public struct GoogleSignInResultModel {
        public let idToken: String
        public let accessToken: String
        public let name: String?
        public let email: String?
    }
}

