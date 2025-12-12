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
        NavigationStack {
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
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .onChange(of: contentURL) { old, new in
                                if !new.isEmpty {
                                    contentType = detectContentType(from: new)
                                }
                            }
                    }

                    // Title Input
                    VStack(alignment: .leading) {
                        Text("Display Title")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField("Enter title", text: $contentTitle)
                            .textFieldStyle(.roundedBorder)
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

                // Live Stream Quick Actions
                Section("Go Live") {
                    // Twitch Button
                    Button(action: { goLiveOnTwitch() }) {
                        HStack {
                            Image(systemName: "video.fill").foregroundColor(.purple)
                            Text("Go Live on Twitch").fontWeight(.medium)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(.gray)
                        }
                    }

                    // YouTube Button
                    Button(action: { goLiveOnYouTube() }) {
                        HStack {
                            Image(systemName: "play.rectangle.fill").foregroundColor(.red)
                            Text("Go Live on YouTube").fontWeight(.medium)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(.gray)
                        }
                    }

                    // End Live Button
                    Button(action: { endLiveStream() }) {
                        HStack {
                            Image(systemName: "stop.circle.fill").foregroundColor(.orange)
                            Text("End Live Stream").fontWeight(.medium)
                            Spacer()
                        }
                    }
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

    // MARK: - Helpers

    private func detectContentType(from url: String) -> String {
        let lowercasedURL = url.lowercased()

        if lowercasedURL.contains("youtube.com") || lowercasedURL.contains("youtu.be") {
            return "youtube"
        }

        if lowercasedURL.hasSuffix(".mp4") ||
            lowercasedURL.hasSuffix(".mov") ||
            lowercasedURL.hasSuffix(".m3u8") ||
            lowercasedURL.hasSuffix(".webm") {
            return "video"
        }

        if lowercasedURL.hasSuffix(".mp3") ||
            lowercasedURL.hasSuffix(".m4a") ||
            lowercasedURL.hasSuffix(".wav") ||
            lowercasedURL.hasSuffix(".aac") {
            return "audio"
        }

        if lowercasedURL.contains("stream") ||
            lowercasedURL.contains("live") ||
            lowercasedURL.contains("radio") {
            return "live"
        }

        return "audio"
    }

    private var buttonColor: Color {
        (isUpdating || contentURL.isEmpty || contentTitle.isEmpty) ? .gray : .blue
    }

    private func updateRadioContent() {
        isUpdating = true
        let db = Firestore.firestore()

        let radioData: [String: Any] = [
            "type": contentType,
            "url": contentURL,
            "title": contentTitle,
            "isPlaying": isPlaying,
            "thumbnail": "",
            "updatedAt": FieldValue.serverTimestamp()
        ]

        db.collection("radioState").document("current").setData(radioData) { error in
            isUpdating = false
            alertMessage = error == nil
                ? "Radio updated successfully! Content is now playing."
                : "Error: \(error!.localizedDescription)"
            showAlert = true
        }
    }

    // MARK: - Live Controls (Twitch youtube)

    private func goLiveOnTwitch() {
        let db = Firestore.firestore()
        let liveData: [String: Any] = [
            "isLive": true,
            "type": "twitch",
            "url": "https://twitch.tv/shondon11", // TODO: set your channel
            "title": "DJ Shon Live on Twitch",
            "priority": 100,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        db.collection("liveStatus").document("current").setData(liveData) { error in
            alertMessage = error == nil ? "Now live on Twitch! 🎮" : "Error: \(error!.localizedDescription)"
            showAlert = true
        }
    }

    private func goLiveOnYouTube() {
        let db = Firestore.firestore()
        let liveData: [String: Any] = [
            "isLive": true,
            "type": "youtube",
            "url": "https://youtube.com/watch?v=YOUR_STREAM_ID", // TODO: set your stream
            "title": "DJ Shon Live on YouTube",
            "priority": 100,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        db.collection("liveStatus").document("current").setData(liveData) { error in
            alertMessage = error == nil ? "Now live on YouTube! 📺" : "Error: \(error!.localizedDescription)"
            showAlert = true
        }
    }

    private func endLiveStream() {
        let db = Firestore.firestore()
        let liveData: [String: Any] = [
            "isLive": false,
            "type": "",
            "url": "",
            "title": "",
            "priority": 0,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        db.collection("liveStatus").document("current").setData(liveData) { error in
            alertMessage = error == nil ? "Live stream ended. Returning to playlist." : "Error: \(error!.localizedDescription)"
            showAlert = true
        }
    }
}

#Preview {
    RadioAdminView()
}
