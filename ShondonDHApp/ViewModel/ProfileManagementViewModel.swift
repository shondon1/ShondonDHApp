//
//  ProfileManagementViewModel.swift
//  ShondonDHApp
//
//  ViewModel for managing profiles in Firestore
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import Combine

@MainActor
class ProfileManagementViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var profiles: [Profile] = []
    @Published var isLoading = true
    @Published var isSaving = false
    @Published var isDeleting = false
    @Published var uploadProgress: Double = 0.0
    @Published var statusMessage = ""
    @Published var showingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""

    // MARK: - Private Properties
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var listener: ListenerRegistration?
    private let collectionName = "profiles"
    private let storageBasePath = "profiles"

    // MARK: - Initialization
    init() {
        subscribeToProfiles()
    }

    deinit {
        listener?.remove()
    }

    // MARK: - Subscribe to Real-time Updates
    func subscribeToProfiles() {
        isLoading = true

        // Simple query without ordering first (to avoid index issues)
        listener = db.collection(collectionName)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                self.isLoading = false

                if let error = error {
                    let errorCode = (error as NSError).code
                    print("🔴 Error loading profiles: \(error.localizedDescription)")
                    print("🔴 Error code: \(errorCode)")

                    // More helpful error message
                    if error.localizedDescription.contains("permission") {
                        self.showError("Permission Denied", message: "Check that Firebase rules are published and include the 'profiles' collection. Also verify you're signed in.")
                    } else {
                        self.showError("Failed to load profiles", message: error.localizedDescription)
                    }
                    return
                }

                guard let documents = snapshot?.documents else {
                    self.profiles = []
                    return
                }

                self.profiles = documents.compactMap { doc -> Profile? in
                    try? doc.data(as: Profile.self)
                }
            }
    }

    // MARK: - Create Profile
    func createProfile(
        name: String,
        profileImage: UIImage,
        affiliation: String,
        occupation: String,
        favoriteSong: String,
        favoriteFood: String,
        unpopularOpinion: String,
        instagram: String,
        youtube: String,
        thirdSocial: String
    ) async throws {
        isSaving = true
        statusMessage = "Uploading image..."
        uploadProgress = 0.0

        do {
            // 1. Upload image to Firebase Storage
            let imageURL = try await uploadProfileImage(image: profileImage, profileId: UUID().uuidString)

            // 2. Get current max order
            let snapshot = try await db.collection(collectionName)
                .order(by: "order", descending: true)
                .limit(to: 1)
                .getDocuments()

            let maxOrder = snapshot.documents.first?.data()["order"] as? Int ?? -1

            // 3. Create Firestore document
            statusMessage = "Saving profile..."
            uploadProgress = 0.9

            var profileData: [String: Any] = [
                "name": name,
                "profileImage": imageURL,
                "order": maxOrder + 1,
                "isActive": true,
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ]

            // Add optional fields
            if !affiliation.isEmpty { profileData["affiliation"] = affiliation }
            if !occupation.isEmpty { profileData["occupation"] = occupation }
            if !favoriteSong.isEmpty { profileData["favoriteSong"] = favoriteSong }
            if !favoriteFood.isEmpty { profileData["favoriteFood"] = favoriteFood }
            if !unpopularOpinion.isEmpty { profileData["unpopularOpinion"] = unpopularOpinion }
            if !instagram.isEmpty { profileData["instagram"] = instagram }
            if !youtube.isEmpty { profileData["youtube"] = youtube }
            if !thirdSocial.isEmpty { profileData["thirdSocial"] = thirdSocial }

            try await db.collection(collectionName).addDocument(data: profileData)

            uploadProgress = 1.0
            statusMessage = "Profile created!"
            isSaving = false

            showSuccess("Profile Created", message: "\(name) has been added successfully.")

        } catch {
            isSaving = false
            statusMessage = ""
            throw error
        }
    }

    // MARK: - Update Profile
    func updateProfile(
        _ profile: Profile,
        name: String,
        newImage: UIImage?,
        affiliation: String,
        occupation: String,
        favoriteSong: String,
        favoriteFood: String,
        unpopularOpinion: String,
        instagram: String,
        youtube: String,
        thirdSocial: String
    ) async throws {
        guard let profileId = profile.id else {
            throw NSError(domain: "ProfileError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Profile ID not found"])
        }

        isSaving = true
        statusMessage = "Updating profile..."
        uploadProgress = 0.0

        do {
            var imageURL = profile.profileImage

            // Upload new image if provided
            if let newImage = newImage {
                statusMessage = "Uploading new image..."
                imageURL = try await uploadProfileImage(image: newImage, profileId: profileId)
            }

            // Build update data
            var profileData: [String: Any] = [
                "name": name,
                "profileImage": imageURL,
                "updatedAt": FieldValue.serverTimestamp()
            ]

            // Add optional fields (use NSNull or delete if empty)
            profileData["affiliation"] = affiliation.isEmpty ? FieldValue.delete() : affiliation
            profileData["occupation"] = occupation.isEmpty ? FieldValue.delete() : occupation
            profileData["favoriteSong"] = favoriteSong.isEmpty ? FieldValue.delete() : favoriteSong
            profileData["favoriteFood"] = favoriteFood.isEmpty ? FieldValue.delete() : favoriteFood
            profileData["unpopularOpinion"] = unpopularOpinion.isEmpty ? FieldValue.delete() : unpopularOpinion
            profileData["instagram"] = instagram.isEmpty ? FieldValue.delete() : instagram
            profileData["youtube"] = youtube.isEmpty ? FieldValue.delete() : youtube
            profileData["thirdSocial"] = thirdSocial.isEmpty ? FieldValue.delete() : thirdSocial

            statusMessage = "Saving changes..."
            uploadProgress = 0.9

            try await db.collection(collectionName).document(profileId).updateData(profileData)

            uploadProgress = 1.0
            statusMessage = "Profile updated!"
            isSaving = false

            showSuccess("Profile Updated", message: "\(name)'s profile has been updated.")

        } catch {
            isSaving = false
            statusMessage = ""
            throw error
        }
    }

    // MARK: - Delete Profile
    func deleteProfile(_ profile: Profile) async throws {
        guard let profileId = profile.id else {
            throw NSError(domain: "ProfileError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Profile ID not found"])
        }

        isDeleting = true

        do {
            // Delete profile image from storage if it's a Firebase URL
            if profile.profileImage.contains("firebasestorage") {
                try? await deleteProfileImage(profileId: profileId)
            }

            // Delete Firestore document
            try await db.collection(collectionName).document(profileId).delete()

            isDeleting = false
            showSuccess("Profile Deleted", message: "\(profile.name) has been removed.")

        } catch {
            isDeleting = false
            throw error
        }
    }

    // MARK: - Toggle Active Status
    func toggleActive(_ profile: Profile) {
        guard let id = profile.id else { return }

        db.collection(collectionName).document(id).updateData([
            "isActive": !profile.isActive,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    // MARK: - Reorder Profiles
    func reorderProfiles(from source: IndexSet, to destination: Int) {
        var reorderedProfiles = profiles
        reorderedProfiles.move(fromOffsets: source, toOffset: destination)

        // Update orders in Firestore using batch
        let batch = db.batch()

        for (index, profile) in reorderedProfiles.enumerated() {
            guard let id = profile.id else { continue }
            let ref = db.collection(collectionName).document(id)
            batch.updateData(["order": index, "updatedAt": FieldValue.serverTimestamp()], forDocument: ref)
        }

        batch.commit { error in
            if let error = error {
                print("Error reordering profiles: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Upload Profile Image
    func uploadProfileImage(image: UIImage, profileId: String) async throws -> String {
        // Resize image to 400x400
        let resizedImage = resizeImage(image: image, targetSize: CGSize(width: 400, height: 400))

        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "UploadError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image"])
        }

        // Check size (max 2MB)
        let maxSize = 2 * 1024 * 1024 // 2MB
        if imageData.count > maxSize {
            throw NSError(domain: "UploadError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Image exceeds 2MB limit"])
        }

        let fileName = "avatar.jpg"
        let storageRef = storage.reference().child("\(storageBasePath)/\(profileId)/\(fileName)")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await storageRef.putDataAsync(imageData, metadata: metadata) { [weak self] progress in
            if let progress = progress {
                let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                Task { @MainActor in
                    self?.uploadProgress = percentComplete * 0.8
                }
            }
        }

        let downloadURL = try await storageRef.downloadURL()
        return downloadURL.absoluteString
    }

    // MARK: - Delete Profile Image
    private func deleteProfileImage(profileId: String) async throws {
        let storageRef = storage.reference().child("\(storageBasePath)/\(profileId)/avatar.jpg")
        try await storageRef.delete()
    }

    // MARK: - Resize Image Helper
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // Choose the smaller ratio to fit within bounds
        let ratio = min(widthRatio, heightRatio)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - Alert Helpers
    private func showSuccess(_ title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }

    private func showError(_ title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}
