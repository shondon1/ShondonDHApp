//
//  UploadView.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 6/21/25.
//

//
//  UploadView.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 6/21/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import UniformTypeIdentifiers
import FirebaseFirestore
import PhotosUI
import AVFoundation

// MARK: - Data Model
struct RadioContent: Codable, Identifiable {
    @DocumentID var id: String?
    var type: String = "none"
    var url: String = ""
    var title: String = "DreamHouse Radio"
    var thumbnail: String? = nil
    var isPlaying: Bool = false
}

// MARK: - Upload View
struct UploadView: View {
    @State private var title: String = ""
    @State private var type: String = "Audio"
    @State private var mediaURL: URL?
    @State private var youtubeURL: String = ""
    @State private var isUploading: Bool = false
    @State private var uploadStatus: String = ""
    @State private var uploadProgress: Double = 0.0
    @State private var isPickerPresented: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingImagePicker = false
    @State private var selectedVideoURL: URL?

    let mediaTypes = ["Audio", "Video", "YouTube"]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Upload to Radio Flow")
                    .font(.title)
                    .bold()

                TextField("Title", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                Picker("Content Type", selection: $type) {
                    ForEach(mediaTypes, id: \.self) { item in
                        Text(item)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: type) { _ in
                    // Reset media when type changes
                    mediaURL = nil
                    selectedPhotoItem = nil
                }

                if type != "YouTube" {
                    VStack(spacing: 15) {
                        // File picker button
                        Button(action: {
                            isPickerPresented = true
                        }) {
                            HStack {
                                Image(systemName: "folder.badge.plus")
                                Text("Choose from Files")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(10)
                        }
                        
                        // Media picker button (Photos for video, Music for audio)
                        if type == "Video" {
                            // Photos picker for videos
                            PhotosPicker(
                                selection: $selectedPhotoItem,
                                matching: .videos,
                                photoLibrary: .shared()
                            ) {
                                HStack {
                                    Image(systemName: "photo.badge.plus")
                                    Text("Choose from Photos")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(10)
                            }
                            .onChange(of: selectedPhotoItem) { newItem in
                                Task {
                                    await loadVideoFromPhotos(newItem)
                                }
                            }
                            
                            // Alternative: Camera Roll button using UIImagePickerController
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "camera.fill")
                                    Text("Choose from Camera Roll")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple.opacity(0.1))
                                .foregroundColor(.purple)
                                .cornerRadius(10)
                            }
                        } else {
                            // Music Library button for audio (if you have Apple Music integration)
                            Button(action: {
                                uploadStatus = "Music Library access requires Apple Music integration"
                            }) {
                                HStack {
                                    Image(systemName: "music.note.house")
                                    Text("Choose from Music Library")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.pink.opacity(0.1))
                                .foregroundColor(.pink)
                                .cornerRadius(10)
                            }
                            .disabled(true) // Disable for now
                        }
                        
                        // Show selected file
                        if let url = mediaURL {
                            HStack {
                                Image(systemName: type == "Video" ? "video.fill" : "music.note")
                                    .foregroundColor(.accentColor)
                                Text(url.lastPathComponent)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer()
                                Button("Remove") {
                                    mediaURL = nil
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                } else {
                    TextField("YouTube URL", text: $youtubeURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                // Upload button
                Button(action: {
                    Task {
                        await uploadMedia()
                    }
                }) {
                    if isUploading {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Uploading... \(Int(uploadProgress * 100))%")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    } else {
                        Text("Upload")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isValidForUpload() ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .disabled(!isValidForUpload() || isUploading)

                if !uploadStatus.isEmpty {
                    Text(uploadStatus)
                        .foregroundColor(uploadStatus.contains("successful") ? .green : .red)
                        .padding()
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.vertical)
        }
        .fileImporter(
            isPresented: $isPickerPresented,
            allowedContentTypes: type == "Video" ? [.movie, .mpeg4Movie, .quickTimeMovie, .video] : [.audio, .mp3, .wav, .mpeg4Audio, .m4a],
            allowsMultipleSelection: false
        ) { result in
            handleFileImporterResult(result)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: .photoLibrary, mediaType: .video) { url in
                if let url = url {
                    mediaURL = url
                    uploadStatus = "Video selected from Camera Roll"
                }
            }
        }
        .onAppear {
            // Sign in anonymously if not already signed in
            if Auth.auth().currentUser == nil {
                signInAnonymously()
            }
        }
    }
    
    // MARK: - Authentication
    
    private func signInAnonymously() {
        Auth.auth().signInAnonymously { result, error in
            if let error = error {
                uploadStatus = "Authentication failed: \(error.localizedDescription)"
            } else {
                print("Signed in anonymously with uid: \(result?.user.uid ?? "unknown")")
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func isValidForUpload() -> Bool {
        if title.isEmpty { return false }
        
        switch type {
        case "YouTube":
            return !youtubeURL.isEmpty && (youtubeURL.contains("youtube.com") || youtubeURL.contains("youtu.be"))
        default:
            return mediaURL != nil
        }
    }
    
    private func handleFileImporterResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                uploadStatus = "Cannot access file. Please try again."
                return
            }
            
            // Copy file to temporary directory
            let tempDirectory = FileManager.default.temporaryDirectory
            let tempFileName = "\(UUID().uuidString)_\(url.lastPathComponent)"
            let tempURL = tempDirectory.appendingPathComponent(tempFileName)
            
            do {
                // If file exists at temp location, remove it first
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(at: tempURL)
                }
                
                // Copy file to temp directory
                try FileManager.default.copyItem(at: url, to: tempURL)
                mediaURL = tempURL
                uploadStatus = "File selected: \(url.lastPathComponent)"
                
                // Stop accessing the security-scoped resource
                url.stopAccessingSecurityScopedResource()
                
            } catch {
                uploadStatus = "Error copying file: \(error.localizedDescription)"
                url.stopAccessingSecurityScopedResource()
            }
            
        case .failure(let error):
            uploadStatus = "File selection failed: \(error.localizedDescription)"
        }
    }
    
    private func loadVideoFromPhotos(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            // Load video as Data first
            if let videoData = try await item.loadTransferable(type: Data.self) {
                // Save to temporary file
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(UUID().uuidString).mov")
                
                try videoData.write(to: tempURL)
                
                await MainActor.run {
                    mediaURL = tempURL
                    uploadStatus = "Video selected from Photos"
                }
            } else {
                await MainActor.run {
                    uploadStatus = "Failed to load video from Photos"
                }
            }
        } catch {
            await MainActor.run {
                uploadStatus = "Error loading video: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Upload Logic
    func uploadMedia() async {
        // Check authentication first
        guard Auth.auth().currentUser != nil else {
            uploadStatus = "Not authenticated. Please wait..."
            signInAnonymously()
            return
        }
        
        guard isValidForUpload() else {
            uploadStatus = "Please fill in all required fields."
            return
        }

        isUploading = true
        uploadStatus = "Starting upload..."
        uploadProgress = 0.0

        if type == "YouTube" {
            // Extract video ID if needed
            let cleanedURL = cleanYouTubeURL(youtubeURL)
            
            let content = RadioContent(
                type: "youtube",
                url: cleanedURL,
                title: title,
                isPlaying: false
            )
            await saveToFirestore(content: content)
        } else if let mediaURL = mediaURL {
            await uploadFileToStorage(mediaURL)
        }
    }
    
    private func cleanYouTubeURL(_ url: String) -> String {
        // Clean and validate YouTube URL
        var cleanedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Ensure it starts with https://
        if !cleanedURL.hasPrefix("http://") && !cleanedURL.hasPrefix("https://") {
            cleanedURL = "https://\(cleanedURL)"
        }
        
        return cleanedURL
    }
    
    private func uploadFileToStorage(_ fileURL: URL) async {
        let fileName = "\(UUID().uuidString)_\(fileURL.lastPathComponent)"
        let storageRef = Storage.storage().reference().child("radio_media/\(type.lowercased())/\(fileName)")
        
        // Create metadata
        let metadata = StorageMetadata()
        metadata.contentType = type == "Video" ? "video/mp4" : "audio/mpeg"
        
        do {
            // Upload file
            let _ = try await storageRef.putFileAsync(from: fileURL, metadata: metadata) { progress in
                if let progress = progress {
                    let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                    Task { @MainActor in
                        self.uploadProgress = percentComplete
                        self.uploadStatus = "Uploading... \(Int(percentComplete * 100))%"
                    }
                }
            }
            
            // Get download URL
            let downloadURL = try await storageRef.downloadURL()
            
            // Save to Firestore
            let content = RadioContent(
                type: type.lowercased(),
                url: downloadURL.absoluteString,
                title: title,
                isPlaying: false
            )
            
            await saveToFirestore(content: content)
            
        } catch {
            await MainActor.run {
                self.uploadStatus = "Upload failed: \(error.localizedDescription)"
                self.isUploading = false
            }
        }
    }

    func saveToFirestore(content: RadioContent) async {
        let db = Firestore.firestore()
        
        do {
            try await db.collection("radioFlow").addDocument(data: [
                "type": content.type,
                "url": content.url,
                "title": content.title,
                "isPlaying": content.isPlaying,
                "createdAt": FieldValue.serverTimestamp()
            ])
            
            await MainActor.run {
                self.uploadStatus = "Upload successful! 🎉"
                // Reset form
                self.title = ""
                self.youtubeURL = ""
                self.mediaURL = nil
                self.selectedPhotoItem = nil
                self.isUploading = false
                self.uploadProgress = 0.0
            }
            
            // Update radio state
            try? await db.collection("radioState").document("current").updateData([
                "lastUpdated": FieldValue.serverTimestamp()
            ])
            
        } catch {
            await MainActor.run {
                self.uploadStatus = "Save failed: \(error.localizedDescription)"
                self.isUploading = false
            }
        }
    }
}

// MARK: - UIImagePickerController Wrapper
struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let mediaType: MediaType
    let completion: (URL?) -> Void
    
    enum MediaType {
        case video
        case image
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        
        if mediaType == .video {
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeHigh
        } else {
            picker.mediaTypes = ["public.image"]
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true)
            
            if parent.mediaType == .video {
                if let videoURL = info[.mediaURL] as? URL {
                    // Copy video to temp directory
                    let tempURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent("\(UUID().uuidString).mov")
                    
                    do {
                        try FileManager.default.copyItem(at: videoURL, to: tempURL)
                        parent.completion(tempURL)
                    } catch {
                        print("Error copying video: \(error)")
                        parent.completion(nil)
                    }
                }
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
            parent.completion(nil)
        }
    }
}

// MARK: - Preview
#Preview {
    UploadView()
}
