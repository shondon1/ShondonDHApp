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
import UniformTypeIdentifiers

struct UploadView: View {
    @StateObject private var viewModel = UploadViewModel()
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            Section("Block Details") {
                TextField("Title", text: $viewModel.title)
                TextField("Start Time (HH:mm)", text: $viewModel.startTime)
                    .keyboardType(.numbersAndPunctuation)
                TextField("Duration (e.g., 00:30:00)", text: $viewModel.duration)
                    .keyboardType(.numbersAndPunctuation)
                
                Picker("Type", selection: $viewModel.type) {
                    Text("Music").tag("music")
                    Text("Show").tag("show")
                    Text("Promo").tag("promo")
                }
                .pickerStyle(.segmented)
                
                Toggle("Has Video?", isOn: $viewModel.hasVideo)
            }
            
            Section("Media Files") {
                FilePickerView(fileURL: $viewModel.audioURL, label: "Select Audio File")
                
                if viewModel.hasVideo {
                    FilePickerView(fileURL: $viewModel.videoURL, label: "Select Video File")
                }
            }
            
            Section {
                Button("Upload & Save") {
                    if viewModel.isValid() {
                        viewModel.uploadAndSave { success, message in
                            alertMessage = message
                            showingAlert = true
                        }
                    } else {
                        alertMessage = "Please fill in all required fields and select an audio file."
                        showingAlert = true
                    }
                }
                .disabled(viewModel.isUploading)
            }
            
            if viewModel.isUploading {
                Section {
                    HStack {
                        ProgressView()
                        Text("Uploading...")
                    }
                }
            }
        }
        .navigationTitle("Upload New Block")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Upload Status", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
}
