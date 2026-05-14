//
//  FirestoreErrorFormatting.swift
//  ShondonDHApp
//
//  Shared Firestore error messages for UI surfaces.
//

import Foundation

/// User-facing text for Firestore failures (especially permission denials).
func firestoreErrorMessage(_ error: Error) -> String {
    let nsError = error as NSError
    if nsError.domain == "FIRFirestoreErrorDomain" && nsError.code == 7 {
        return "Permission denied. Sign in with an admin account, or ask an owner to grant your UID the admin role in Firebase."
    }
    return error.localizedDescription
}
