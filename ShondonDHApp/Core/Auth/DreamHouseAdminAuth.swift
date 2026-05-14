//
//  DreamHouseAdminAuth.swift
//  ShondonDHApp
//
//  Admin authorization for the Studio app.
//  Must match `isAdmin()` in firestore.rules and storage.rules.
//
//  Setup (Firebase):
//  - Preferred: set custom claim `admin: true` on the admin user's UID (Admin SDK).
//  - Or: create Firestore `adminUsers/{uid}` with `{ "active": true }` (uid = Auth user id).
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

enum DreamHouseAdminAuth {

    /// Firestore collection for role documents (see firestore.rules).
    static let adminUsersCollection = "adminUsers"

    /// Pre-fills the login email field (UX only; not used for security).
    static let loginHintEmail = "rashyslop@outlook.com"

    /// Must stay in sync with `isAdmin()` in `firestore.rules` and `storage.rules` (email branch).
    private static let legacyAdminEmails: Set<String> = [
        "rashyslop@outlook.com",
        "rashon_hyslop@outlook.com",
    ]

    /// Admin if any of:
    /// 1) Signed-in user email is in the same allowlist as Firestore/Storage rules (no network; fixes App Check timeouts).
    /// 2) ID token custom claim `admin == true`
    /// 3) Firestore `adminUsers/{uid}` exists and `active != false`
    static func validateCurrentUserIsAdmin() async -> Bool {
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            return false
        }

        if isLegacyAdminEmail(user) {
            return true
        }

        // Prefer the cached token first; forcing refresh often blocks on App Check / network and can hang the UI.
        do {
            let token = try await user.getIDTokenResult()
            if token.claims["admin"] as? Bool == true {
                return true
            }
        } catch {
            // Fall through to Firestore role document.
        }

        do {
            let doc = try await Firestore.firestore()
                .collection(adminUsersCollection)
                .document(user.uid)
                .getDocument()
            guard doc.exists else { return false }
            return doc.data()?["active"] as? Bool ?? true
        } catch {
            return false
        }
    }

    private static func isLegacyAdminEmail(_ user: User) -> Bool {
        guard let email = user.email?.lowercased(), !email.isEmpty else { return false }
        return legacyAdminEmails.contains(email)
    }
}
