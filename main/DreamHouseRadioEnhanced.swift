//
//  DreamHouseRadioEnhanced.swift
//  DreamHouse
//
//  Created by Rashon Hyslop on 7/19/25.
//

import SwiftUI
import AVKit
import WebKit
import FirebaseFirestore


// MARK: - Color Extension
extension Color {
    static let deepTeal = Color(red: 61/255, green: 90/255, blue: 128/255)
    static let skyTeal = Color(red: 144/255, green: 224/255, blue: 239/255)
    static let peachGold = Color(red: 254/255, green: 209/255, blue: 140/255)
    static let charcoal = Color(red: 51/255, green: 51/255, blue: 51/255)
}

// MARK: - Enhanced Data Models
struct RadioContent: Codable, Identifiable {
    @DocumentID var id: String?
    var type: String = "audio"
    var url: String = ""
    var title: String = ""
    var artist: String? = nil
    var thumbnailURL: String? = nil
    var duration: Double? = nil
    var order: Int = 0
    var createdAt: Timestamp? = nil
}

struct TickerMessage: Codable, Identifiable {
    @DocumentID var id: String?
    var message: String = ""
    var isActive: Bool = true
    var priority: Int = 0
    var createdAt: Timestamp? = nil
    var expiresAt: Timestamp? = nil
}

// MARK: - Enhanced ViewModel
class EnhancedRadioViewModel: NSObject, ObservableObject {
    var objectWillChange: ObservableObjectPublisher
    
    @Published var playlist: [RadioContent] = []
    @Published var currentIndex: Int = 0
    @Published var isLive: Bool = false
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var liveTrackTitle: String? = nil
    @Published var listenerCount: Int = 0
    @Published var nextUpTitle: String = ""
    @Published var isBuffering: Bool = false
    @Published var currentLiveType: String = "icecast"
    @Published var isPlaying: Bool = true
    
    // Ticker Management
    @Published var tickerMessages: [TickerMessage] = []
    @Published var currentTickerMessage: String = ""
    @Published var showTickerControl: Bool = false
    
    private let db = Firestore.firestore()
    private var playlistListener: ListenerRegistration?
    private var tickerListener: ListenerRegistration?
    private var liveStatusListener: ListenerRegistration?
    private var liveTimer: Timer?
    private var progressTimer: Timer?
    private var tickerTimer: Timer?
    @Published var player: AVPlayer?
    private var endObserver: NSObjectProtocol?
    private var timeObserver: Any?
    private var resumeIndex: Int? = nil
    private var resumeTime: Double? = nil
    
    // Live stream URLs
    private let icecastURL = "https://radio.pmcshondon.com/dreamhouse"
    private let statusURL = "https://radio.pmcshondon.com/status-json.xsl"
    
    override init() {
        super.init()
        setupAudioSession()
        subscribeToRadioFlow()
        subscribeToTickerMessages()
        subscribeLiveStatus()
        startLivePolling()
        startTickerRotation()
    }
    
    deinit {
        cleanup()
    }
    
