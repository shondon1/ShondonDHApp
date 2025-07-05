//
//  ContentView.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 6/21/25.
//

import SwiftUI
import FirebaseAuth
import Combine

struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager()
    
    var body: some View {
        Group {
            if authManager.isLoading {
                // Loading view while authenticating
                VStack {
                    ProgressView()
                    Text("Authenticating...")
                        .padding(.top)
                }
            } else if authManager.isAuthenticated {
                // Your existing content
                NavigationView {
                    List {
                        Section("Content Management") {
                            NavigationLink(destination: UploadView()) {
                                Label("Upload New Block", systemImage: "square.and.arrow.up")
                            }
//                            NavigationLink(destination: RadioFlowListView()) {
//                                Label("View Schedule", systemImage: "calendar")
//                            }
                            NavigationLink(destination: RadioFlowView()) {
                                Label("Radio Flow", systemImage: "book")
                            }
                        }
                    }
                    .navigationTitle("DreamHouse Studio")
                }
            } else {
                // Error view
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("Authentication Failed")
                        .font(.title2)
                    
                    Text(authManager.errorMessage)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Retry") {
                        authManager.signInAnonymously()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .onAppear {
            // Automatically sign in when app launches
            authManager.signInAnonymously()
        }
    }
}

// Authentication Manager
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var errorMessage = ""
    
    init() {
        // Check if already signed in
        if let user = Auth.auth().currentUser {
            print("Already signed in with UID: \(user.uid)")
            self.isAuthenticated = true
            self.isLoading = false
        }
    }
    
    func signInAnonymously() {
        isLoading = true
        errorMessage = ""
        
        Auth.auth().signInAnonymously { [weak self] authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Anonymous auth failed: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    self?.isAuthenticated = false
                } else if let user = authResult?.user {
                    print("Signed in anonymously with UID: \(user.uid)")
                    self?.isAuthenticated = true
                }
                self?.isLoading = false
            }
        }
    }
}

#Preview {
    ContentView()
}
