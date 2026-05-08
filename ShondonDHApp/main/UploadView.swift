//
//  UploadView.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 6/21/25.
//

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
    var type: String
    var url: String
    var title: String
    var thumbnailURL: String?
    var isPlaying: Bool
    var order: Int   // <-- add this
   // var createdAt: Timestamp? // optional, in case you want it later
}

// MARK: - Upload View
struct UploadView: View {
    @State private var title: String = ""
    @State private var type: String = "Audio"
    @State private var mediaURL: URL?
    @State private var thumbnailImage: UIImage?
    @State private var youtubeURL: String = ""
    @State private var isUploading: Bool = false
    @State private var uploadStatus: String = ""
    @State private var uploadProgress: Double = 0.0
    @State private var isFilePickerPresented: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingImagePicker = false
    @State private var showingThumbnailPicker = false
    @State private var notifyListeners = false

    let mediaTypes = ["Audio", "Video", "YouTube"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "radio.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Upload to Radio Flow")
                        .font(.title)
                        .bold()
                }
                .padding(.top)
                
                // Title Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                
                // Content Type Picker
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
                    thumbnailImage = nil
                }
                
                // Content Selection Based on Type
                if type == "YouTube" {
                    // YouTube URL Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("YouTube URL")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextField("https://youtube.com/watch?v=...", text: $youtubeURL)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding(.horizontal)
                } else if type == "Audio" {
                    // Audio Selection with Thumbnail
                    VStack(spacing: 15) {
                        // Audio File Selection
                        audioSelectionSection
                        
                        // Thumbnail Selection for Audio
                        thumbnailSelectionSection
                    }
                } else if type == "Video" {
                    // Video Selection Only (No Thumbnail)
                    videoSelectionSection
                }
                
                // Upload Progress
                if isUploading {
                    VStack(spacing: 10) {
                        ProgressView(value: uploadProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                            .padding(.horizontal)
                        
                        Text("\(Int(uploadProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Notify listeners toggle
                Toggle(isOn: $notifyListeners) {
                    Label("Notify Listeners", systemImage: "bell.badge")
                }
                .padding(.horizontal)
                .tint(.blue)

                // Upload Button
                Button(action: {
                    Task {
                        await uploadMedia()
                    }
                }) {
                    if isUploading {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Uploading...")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    } else {
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                            Text("Upload to Radio")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValidForUpload() ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .disabled(!isValidForUpload() || isUploading)
                
                // Status Message
                if !uploadStatus.isEmpty {
                    HStack {
                        Image(systemName: uploadStatus.contains("successful") ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        Text(uploadStatus)
                    }
                    .foregroundColor(uploadStatus.contains("successful") ? .green : .red)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .fileImporter(
            isPresented: $isFilePickerPresented,
            allowedContentTypes: type == "Video" ?
            [.movie, .mpeg4Movie, .quickTimeMovie, .video] :
                [.audio, .mp3, .wav, .mpeg4Audio],
            allowsMultipleSelection: false
        ) { result in
            handleFileImporterResult(result)
        }
        .sheet(isPresented: $showingImagePicker) {
            MediaPicker(
                mediaType: type == "Video" ? .video : .audio,
                onSelection: { url, thumbnail in
                    if let url = url {
                        mediaURL = url
                        uploadStatus = "\(type) selected from Camera Roll"
                    }
                }
            )
        }
        .sheet(isPresented: $showingThumbnailPicker) {
            MediaPicker(
                mediaType: .photo,
                onSelection: { _, image in
                    thumbnailImage = image
                    if image != nil {
                        uploadStatus = "Thumbnail selected"
                    }
                }
            )
        }
    }
    
    // MARK: - Audio Selection Section
    private var audioSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Audio File")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                // Files Button
                Button(action: {
                    isFilePickerPresented = true
                }) {
                    VStack {
                        Image(systemName: "folder.badge.plus")
                            .font(.title2)
                        Text("Files")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
                }
                
                // Camera Roll Button (for audio from videos)
                Button(action: {
                    showingImagePicker = true
                }) {
                    VStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                        Text("Camera Roll")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            // Show selected audio file
            if let url = mediaURL {
                selectedFileView(url: url, type: "Audio")
            }
        }
    }
    
    // MARK: - Video Selection Section
    private var videoSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Video File")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                // Files Button
                Button(action: {
                    isFilePickerPresented = true
                }) {
                    VStack {
                        Image(systemName: "folder.badge.plus")
                            .font(.title2)
                        Text("Files")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
                }
                
                // Camera Roll Button
                Button(action: {
                    showingImagePicker = true
                }) {
                    VStack {
                        Image(systemName: "photo.stack")
                            .font(.title2)
                        Text("Camera Roll")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .foregroundColor(.purple)
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            // Show selected video file
            if let url = mediaURL {
                selectedFileView(url: url, type: "Video")
            }
        }
    }
    
    // MARK: - Thumbnail Selection Section (Audio Only)
    private var thumbnailSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Album Art (Optional)")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: {
                showingThumbnailPicker = true
            }) {
                if let image = thumbnailImage {
                    // Show selected thumbnail
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 120)
                            .clipped()
                            .cornerRadius(10)
                        
                        Button(action: {
                            thumbnailImage = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(8)
                    }
                } else {
                    // Show placeholder
                    VStack {
                        Image(systemName: "photo.badge.plus")
                            .font(.title)
                        Text("Add Album Art")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.gray)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                            .foregroundColor(.gray.opacity(0.5))
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Selected File View
    private func selectedFileView(url: URL, type: String) -> some View {
        HStack {
            Image(systemName: type == "Video" ? "video.fill" : "music.note")
                .foregroundColor(.accentColor)
                .font(.title3)
            
            VStack(alignment: .leading) {
                Text(url.lastPathComponent)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(fileSizeString(for: url))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                mediaURL = nil
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    // MARK: - Helper Functions
    
    private func fileSizeString(for url: URL) -> String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let size = attributes[.size] as? Int64 {
                return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            }
        } catch {
            // Ignore error
        }
        return "Unknown size"
    }
    
    /// Picks a MIME type that satisfies `storage.rules` (`audio/.*` / `video/.*`).
    private func mimeTypeForStorage(fileURL: URL) -> String {
        let ext = fileURL.pathExtension.lowercased()
        if type == "Video" {
            if let ut = UTType(filenameExtension: ext), let mime = ut.preferredMIMEType, mime.hasPrefix("video/") {
                return mime
            }
            return "video/mp4"
        }
        if let ut = UTType(filenameExtension: ext), let mime = ut.preferredMIMEType, mime.hasPrefix("audio/") {
            return mime
        }
        return "audio/mpeg"
    }
    
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
    
    // MARK: - Upload Logic
    func uploadMedia() async {
        guard DreamHouseAdminAuth.isAdmin(Auth.auth().currentUser) else {
            await MainActor.run {
                uploadStatus = "You must be signed in with the DreamHouse admin account to upload. Use Sign Out, then sign in again."
            }
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
                isPlaying: false,
                order: 0
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
        
        // Create metadata (must match storage.rules audio/* or video/*)
        let metadata = StorageMetadata()
        metadata.contentType = mimeTypeForStorage(fileURL: fileURL)
        
        do {
            // Upload main file
            let _ = try await storageRef.putFileAsync(from: fileURL, metadata: metadata) { progress in
                if let progress = progress {
                    let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                    Task { @MainActor in
                        self.uploadProgress = percentComplete * 0.8 // 80% for main file
                        self.uploadStatus = "Uploading \(type.lowercased())... \(Int(percentComplete * 100))%"
                    }
                }
            }
            
            // Get download URL
            let downloadURL = try await storageRef.downloadURL()
            
            // Upload thumbnail if it's audio and thumbnail exists
            var thumbnailURL: String? = nil
            if type == "Audio", let thumbnail = thumbnailImage {
                uploadStatus = "Uploading album art..."
                uploadProgress = 0.9
                
                thumbnailURL = try await uploadThumbnail(thumbnail)
            }
            
            // Save to Firestore
            let content = RadioContent(
                type: type.lowercased(),
                url: downloadURL.absoluteString,
                title: title,
                thumbnailURL: thumbnailURL,
                isPlaying: false,
                order: 0
            )
            
            await saveToFirestore(content: content)
            
        } catch {
            await MainActor.run {
                self.uploadStatus = "Upload failed: \(error.localizedDescription)"
                self.isUploading = false
            }
        }
    }
    
    private func uploadThumbnail(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "UploadError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image"])
        }
        
        let fileName = "\(UUID().uuidString).jpg"
        let storageRef = Storage.storage().reference().child("radio_media/thumbnails/\(fileName)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    private func getMediaDuration(from url: URL) async -> Double? {
        let asset = AVAsset(url: url)
        
        do {
            let duration = try await asset.load(.duration)
            let seconds = CMTimeGetSeconds(duration)
            return seconds.isFinite ? seconds : nil
        } catch {
            print("Failed to get duration: \(error)")
            return nil
        }
    }
    //MARK: - Save to Firestore function
    func saveToFirestore(content: RadioContent) async {
        let db = Firestore.firestore()
        
        var duration: Double = 180  // Default 3 minutes
        if let mediaURL = mediaURL {
            if let detectedDuration = await getMediaDuration(from: mediaURL) {
                duration = detectedDuration
            }
        }
        
        do {
            // 1️⃣ Find current max order
            let snapshot = try await db.collection("radioFlow")
                .order(by: "order", descending: true)
                .limit(to: 1)
                .getDocuments()
            let maxOrder = snapshot.documents.first?
                .data()["order"] as? Int ?? -1
            
            // 2️⃣ Build your data including new order
            var data: [String: Any] = [
                "type":        content.type,
                "url":         content.url,
                "title":       content.title,
                "isPlaying":   content.isPlaying,
                "duration": duration,
                "order":       maxOrder + 1,
                "createdAt":   FieldValue.serverTimestamp()
            ]
            if let thumb = content.thumbnailURL {
                data["thumbnailURL"] = thumb
            }
            
            // 3️⃣ Save it
            let ref = try await db.collection("radioFlow").addDocument(data: data)

            // 4️⃣ Optionally notify listeners (passive = silent banner, won't interrupt)
            if notifyListeners {
                try? await PushNotificationService.shared.queue(
                    title: "New on DreamHouse Radio",
                    body: content.title.isEmpty ? "Fresh content just dropped." : "\"\(content.title)\" is now in the rotation.",
                    category: "content",
                    interruptionLevel: .passive,
                    sourceType: "auto_upload",
                    sourceId: ref.documentID
                )
            }

            await MainActor.run {
                uploadStatus = notifyListeners ? "Upload successful! Listeners notified." : "Upload successful!"
                // reset your form state…
                self.title = ""
                self.youtubeURL = ""
                self.mediaURL = nil
                self.selectedPhotoItem = nil
                self.thumbnailImage = nil
                self.isUploading = false
                self.uploadProgress = 0.0
            }
            
            // 5️⃣ Optionally bump your radioState timestamp
            try? await db.collection("radioState")
                .document("current")
                .updateData(["lastUpdated": FieldValue.serverTimestamp()])
            
        } catch {
            await MainActor.run {
                uploadStatus = firestoreErrorMessage(error)
                isUploading = false
            }
        }
    }
    
    
    // MARK: - Media Picker
    struct MediaPicker: UIViewControllerRepresentable {
        enum MediaType {
            case video
            case audio
            case photo
        }
        
        let mediaType: MediaType
        let onSelection: (URL?, UIImage?) -> Void
        
        func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = context.coordinator
            
            switch mediaType {
            case .video:
                picker.mediaTypes = ["public.movie"]
                picker.videoQuality = .typeHigh
            case .audio:
                // For audio from videos in camera roll
                picker.mediaTypes = ["public.movie"]
            case .photo:
                picker.mediaTypes = ["public.image"]
            }
            
            return picker
        }
        
        func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
            let parent: MediaPicker
            
            init(_ parent: MediaPicker) {
                self.parent = parent
            }
            
            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
                picker.dismiss(animated: true)
                
                switch parent.mediaType {
                case .video, .audio:
                    if let videoURL = info[.mediaURL] as? URL {
                        // Copy video to temp directory
                        let tempURL = FileManager.default.temporaryDirectory
                            .appendingPathComponent("\(UUID().uuidString).mov")
                        
                        do {
                            try FileManager.default.copyItem(at: videoURL, to: tempURL)
                            parent.onSelection(tempURL, nil)
                        } catch {
                            print("Error copying video: \(error)")
                            parent.onSelection(nil, nil)
                        }
                    }
                case .photo:
                    if let image = info[.originalImage] as? UIImage {
                        parent.onSelection(nil, image)
                    }
                }
            }
            
            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                picker.dismiss(animated: true)
                parent.onSelection(nil, nil)
            }
        }
    }
    
}
// MARK: - Preview
#Preview {
    UploadView()
}