    private func cleanup() {
        playlistListener?.remove()
        tickerListener?.remove()
        liveStatusListener?.remove()
        liveTimer?.invalidate()
        progressTimer?.invalidate()
        tickerTimer?.invalidate()
        if let obs = endObserver { NotificationCenter.default.removeObserver(obs) }
        if let timeObs = timeObserver { player?.removeTimeObserver(timeObs) }
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Ticker Management
    private func subscribeToTickerMessages() {
        tickerListener = db.collection("tickerMessages")
            .whereField("isActive", isEqualTo: true)
            .order(by: "priority", descending: true)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let e = error {
                    self.errorMessage = e.localizedDescription
                } else if let docs = snapshot?.documents {
                    do {
                        self.tickerMessages = try docs.compactMap { try $0.data(as: TickerMessage.self) }
                        self.updateCurrentTickerMessage()
                    } catch {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
    }
    
    private func startTickerRotation() {
        tickerTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { [weak self] _ in
            self?.rotateTickerMessage()
        }
    }
    
    private func updateCurrentTickerMessage() {
        let activeMessages = tickerMessages.filter { message in
            guard message.isActive else { return false }
            if let expiresAt = message.expiresAt {
                return expiresAt.dateValue() > Date()
            }
            return true
        }
        
        if !activeMessages.isEmpty {
            currentTickerMessage = activeMessages.first?.message ?? ""
        } else {
            currentTickerMessage = "🎵 Welcome to DreamHouse Radio - Your 24/7 Vibe Station 🎵"
        }
    }
    
    private func rotateTickerMessage() {
        let activeMessages = tickerMessages.filter { message in
            guard message.isActive else { return false }
            if let expiresAt = message.expiresAt {
                return expiresAt.dateValue() > Date()
            }
            return true
        }
        
        if activeMessages.count > 1 {
            // Rotate through messages
            if let currentIndex = activeMessages.firstIndex(where: { $0.message == currentTickerMessage }) {
                let nextIndex = (currentIndex + 1) % activeMessages.count
                currentTickerMessage = activeMessages[nextIndex].message
            } else {
                currentTickerMessage = activeMessages.first?.message ?? ""
            }
        }
    }
    
    // MARK: - Ticker Control Functions
    func addTickerMessage(_ message: String, priority: Int = 0, expiresIn: TimeInterval? = nil) async {
        let db = Firestore.firestore()
        var data: [String: Any] = [
            "message": message,
            "isActive": true,
            "priority": priority,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        if let expiresIn = expiresIn {
            data["expiresAt"] = Timestamp(date: Date().addingTimeInterval(expiresIn))
        }
        
        do {
            try await db.collection("tickerMessages").addDocument(data: data)
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to add ticker message: \(error.localizedDescription)"
            }
        }
    }
    
    func updateTickerMessage(_ messageId: String, isActive: Bool) async {
        let db = Firestore.firestore()
        do {
            try await db.collection("tickerMessages").document(messageId).updateData([
                "isActive": isActive
            ])
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to update ticker message: \(error.localizedDescription)"
            }
        }
    }
    
    func deleteTickerMessage(_ messageId: String) async {
        let db = Firestore.firestore()
        do {
            try await db.collection("tickerMessages").document(messageId).delete()
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to delete ticker message: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Radio Flow Management
    private func subscribeToRadioFlow() {
        isLoading = true
        playlistListener = db.collection("radioFlow")
            .order(by: "order")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let e = error {
                    self.errorMessage = e.localizedDescription
                    self.isLoading = false
                } else if let docs = snapshot?.documents {
                    do {
                        self.playlist = try docs.compactMap { try $0.data(as: RadioContent.self) }
                        self.isLoading = false
                        
                        if !self.isLive && !self.playlist.isEmpty && self.player == nil {
                            self.currentIndex = 0
                            self.playCurrent()
                            self.updateNextUp()
                        }
                    } catch {
                        self.errorMessage = error.localizedDescription
                        self.isLoading = false
                    }
                }
            }
    }
    
    // ... existing radio functionality methods remain the same as in the original ...
    
    private func subscribeLiveStatus() {
        liveStatusListener = db.collection("liveStatus")
            .document("current")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self,
                      let data = snapshot?.data() else { return }
                
                let isLiveNow = data["isLive"] as? Bool ?? false
                let liveType = data["type"] as? String ?? "icecast"
                let liveURL = data["url"] as? String
                let liveTitle = data["title"] as? String
                
                DispatchQueue.main.async {
                    if isLiveNow && !self.isLive && liveURL != nil {
                        self.resumeIndex = self.currentIndex
                        self.resumeTime = self.currentTime
                        self.isLive = true
                        self.currentLiveType = liveType
                        self.liveTrackTitle = liveTitle
                        self.playLiveContent(url: liveURL!, type: liveType)
                    } else if !isLiveNow && self.isLive && liveType != "icecast" {
                        self.isLive = false
                        if let idx = self.resumeIndex {
                            self.currentIndex = idx
                        }
                        self.playCurrent(resumeTime: self.resumeTime)
                        self.resumeIndex = nil
                        self.resumeTime = nil
                    }
                }
            }
    }
    
    private func startLivePolling() {
        liveTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.checkIcecastStatus()
        }
        checkIcecastStatus()
    }
    
    private func checkIcecastStatus() {
        guard let url = URL(string: statusURL) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self,
                  let data = data,
                  let stats = try? JSONDecoder().decode(IcecastStats.self, from: data)
            else { return }
            
            let liveMount = stats.icestats.source.first { $0.mount == "/dreamhouse" }
            DispatchQueue.main.async {
                let nowLive = (liveMount?.listeners ?? 0) > 0
                self.listenerCount = liveMount?.listeners ?? 0
                
                if nowLive && !self.isLive {
                    self.resumeIndex = self.currentIndex
                    self.resumeTime = self.currentTime
                    self.isLive = true
                    self.currentLiveType = "icecast"
                    self.liveTrackTitle = liveMount?.title ?? "Live Broadcast"
                    self.playLiveStream()
                } else if !nowLive && self.isLive && self.currentLiveType == "icecast" {
                    self.isLive = false
                    if let idx = self.resumeIndex {
                        self.currentIndex = idx
                    }
                    self.playCurrent(resumeTime: self.resumeTime)
                    self.resumeIndex = nil
                    self.resumeTime = nil
                }
            }
        }.resume()
    }
    
