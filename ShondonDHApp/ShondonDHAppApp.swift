//
//  ShondonDHAppApp.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 6/21/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseAppCheck

#if os(iOS) || os(visionOS)
import UIKit

/// Subclass `UIResponder` so GoogleUtilities / Firebase swizzlers recognize a normal UIKit app delegate chain.
@objc(AppDelegate)
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        true
    }
}
#endif

@main
struct ShondonDHAppApp: App {
    #if os(iOS) || os(visionOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #endif
    @StateObject private var authManager = AuthenticationManager()

    init() {
        AppCheck.setAppCheckProviderFactory(ShondonDHAppCheckProviderFactory())

        let plistName = (Bundle.main.object(forInfoDictionaryKey: "FIREBASE_PLIST_NAME") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedPlistName = (plistName?.isEmpty == false) ? plistName! : "GoogleService-Info"

        if let path = Bundle.main.path(forResource: resolvedPlistName, ofType: "plist"),
           let options = FirebaseOptions(contentsOfFile: path) {
            FirebaseApp.configure(options: options)
        } else {
            FirebaseApp.configure()
        }

        #if DEBUG
        if let app = FirebaseApp.app() {
            let bid = Bundle.main.bundleIdentifier ?? "(unknown bundle id)"
            NSLog(
                "App Check: add debug token for GOOGLE_APP_ID=%@ (%@). Scheme env: FIRAAppCheckDebugToken.",
                app.options.googleAppID,
                bid
            )
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}
