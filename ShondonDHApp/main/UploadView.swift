//
//  UploadView.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 6/21/25.
//



import SwiftUI
import Firebase
import FirebaseStorage
import UniformTypeIdentifiers
import FirebaseFirestore
// import FirebaseFirestoreSwift

// MARK: - Data Model
struct RadioContent: Codable, Identifiable {
    @DocumentID var id: String?
    var type: String = "none"        // "audio", "video", "youtube", "live", "none"
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
    @State private var isPickerPresented: Bool = false

    let mediaTypes = ["Audio", "Video", "YouTube"]

    var body: some View {
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

            if type != "YouTube" {
                Button("Choose File") {
                    isPickerPresented = true
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .fileImporter(
                    isPresented: $isPickerPresented,
                    allowedContentTypes: [UTType.audio, UTType.movie],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        mediaURL = urls.first
                    case .failure(let error):
                        uploadStatus = "File selection failed: \(error.localizedDescription)"
                    }
                }
            } else {
                TextField("YouTube URL", text: $youtubeURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
            }

            Button(action: uploadMedia) {
                if isUploading {
                    ProgressView()
                } else {
                    Text("Upload")
                        .bold()
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)

            if !uploadStatus.isEmpty {
                Text(uploadStatus)
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .padding()
    }

    // MARK: - Upload Logic
    func uploadMedia() {
        guard !title.isEmpty else {
            uploadStatus = "Title required."
            return
        }

        isUploading = true
        uploadStatus = ""

        if type == "YouTube" {
            let content = RadioContent(
                type: "youtube",
                url: youtubeURL,
                title: title,
                isPlaying: false
            )
            saveToFirestore(content: content)
        } else if let mediaURL = mediaURL {
            let ext = mediaURL.pathExtension
            let storageRef = Storage.storage().reference().child("media/\(UUID().uuidString).\(ext)")

            storageRef.putFile(from: mediaURL, metadata: nil) { metadata, error in
                if let error = error {
                    uploadStatus = "Upload failed: \(error.localizedDescription)"
                    isUploading = false
                    return
                }

                storageRef.downloadURL { url, error in
                    guard let downloadURL = url else {
                        uploadStatus = "URL retrieval failed."
                        isUploading = false
                        return
                    }

                    let isVideo = type.lowercased() == "video"
                    let content = RadioContent(
                        type: isVideo ? "video" : "audio",
                        url: downloadURL.absoluteString,
                        title: title,
                        isPlaying: false
                    )
                    saveToFirestore(content: content)
                }
            }
        } else {
            uploadStatus = "No media selected."
            isUploading = false
        }
    }

    func saveToFirestore(content: RadioContent) {
        let db = Firestore.firestore()
        do {
            try db.collection("radioFlow").addDocument(from: content) { error in
                if let error = error {
                    uploadStatus = "Error saving: \(error.localizedDescription)"
                } else {
                    uploadStatus = "Upload successful!"
                    title = ""
                    youtubeURL = ""
                    mediaURL = nil
                }
                isUploading = false
            }
        } catch {
            uploadStatus = "Serialization failed."
            isUploading = false
        }
    }
}

#Preview {
    UploadView()
}
