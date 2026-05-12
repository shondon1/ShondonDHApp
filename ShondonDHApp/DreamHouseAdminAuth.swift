//
//  DreamHouseAdminAuth.swift
//  ShondonDHApp
//
//  Must stay in sync with firestore.rules / storage.rules isAdmin().
//

import Foundation
import FirebaseAuth

enum DreamHouseAdminAuth {
    /// Shown on the login screen and used for sign-in.
    static let loginEmail = "rashyslop@outlook.com"

    /// All emails granted admin write access (lowercase).
    private static let allowedEmails: Set<String> = [
        "rashyslop@outlook.com",
        "rashon_hyslop@outlook.com"
    ]

    static func isAdmin(_ user: User?) -> Bool {
        guard let email = user?.email?.lowercased(), !email.isEmpty else { return false }
        return allowedEmails.contains(email)
    }
}
