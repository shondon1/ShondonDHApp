//
//  AuthenticationManager.swift
//  ShondonDHApp
//

import Combine
import FirebaseAuth
import Foundation

/// Observes Firebase Auth and resolves whether the current user is an admin (claims or `adminUsers`).
final class AuthenticationManager: ObservableObject {
    private enum AdminGateOutcome: Sendable {
        case resolved(isAdmin: Bool)
        case timedOut
    }
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var errorMessage = ""

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var authValidationTask: Task<Void, Never>?

    init() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.authValidationTask?.cancel()
            self?.authValidationTask = Task { [weak self] in
                guard let self else { return }
                await MainActor.run {
                    self.isLoading = true
                }

                if user == nil {
                    await MainActor.run {
                        self.isAuthenticated = false
                        self.errorMessage = ""
                        self.isLoading = false
                    }
                    return
                }

                if let user, user.isAnonymous {
                    try? Auth.auth().signOut()
                    await MainActor.run {
                        self.isAuthenticated = false
                        self.isLoading = false
                    }
                    return
                }

                let outcome = await self.raceAdminValidationWithTimeout(seconds: 8)
                if Task.isCancelled { return }

                await MainActor.run {
                    switch outcome {
                    case .resolved(let isAdmin):
                        self.isAuthenticated = isAdmin
                        if isAdmin {
                            self.errorMessage = ""
                        } else {
                            self.errorMessage = "Signed in, but this account is not assigned the admin role."
                        }
                    case .timedOut:
                        try? Auth.auth().signOut()
                        self.isAuthenticated = false
                        self.errorMessage = "Could not verify admin access (timed out). Check network, App Check, and Firestore, then try again."
                    }
                    self.isLoading = false
                }
            }
        }
    }

    deinit {
        authValidationTask?.cancel()
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func signIn(email: String, password: String) {
        isLoading = true
        errorMessage = ""

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            DispatchQueue.main.async {
                if let error {
                    self?.errorMessage = self?.friendlyError(error) ?? error.localizedDescription
                    self?.isAuthenticated = false
                    self?.isLoading = false
                }
                // Success: keep isLoading true until the auth listener finishes admin validation.
            }
        }
    }

    private func raceAdminValidationWithTimeout(seconds: TimeInterval) async -> AdminGateOutcome {
        await withTaskGroup(of: AdminGateOutcome.self) { group in
            group.addTask {
                let isAdmin = await DreamHouseAdminAuth.validateCurrentUserIsAdmin()
                return .resolved(isAdmin: isAdmin)
            }
            group.addTask {
                let nanos = UInt64(seconds * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanos)
                return .timedOut
            }
            let first = await group.next() ?? .timedOut
            group.cancelAll()
            return first
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = "Sign out failed: \(error.localizedDescription)"
        }
    }

    private func friendlyError(_ error: Error) -> String {
        let nsError = error as NSError
        guard let code = AuthErrorCode(rawValue: nsError.code) else {
            return error.localizedDescription
        }
        switch code {
        case .wrongPassword, .invalidCredential:
            return "Incorrect password. Please try again."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .userNotFound:
            return "No account found with this email."
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .tooManyRequests:
            return "Too many failed attempts. Please wait a moment and try again."
        default:
            return error.localizedDescription
        }
    }
}
