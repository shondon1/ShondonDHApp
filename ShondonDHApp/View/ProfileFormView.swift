//
//  ProfileFormView.swift
//  ShondonDHApp
//
//  Form view for creating and editing profiles
//

import SwiftUI
import PhotosUI

struct ProfileFormView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProfileManagementViewModel

    // MARK: - Mode
    enum Mode {
        case create
        case edit(Profile)

        var title: String {
            switch self {
            case .create: return "Add Profile"
            case .edit: return "Edit Profile"
            }
        }

        var buttonText: String {
            switch self {
            case .create: return "Create Profile"
            case .edit: return "Save Changes"
            }
        }
    }

    let mode: Mode

    // MARK: - Form State
    @State private var name = ""
    @State private var affiliation = ""
    @State private var occupation = ""
    @State private var favoriteSong = ""
    @State private var favoriteFood = ""
    @State private var unpopularOpinion = ""
    @State private var instagram = ""
    @State private var youtube = ""
    @State private var thirdSocial = ""

    // MARK: - Image State
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var existingImageURL: String?

    // MARK: - UI State
    @State private var showingError = false
    @State private var errorMessage = ""

    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                // Profile Image Section
                Section {
                    profileImageSection
                } header: {
                    Text("Profile Photo")
                } footer: {
                    Text("Required. Max 2MB, recommended 400x400 pixels.")
                }

                // Basic Info Section
                Section("Basic Information") {
                    TextField("Name *", text: $name)

                    TextField("Affiliation (e.g., PMC, T2S)", text: $affiliation)

                    TextField("Occupation / Role", text: $occupation)
                }

                // Favorites Section
                Section("Favorites") {
                    TextField("Favorite Song (Song - Artist)", text: $favoriteSong)

                    TextField("Favorite Food", text: $favoriteFood)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Unpopular Opinion")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $unpopularOpinion)
                            .frame(minHeight: 60)
                    }
                }

                // Social Links Section
                Section {
                    HStack {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.pink)
                            .frame(width: 24)
                        TextField("Instagram handle", text: $instagram)
                    }

                    HStack {
                        Image(systemName: "play.rectangle.fill")
                            .foregroundColor(.red)
                            .frame(width: 24)
                        TextField("YouTube channel", text: $youtube)
                    }

                    HStack {
                        Image(systemName: "at")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        TextField("X (Twitter) handle", text: $thirdSocial)
                    }
                } header: {
                    Text("Social Links")
                } footer: {
                    Text("Enter handles without the @ symbol.")
                }

                // Preview Section
                Section("Preview") {
                    profilePreview
                }

                // Upload Progress
                if viewModel.isSaving {
                    Section {
                        VStack(spacing: 10) {
                            ProgressView(value: viewModel.uploadProgress)
                                .progressViewStyle(LinearProgressViewStyle())

                            Text(viewModel.statusMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(mode.buttonText) {
                        Task {
                            await saveProfile()
                        }
                    }
                    .disabled(!isValid || viewModel.isSaving)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onChange(of: viewModel.showingAlert) { showing in
                if showing && !viewModel.alertTitle.contains("Error") {
                    dismiss()
                }
            }
            .onAppear {
                loadExistingData()
            }
        }
    }

    // MARK: - Profile Image Section
    private var profileImageSection: some View {
        VStack(spacing: 12) {
            Button(action: { showingImagePicker = true }) {
                if let image = selectedImage {
                    // Show selected image
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.blue, lineWidth: 3)
                        )
                } else if let urlString = existingImageURL, !urlString.isEmpty {
                    // Show existing image from URL
                    AsyncImage(url: URL(string: urlString)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.blue, lineWidth: 3)
                                )
                        case .failure:
                            placeholderImage
                        case .empty:
                            ProgressView()
                                .frame(width: 120, height: 120)
                        @unknown default:
                            placeholderImage
                        }
                    }
                } else {
                    // Show placeholder
                    placeholderImage
                }
            }
            .buttonStyle(.plain)

            Text(selectedImage != nil ? "Tap to change photo" : "Tap to select photo")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var placeholderImage: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 120, height: 120)

            VStack(spacing: 4) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)

                Text("Add Photo")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
    }

    // MARK: - Profile Preview
    private var profilePreview: some View {
        VStack(spacing: 12) {
            // Mini profile card preview
            HStack(spacing: 12) {
                // Avatar
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                } else if let urlString = existingImageURL, !urlString.isEmpty {
                    AsyncImage(url: URL(string: urlString)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Circle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(name.isEmpty ? "Name" : name)
                        .font(.headline)
                        .foregroundColor(name.isEmpty ? .gray : .primary)

                    if !affiliation.isEmpty {
                        Text(affiliation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if !occupation.isEmpty {
                        Text(occupation)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }

                Spacer()

                // Social icons preview
                HStack(spacing: 8) {
                    if !instagram.isEmpty {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.pink)
                            .font(.caption)
                    }
                    if !youtube.isEmpty {
                        Image(systemName: "play.rectangle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    if !thirdSocial.isEmpty {
                        Image(systemName: "at")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }

    // MARK: - Validation
    private var isValid: Bool {
        let hasName = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        switch mode {
        case .create:
            return hasName && selectedImage != nil
        case .edit:
            // For edit, image is optional (keep existing)
            return hasName && (selectedImage != nil || existingImageURL != nil)
        }
    }

    // MARK: - Load Existing Data (for Edit mode)
    private func loadExistingData() {
        if case .edit(let profile) = mode {
            name = profile.name
            affiliation = profile.affiliation ?? ""
            occupation = profile.occupation ?? ""
            favoriteSong = profile.favoriteSong ?? ""
            favoriteFood = profile.favoriteFood ?? ""
            unpopularOpinion = profile.unpopularOpinion ?? ""
            instagram = profile.instagram ?? ""
            youtube = profile.youtube ?? ""
            thirdSocial = profile.thirdSocial ?? ""
            existingImageURL = profile.profileImage
        }
    }

    // MARK: - Save Profile
    private func saveProfile() async {
        do {
            switch mode {
            case .create:
                guard let image = selectedImage else {
                    errorMessage = "Please select a profile photo."
                    showingError = true
                    return
                }

                try await viewModel.createProfile(
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    profileImage: image,
                    affiliation: affiliation.trimmingCharacters(in: .whitespacesAndNewlines),
                    occupation: occupation.trimmingCharacters(in: .whitespacesAndNewlines),
                    favoriteSong: favoriteSong.trimmingCharacters(in: .whitespacesAndNewlines),
                    favoriteFood: favoriteFood.trimmingCharacters(in: .whitespacesAndNewlines),
                    unpopularOpinion: unpopularOpinion.trimmingCharacters(in: .whitespacesAndNewlines),
                    instagram: instagram.trimmingCharacters(in: .whitespacesAndNewlines),
                    youtube: youtube.trimmingCharacters(in: .whitespacesAndNewlines),
                    thirdSocial: thirdSocial.trimmingCharacters(in: .whitespacesAndNewlines)
                )

            case .edit(let profile):
                try await viewModel.updateProfile(
                    profile,
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    newImage: selectedImage,
                    affiliation: affiliation.trimmingCharacters(in: .whitespacesAndNewlines),
                    occupation: occupation.trimmingCharacters(in: .whitespacesAndNewlines),
                    favoriteSong: favoriteSong.trimmingCharacters(in: .whitespacesAndNewlines),
                    favoriteFood: favoriteFood.trimmingCharacters(in: .whitespacesAndNewlines),
                    unpopularOpinion: unpopularOpinion.trimmingCharacters(in: .whitespacesAndNewlines),
                    instagram: instagram.trimmingCharacters(in: .whitespacesAndNewlines),
                    youtube: youtube.trimmingCharacters(in: .whitespacesAndNewlines),
                    thirdSocial: thirdSocial.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = true
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

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let edited = info[.editedImage] as? UIImage {
                parent.image = edited
            } else if let original = info[.originalImage] as? UIImage {
                parent.image = original
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview
#Preview("Create Mode") {
    ProfileFormView(viewModel: ProfileManagementViewModel(), mode: .create)
}

#Preview("Edit Mode") {
    ProfileFormView(viewModel: ProfileManagementViewModel(), mode: .edit(Profile.sample))
}
