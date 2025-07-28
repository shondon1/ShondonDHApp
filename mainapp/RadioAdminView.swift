//
//  RadioAdminView.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 7/2/25.
//

import SwiftUI
import FirebaseFirestore

struct RadioAdminView: View {
    @State private var contentType = "audio"
    @State private var contentURL = ""
    @State private var contentTitle = "DreamHouse Radio"
    @State private var isPlaying = true
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isUpdating = false
    
    var body: some View {
        NavigationView {
            Form {
                // Content Configuration Section
                Section("Configure Content") {
                    // Content Type Picker
                    Picker("Content Type", selection: $contentType) {
                        Label("Audio Stream", systemImage: "antenna.radiowaves.left.and.right").tag("audio")
                        Label("Video", systemImage: "video").tag("video")
                        Label("YouTube", systemImage: "play.rectangle").tag("youtube")
                        Label("Live Stream", systemImage: "dot.radiowaves.left.and.right").tag("live")
                    }
                    
                    // URL Input
                    VStack(alignment: .leading) {
                        Text("Content URL")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter URL", text: $contentURL)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: contentURL) { newURL in
                                // Auto-detect content type when URL changes
                                if !newURL.isEmpty {
                                    contentType = detectContentType(from: newURL)
                                }
                            }
                    }
                    
                    // Title Input
                    VStack(alignment: .leading) {
                        Text("Display Title")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter title", text: $contentTitle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Playing Toggle
                    Toggle("Start Playing Immediately", isOn: $isPlaying)
                }
                
                // Update Button
                Section {
                    Button(action: updateRadioContent) {
                        HStack {
                            if isUpdating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "radio")
                            }
                            
                            Text(isUpdating ? "Updating..." : "Update Radio")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(buttonColor)
                        .cornerRadius(10)
                    }
                    .disabled(isUpdating || contentURL.isEmpty || contentTitle.isEmpty)
                }
                
                // Instructions
                Section("How It Works") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("The radio plays 24/7 in your DreamHouse app", systemImage: "info.circle")
                            .font(.caption)
                        
                        Label("Changes appear instantly for all listeners", systemImage: "sparkles")
                            .font(.caption)
                        
                        Label("YouTube URLs will be embedded in the app", systemImage: "play.rectangle")
                            .font(.caption)
                        
                        Label("Use live stream URLs for continuous playback", systemImage: "antenna.radiowaves.left.and.right")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Radio Control")
            .alert("Radio Update", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func detectContentType(from url: String) -> String {
        let lowercasedURL = url.lowercased()
        
        // YouTube detection
        if lowercasedURL.contains("youtube.com") || lowercasedURL.contains("youtu.be") {
            return "youtube"
        }
        
        // Video file extensions
        if lowercasedURL.hasSuffix(".mp4") || 
           lowercasedURL.hasSuffix(".mov") || 
           lowercasedURL.hasSuffix(".m3u8") ||
           lowercasedURL.hasSuffix(".webm") {
            return "video"
        }
        
        // Audio file extensions
        if lowercasedURL.hasSuffix(".mp3") || 
           lowercasedURL.hasSuffix(".m4a") || 
           lowercasedURL.hasSuffix(".wav") ||
           lowercasedURL.hasSuffix(".aac") {
            return "audio"
        }
        
        // Live stream indicators
        if lowercasedURL.contains("stream") || 
           lowercasedURL.contains("live") ||
           lowercasedURL.contains("radio") {
            return "live"
        }
        
        // Default to audio for unknown URLs
        return "audio"
    }
    
    private var buttonColor: Color {
        if isUpdating || contentURL.isEmpty || contentTitle.isEmpty {
            return Color.gray
        }
        return Color.blue
    }
    
    private func updateRadioContent() {
        isUpdating = true
        
        let db = Firestore.firestore()
        let radioData: [String: Any] = [
            "type": contentType,
            "url": contentURL,
            "title": contentTitle,
            "isPlaying": isPlaying,
            "thumbnail": "", // You can add thumbnail support later
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("radioState").document("current").setData(radioData) { error in
            isUpdating = false
            
            if let error = error {
                alertMessage = "Error: \(error.localizedDescription)"
            } else {
                alertMessage = "Radio updated successfully! Content is now playing."
            }
            showAlert = true
        }
    }
}

#Preview {
    RadioAdminView()
}
