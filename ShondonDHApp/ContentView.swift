//
//  ContentView.swift
//  ShondonDHApp
//
//  Root shell: auth gate + main admin navigation. Feature screens live under Features/.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        Group {
            if authManager.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading...")
                        .foregroundColor(.secondary)
                }
            } else if authManager.isAuthenticated {
                NavigationView {
                    List {
                        Section("Content Management") {
                            NavigationLink(destination: UploadView()) {
                                Label("Upload New Content", systemImage: "square.and.arrow.up")
                            }

                            NavigationLink(destination: RadioFlowView()) {
                                Label("Radio Flow", systemImage: "music.note.list")
                            }
                        }

                        Section("Radio Control") {
                            NavigationLink(destination: RadioAdminView()) {
                                Label("Radio Admin", systemImage: "radio")
                            }

                            NavigationLink(destination: ScheduleView()) {
                                Label("Schedule Management", systemImage: "calendar")
                            }
                        }

                        Section("Ticker Messages") {
                            NavigationLink(destination: TickerManagementView()) {
                                Label("Manage Ticker Messages", systemImage: "text.bubble.rtl")
                                    .badge(Text("New"))
                            }

                            NavigationLink(destination: QuickTickerMessageView()) {
                                Label("Quick Message", systemImage: "text.bubble")
                            }
                        }

                        Section("User Updates") {
                            NavigationLink(destination: UpdateMessagesView()) {
                                Label("Update Messages", systemImage: "doc.text.fill")
                            }
                        }

                        Section("Community") {
                            NavigationLink(destination: ProfileListView()) {
                                Label("Profile Management", systemImage: "person.crop.rectangle.stack")
                            }
                        }

                        Section("Notifications") {
                            NavigationLink(destination: PushNotificationsView()) {
                                Label("Push Notifications", systemImage: "bell.badge")
                            }
                        }

                        Section("Status") {
                            NavigationLink(destination: RadioStatusView()) {
                                Label("Radio Status", systemImage: "antenna.radiowaves.left.and.right")
                            }
                        }
                    }
                    .navigationTitle("DreamHouse Studio")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { authManager.signOut() }) {
                                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            } else {
                LoginView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager())
}
