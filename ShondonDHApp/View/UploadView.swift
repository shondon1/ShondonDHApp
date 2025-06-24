//
//  UploadView.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 6/21/25.
//




import SwiftUI
import UniformTypeIdentifiers

struct UploadView: View {
    @StateObject private var viewModel = UploadViewModel()
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Upload Status"
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Block Details Section
                Section("Content Details") {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Track/Show Title", text: $viewModel.title)
                            .textFieldStyle(.roundedBorder)
                        
                        if viewModel.title.isEmpty {
                            Text("Required: Enter a title for this content")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    HStack {
                        VStack(alignment: .leading) {
                            TextField("Start Time (HH:mm)", text: $viewModel.startTime)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numbersAndPunctuation)
                            
                            Text("Example: 14:30 for 2:30 PM")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading) {
                            TextField("Duration (HH:mm:ss)", text: $viewModel.duration)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numbersAndPunctuation)
                            
                            Text("Example: 00:03:45")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Picker("Content Type", selection: $viewModel.type) {
                        Label("Music Track", systemImage: "music.note").tag("music")
                        Label("Show/Talk", systemImage: "mic").tag("show")
                        Label("Promo/Ad", systemImage: "megaphone").tag("promo")
                    }
                    .pickerStyle(.segmented)
                    
                    Toggle("Has Video Component?", isOn: $viewModel.hasVideo)
                }
                
                // MARK: - Media Files Section
                Section("Media Files") {
                    EnhancedFilePickerView(
                        fileURL: $viewModel.audioURL,
                        label: "Select Audio File",
                        systemImage: "music.note",
                        allowedTypes: [.audio, .mp3],
                        isRequired: true
                    )
                    
                    if viewModel.hasVideo {
                        EnhancedFilePickerView(
                            fileURL: $viewModel.videoURL,
                            label: "Select Video File",
                            systemImage: "video",
                            allowedTypes: [.movie, .mpeg4Movie],
                            isRequired: false
                        )
                    }
                }
                
                // MARK: - Upload Section
                Section {
                    Button(action: uploadContent) {
                        HStack {
                            if viewModel.isUploading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "icloud.and.arrow.up")
                            }
                            
                            Text(viewModel.isUploading ? "Uploading..." : "Upload to Radio")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(uploadButtonColor)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.isUploading || !viewModel.isValid())
                    
                    if viewModel.isUploading {
                        VStack(spacing: 8) {
                            ProgressView(value: viewModel.uploadProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                            
                            Text(viewModel.uploadStatus)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(Int(viewModel.uploadProgress * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                }
                
                // MARK: - Quick Actions Section
                if !viewModel.isUploading {
                    Section("Quick Setup") {
                        Button("Fill Sample Music Track") {
                            fillSampleMusicData()
                        }
                        
                        Button("Fill Sample Show Segment") {
                            fillSampleShowData()
                        }
                        
                        Button("Fill Sample Promo") {
                            fillSamplePromoData()
                        }
                    }
                }
            }
            .navigationTitle("Upload Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") {
                    if alertTitle == "Success" {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Helper Methods
    private var uploadButtonColor: Color {
        if viewModel.isUploading {
            return .gray
        } else if viewModel.isValid() {
            return .blue
        } else {
            return .gray
        }
    }
    
    private func uploadContent() {
        viewModel.uploadAndSave { success, message in
            alertTitle = success ? "Success" : "Error"
            alertMessage = message
            showingAlert = true
        }
    }
    
    private func fillSampleMusicData() {
        viewModel.title = "Sample Track"
        viewModel.startTime = "12:00"
        viewModel.duration = "00:03:30"
        viewModel.type = "music"
        viewModel.hasVideo = false
    }
    
    private func fillSampleShowData() {
        viewModel.title = "Morning Talk Segment"
        viewModel.startTime = "08:00"
        viewModel.duration = "00:15:00"
        viewModel.type = "show"
        viewModel.hasVideo = true
    }
    
    private func fillSamplePromoData() {
        viewModel.title = "Station ID Jingle"
        viewModel.startTime = "13:30"
        viewModel.duration = "00:00:30"
        viewModel.type = "promo"
        viewModel.hasVideo = false
    }
}

// MARK: - Enhanced File Picker
struct EnhancedFilePickerView: View {
    @Binding var fileURL: URL?
    let label: String
    let systemImage: String
    let allowedTypes: [UTType]
    let isRequired: Bool
    @State private var showingDocumentPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                showingDocumentPicker = true
            }) {
                HStack {
                    Image(systemName: systemImage)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text(label)
                            .foregroundColor(.primary)
                        
                        if isRequired && fileURL == nil {
                            Text("Required")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    Spacer()
                    
                    if let url = fileURL {
                        VStack(alignment: .trailing) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Selected")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    } else {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            if let url = fileURL {
                HStack {
                    Text("📎 \(url.lastPathComponent)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button("Remove") {
                        fileURL = nil
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
                .padding(.horizontal, 4)
            }
        }
        .sheet(isPresented: $showingDocumentPicker) {
            EnhancedDocumentPicker(fileURL: $fileURL, allowedTypes: allowedTypes)
        }
    }
}

// MARK: - Enhanced Document Picker
struct EnhancedDocumentPicker: UIViewControllerRepresentable {
    @Binding var fileURL: URL?
    let allowedTypes: [UTType]
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: allowedTypes,
            asCopy: true
        )
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: EnhancedDocumentPicker
        
        init(_ parent: EnhancedDocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                parent.fileURL = url
            }
            parent.dismiss()
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}

#Preview {
    UploadView()
}
