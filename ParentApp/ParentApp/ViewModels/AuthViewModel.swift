import SwiftUI
import AuthenticationServices
import SharedMessaging
import CryptoKit

@MainActor
class AuthViewModel: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentProfile: Profile?
    @Published var needsProfileSetup = false

    private let userType: UserType
    private var currentNonce: String?

    init(userType: UserType) {
        self.userType = userType
    }

    func checkAuthStatus() async {
        do {
            currentProfile = try await SupabaseClient.shared.currentUser()
            isAuthenticated = currentProfile != nil
        } catch {
            isAuthenticated = false
        }
    }

    func signInWithApple() {
        let nonce = randomNonceString()
        currentNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    func createProfile(fullName: String, email: String) async {
        isLoading = true
        error = nil

        do {
            let profile = try await SupabaseClient.shared.createProfile(
                fullName: fullName,
                email: email,
                userType: userType,
                appleUserId: nil
            )

            currentProfile = profile

            // Initialize encryption keys
            let messagingService = MessagingService(deviceId: UIDevice.current.identifierForVendor!.uuidString)
            try await messagingService.initializeKeys(for: profile.id)

            isAuthenticated = true
            needsProfileSetup = false
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func signOut() async {
        do {
            try await SupabaseClient.shared.signOut()
            isAuthenticated = false
            currentProfile = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }

        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            error = "Failed to get Apple ID credentials"
            return
        }

        Task {
            isLoading = true
            error = nil

            do {
                let profile = try await SupabaseClient.shared.signInWithApple(
                    idToken: idTokenString,
                    nonce: nonce
                )

                currentProfile = profile

                // Initialize encryption keys if needed
                let messagingService = MessagingService(deviceId: UIDevice.current.identifierForVendor!.uuidString)
                try await messagingService.initializeKeys(for: profile.id)

                isAuthenticated = true
            } catch SupabaseError.profileNotFound {
                // Profile needs to be created
                needsProfileSetup = true
            } catch {
                self.error = error.localizedDescription
            }

            isLoading = false
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        self.error = error.localizedDescription
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthViewModel: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return UIWindow()
        }
        return window
    }
}
