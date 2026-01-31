//
//  ProfileModel.swift
//  ShondonDHApp
//
//  Profile model for the DreamHouse community members
//

import Foundation
import SwiftUI
import FirebaseFirestore

// MARK: - Profile Model
struct Profile: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var profileImage: String
    var affiliation: String?
    var occupation: String?
    var favoriteSong: String?
    var favoriteFood: String?
    var unpopularOpinion: String?
    var instagram: String?
    var youtube: String?
    var thirdSocial: String?
    var order: Int
    var isActive: Bool
    var createdAt: Date?
    var updatedAt: Date?

    // MARK: - Computed Properties

    var displayName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var instagramURL: URL? {
        guard let handle = instagram, !handle.isEmpty else { return nil }
        let cleanHandle = handle.replacingOccurrences(of: "@", with: "")
        return URL(string: "https://instagram.com/\(cleanHandle)")
    }

    var youtubeURL: URL? {
        guard let channel = youtube, !channel.isEmpty else { return nil }
        return URL(string: "https://youtube.com/@\(channel)")
    }

    var twitterURL: URL? {
        guard let handle = thirdSocial, !handle.isEmpty else { return nil }
        let cleanHandle = handle.replacingOccurrences(of: "@", with: "")
        return URL(string: "https://x.com/\(cleanHandle)")
    }

    var hasSocialLinks: Bool {
        (instagram != nil && !instagram!.isEmpty) ||
        (youtube != nil && !youtube!.isEmpty) ||
        (thirdSocial != nil && !thirdSocial!.isEmpty)
    }

    // MARK: - Firestore Data Conversion

    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "name": name,
            "profileImage": profileImage,
            "order": order,
            "isActive": isActive,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        // Add optional fields only if they have values
        if let affiliation = affiliation, !affiliation.isEmpty {
            data["affiliation"] = affiliation
        }
        if let occupation = occupation, !occupation.isEmpty {
            data["occupation"] = occupation
        }
        if let favoriteSong = favoriteSong, !favoriteSong.isEmpty {
            data["favoriteSong"] = favoriteSong
        }
        if let favoriteFood = favoriteFood, !favoriteFood.isEmpty {
            data["favoriteFood"] = favoriteFood
        }
        if let unpopularOpinion = unpopularOpinion, !unpopularOpinion.isEmpty {
            data["unpopularOpinion"] = unpopularOpinion
        }
        if let instagram = instagram, !instagram.isEmpty {
            data["instagram"] = instagram
        }
        if let youtube = youtube, !youtube.isEmpty {
            data["youtube"] = youtube
        }
        if let thirdSocial = thirdSocial, !thirdSocial.isEmpty {
            data["thirdSocial"] = thirdSocial
        }

        return data
    }

    // MARK: - Empty Profile Factory

    static func empty(order: Int = 0) -> Profile {
        Profile(
            name: "",
            profileImage: "",
            affiliation: nil,
            occupation: nil,
            favoriteSong: nil,
            favoriteFood: nil,
            unpopularOpinion: nil,
            instagram: nil,
            youtube: nil,
            thirdSocial: nil,
            order: order,
            isActive: true,
            createdAt: nil,
            updatedAt: nil
        )
    }
}

// MARK: - Profile Extension for Preview
extension Profile {
    static var sample: Profile {
        Profile(
            id: "sample1",
            name: "DJ Shondon",
            profileImage: "https://example.com/image.jpg",
            affiliation: "DreamHouse",
            occupation: "DJ / Producer",
            favoriteSong: "Sunset Dreams - The Vibers",
            favoriteFood: "Jerk Chicken",
            unpopularOpinion: "Pineapple belongs on pizza",
            instagram: "djshondon",
            youtube: "DJShondon",
            thirdSocial: "djshondon",
            order: 1,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
