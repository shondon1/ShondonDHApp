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

// AppDelegate class
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
}

@main
struct ShondonDHAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthenticationManager()
    
    init() {
        // Configure App Check
        #if targetEnvironment(simulator)
            let providerFactory = AppCheckDebugProviderFactory()
        #else
            let providerFactory = DeviceCheckProviderFactory()
        #endif
        
        AppCheck.setAppCheckProviderFactory(providerFactory)
        
        // Configure Firebase
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .onAppear {
                    // Sign in anonymously when app launches
                    authManager.signInAnonymously()
                }
        }
    }
}

