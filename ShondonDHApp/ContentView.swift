//
//  ContentView.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 6/21/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        Group {
            if authManager.isLoading {
                // Loading while checking persisted auth session
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading...")
                        .foregroundColor(.secondary)
                }
            } else if authManager.isAuthenticated {
                // Main admin interface
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
                // Login screen
                LoginView()
            }
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var password = ""
    @FocusState private var isPasswordFocused: Bool

    private let adminEmail = "rashon_hyslop@outlook.com"

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Header
            VStack(spacing: 12) {
                Image(systemName: "radio.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                Text("DreamHouse Studio")
                    .font(.largeTitle)
                    .bold()
                Text("Admin Panel")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 48)

            // Form
            VStack(spacing: 16) {
                // Email (read-only)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Email")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.gray)
                        Text(adminEmail)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }

                // Password
                VStack(alignment: .leading, spacing: 6) {
                    Text("Password")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                        SecureField("Enter your password", text: $password)
                            .focused($isPasswordFocused)
                            .submitLabel(.go)
                            .onSubmit { attemptSignIn() }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }

                // Error message
                if !authManager.errorMessage.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(authManager.errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Sign In button
                Button(action: attemptSignIn) {
                    HStack {
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        Text(authManager.isLoading ? "Signing in..." : "Sign In")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(password.isEmpty || authManager.isLoading ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(password.isEmpty || authManager.isLoading)
            }
            .padding(.horizontal, 32)

            Spacer()

            Text("DreamHouse Radio Admin")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
        }
    }

    private func attemptSignIn() {
        guard !password.isEmpty else { return }
        isPasswordFocused = false
        authManager.signIn(email: adminEmail, password: password)
    }
}
// MARK: - Quick Ticker Message View (Simple Version)
struct QuickTickerMessageView: View {
    @State private var message = ""
    @State private var priority = 0
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isAdding = false
    @Environment(\.dismiss) private var dismiss
    
    let priorities = [
        (0, "Normal"),
        (1, "High"),
        (2, "Urgent")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Quick Ticker Message")
                        .font(.title2)
                        .bold()
                    
                    Text("Add a message to the radio ticker")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Message Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Message")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter your message...", text: $message, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                .padding(.horizontal)
                
                // Priority Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Priority")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(priorities, id: \.0) { priority in
                            HStack {
                                Image(systemName: priorityIcon(for: priority.0))
                                    .foregroundColor(priorityColor(for: priority.0))
                                Text(priority.1)
                            }
                            .tag(priority.0)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.horizontal)
                
                // Add Button
                Button(action: {
                    Task {
                        await addMessage()
                    }
                }) {
                    HStack {
                        if isAdding {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "plus.circle.fill")
                        }
                        Text(isAdding ? "Adding..." : "Add Message")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValidMessage() ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!isValidMessage() || isAdding)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Quick Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Message Added", isPresented: $showingAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func isValidMessage() -> Bool {
        return !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func addMessage() async {
        guard isValidMessage() else { return }
        
        isAdding = true
        let messageText = message.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let db = Firestore.firestore()
        let data: [String: Any] = [
            "message": messageText,
            "isActive": true,
            "priority": priority,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        do {
            try await db.collection("tickerMessages").addDocument(data: data)
            
            await MainActor.run {
                alertMessage = "Message added successfully!"
                showingAlert = true
                isAdding = false
            }
        } catch {
            await MainActor.run {
                alertMessage = "Failed to add message: \(firestoreErrorMessage(error))"
                showingAlert = true
                isAdding = false
            }
        }
    }
    
    private func priorityIcon(for priority: Int) -> String {
        switch priority {
        case 2: return "exclamationmark.triangle.fill"
        case 1: return "exclamationmark.circle.fill"
        default: return "info.circle.fill"
        }
    }
    
    private func priorityColor(for priority: Int) -> Color {
        switch priority {
        case 2: return .red
        case 1: return .orange
        default: return .blue
        }
    }
}

// MARK: - Simple Radio Status View
struct RadioStatusView: View {
    @State private var listenerCount = 0
    @State private var currentTrack = "Loading..."
    @State private var isLive = false
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Current Status Card
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "radio.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading) {
                                Text("DreamHouse Radio")
                                    .font(.title2)
                                    .bold()
                                Text("24/7 Vibe Station")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Live Indicator
                            if isLive {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                    Text("LIVE")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.red)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        
                        Divider()
                        
                        // Status Details
                        VStack(spacing: 12) {
                            StatusRow(
                                icon: "antenna.radiowaves.left.and.right",
                                title: "Listeners",
                                value: "\(listenerCount)",
                                color: .green
                            )
                            
                            StatusRow(
                                icon: "music.note",
                                title: "Current Track",
                                value: currentTrack,
                                color: .blue
                            )
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    if isLoading {
                        ProgressView("Loading status...")
                            .padding()
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Radio Status")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadRadioStatus()
            }
        }
    }
    
    private func loadRadioStatus() {
        // Simple status loading - you can enhance this later
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            listenerCount = Int.random(in: 10...50)
            currentTrack = "DreamHouse Vibes"
            isLive = true
        }
    }
}

// MARK: - Status Row
struct StatusRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .bold()
                .foregroundColor(color)
        }
    }
}

// MARK: - Authentication Manager
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var errorMessage = ""

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        // Listen for persisted auth state — fires immediately with current user (or nil)
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                self?.isLoading = false
            }
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func signIn(email: String, password: String) {
        isLoading = true
        errorMessage = ""

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = self?.friendlyError(error) ?? error.localizedDescription
                    self?.isAuthenticated = false
                }
                // isAuthenticated is set by the auth state listener
                self?.isLoading = false
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            // isAuthenticated will be set to false by the auth state listener
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

// MARK: - Firestore Error Helper
/// Returns a user-friendly message for Firestore errors, especially permission denials.
func firestoreErrorMessage(_ error: Error) -> String {
    let nsError = error as NSError
    // Firestore error code 7 = PERMISSION_DENIED
    if nsError.domain == "FIRFirestoreErrorDomain" && nsError.code == 7 {
        return "Permission denied. Please ensure you are signed in as the admin account."
    }
    return error.localizedDescription
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager())
}
