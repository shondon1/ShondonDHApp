//
//  ShondonDHAppCheckProviderFactory.swift
//

import FirebaseAppCheck
import FirebaseCore
import Foundation

/// App Check factory.
/// - Simulator: debug provider (register debug token in Firebase Console).
/// - **Debug** iPhone/vision builds from Xcode: debug provider. Apple’s *development* App Attest tokens
///   are often rejected by Firebase (`403 App attestation failed`); Firebase expects production attestation
///   (TestFlight/App Store). Until then, use a registered debug token for sideloaded dev builds.
/// - **Release** iOS/visionOS: `AppAttestProvider` (matches App Check “App Attest” in console).
final class ShondonDHAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        #if targetEnvironment(simulator)
            return AppCheckDebugProvider(app: app)
        #elseif DEBUG && (os(iOS) || os(visionOS))
            return AppCheckDebugProvider(app: app)
        #elseif os(iOS) || os(visionOS)
            if #available(iOS 14.0, visionOS 1.0, *) {
                return AppAttestProvider(app: app)
            }
            return DeviceCheckProvider(app: app)
        #else
            return DeviceCheckProvider(app: app)
        #endif
    }
}
