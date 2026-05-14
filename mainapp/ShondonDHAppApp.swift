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

        FirebaseApp.configure()

        #if DEBUG
        if let app = FirebaseApp.app() {
            let bid = Bundle.main.bundleIdentifier ?? "(unknown bundle id)"
            NSLog(
                "App Check: register debug token for GOOGLE_APP_ID=%@ (%@). Scheme env: FIRAAppCheckDebugToken.",
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