    private func updateNextUp() {
        guard !playlist.isEmpty else { return }
        let nextIndex = (currentIndex + 1) % playlist.count
        nextUpTitle = playlist[nextIndex].title
    }
    
    private func playCurrent(resumeTime: Double? = nil) {
        guard !playlist.isEmpty else { return }
        let item = playlist[currentIndex]
        setupPlayer(item: item, onEnd: advance, resumeTime: resumeTime)
        updateNextUp()
    }
    
    private func playLiveStream() {
        let liveItem = RadioContent(
            type: "live",
            url: icecastURL,
            title: "Live Broadcast"
        )
        setupPlayer(item: liveItem, onEnd: nil)
    }
    
    private func playLiveContent(url: String, type: String) {
        let liveItem = RadioContent(
            type: type,
            url: url,
            title: liveTrackTitle ?? "Live Stream"
        )
        setupPlayer(item: liveItem, onEnd: nil)
    }
    
    func advance() {
        guard !playlist.isEmpty else { return }
        currentIndex = (currentIndex + 1) % playlist.count
        playCurrent()
    }
    
    private func setupPlayer(item: RadioContent, onEnd: (() -> Void)?, resumeTime: Double? = nil) {
        if let obs = endObserver {
            NotificationCenter.default.removeObserver(obs)
        }
        if let timeObs = timeObserver {
            player?.removeTimeObserver(timeObs)
            timeObserver = nil
        }
        
        player?.pause()
        player = nil
        currentTime = 0
        duration = 0
        isBuffering = true
        
        guard let url = URL(string: item.url) else {
            isBuffering = false
            return
        }
        
        if item.type == "youtube" || item.type == "twitch" {
            isBuffering = false
            return
        }
        
        player = AVPlayer(url: url)
        
        if item.type == "video" {
            player?.currentItem?.videoComposition = AVVideoComposition(propertiesOf: player!.currentItem!.asset)
        }
        
        player?.currentItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
        player?.currentItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
        
        if let finish = onEnd {
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player?.currentItem,
                queue: .main) { _ in finish() }
        }
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            if let duration = self.player?.currentItem?.duration, !duration.isIndefinite {
                self.duration = duration.seconds
            }
        }
        
        if let t = resumeTime, t > 0 {
            player?.seek(to: CMTime(seconds: t, preferredTimescale: 600))
        }
        player?.play()
        isPlaying = true
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "playbackBufferEmpty" {
            isBuffering = true
        } else if keyPath == "playbackLikelyToKeepUp" {
            isBuffering = false
        }
    }
    
    func formatTime(_ seconds: Double) -> String {
        if seconds.isNaN || seconds.isInfinite { return "--:--" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Icecast Status Structures
struct IcecastStats: Codable {
    struct Source: Codable {
        let mount: String
        let listeners: Int
        let server_description: String?
        let title: String?
    }
    let icestats: StatsContainer
    struct StatsContainer: Codable {
        let source: [Source]
    }
} 
