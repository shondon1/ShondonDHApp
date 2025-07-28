//  DreamHouseRadio.swift
//  DreamHouse
//
//  Created by Rashon Hyslop on 7/19/25.
//

// import SwiftUI
// import AVKit
// import WebKit
// import FirebaseFirestore
// import FirebaseFirestoreSwift

// // MARK: - Color Extension
// extension Color {
//     static let deepTeal = Color(red: 61/255, green: 90/255, blue: 128/255)
//     static let skyTeal = Color(red: 144/255, green: 224/255, blue: 239/255)
//     static let peachGold = Color(red: 254/255, green: 209/255, blue: 140/255)
//     static let charcoal = Color(red: 51/255, green: 51/255, blue: 51/255)
// }

// // MARK: - Data Model
// struct RadioContent: Codable, Identifiable {
//     @DocumentID var id: String?
//     var type: String = "audio"
//     var url: String = ""
//     var title: String = ""
//     var artist: String? = nil
//     var thumbnailURL: String? = nil
//     var duration: Double? = nil
//     var order: Int = 0
// }

// // MARK: - Icecast Status Structures
// struct IcecastStats: Codable {
//     struct Source: Codable {
//         let mount: String
//         let listeners: Int
//         let server_description: String?
//         let title: String?
//     }
//     let icestats: StatsContainer
//     struct StatsContainer: Codable {
//         let source: [Source]
//     }
// }

// // MARK: - ViewModel Protocol
// protocol RadioViewModelProtocol: ObservableObject {
//     var playlist: [RadioContent] { get }
//     var currentIndex: Int { get }
//     var isLive: Bool { get }
//     var isLoading: Bool { get }
//     var errorMessage: String? { get }
//     var currentTime: Double { get }
//     var duration: Double { get }
//     var liveTrackTitle: String? { get }
//     var listenerCount: Int { get }
//     var nextUpTitle: String { get }
//     var isBuffering: Bool { get }
//     var currentLiveType: String { get }
//     var player: AVPlayer? { get }
//     var isPlaying: Bool { get }
    
//     func formatTime(_ seconds: Double) -> String
// }

// // MARK: - Main ViewModel
// class RadioViewModel: NSObject, ObservableObject, RadioViewModelProtocol {
//     @Published var playlist: [RadioContent] = []
//     @Published var currentIndex: Int = 0
//     @Published var isLive: Bool = false
//     @Published var isLoading = true
//     @Published var errorMessage: String?
//     @Published var currentTime: Double = 0
//     @Published var duration: Double = 0
//     @Published var liveTrackTitle: String? = nil
//     @Published var listenerCount: Int = 0
//     @Published var nextUpTitle: String = ""
//     @Published var isBuffering: Bool = false
//     @Published var currentLiveType: String = "icecast"
//     @Published var isPlaying: Bool = true
    
//     private let db = Firestore.firestore()
//     private var playlistListener: ListenerRegistration?
//     private var liveStatusListener: ListenerRegistration?
//     private var liveTimer: Timer?
//     private var progressTimer: Timer?
//     @Published var player: AVPlayer?
//     private var endObserver: NSObjectProtocol?
//     private var timeObserver: Any?
//     private var resumeIndex: Int? = nil
//     private var resumeTime: Double? = nil
    
//     // Live stream URLs
//     private let icecastURL = "https://radio.pmcshondon.com/dreamhouse"
//     private let statusURL = "https://radio.pmcshondon.com/status-json.xsl"
    
//     override init() {
//         super.init()
//         subscribeToRadioFlow()
//         subscribeLiveStatus()
//         startLivePolling()
//         setupAudioSession()
//     }
    
//     deinit {
//         playlistListener?.remove()
//         liveStatusListener?.remove()
//         liveTimer?.invalidate()
//         progressTimer?.invalidate()
//         if let obs = endObserver { NotificationCenter.default.removeObserver(obs) }
//         if let timeObs = timeObserver { player?.removeTimeObserver(timeObs) }
//     }
    
//     private func setupAudioSession() {
//         do {
//             try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
//             try AVAudioSession.sharedInstance().setActive(true)
//         } catch {
//             print("Failed to setup audio session: \(error)")
//         }
//     }
    
//     private func subscribeToRadioFlow() {
//         isLoading = true
//         playlistListener = db.collection("radioFlow")
//             .order(by: "order")
//             .addSnapshotListener { [weak self] snapshot, error in
//                 guard let self = self else { return }
//                 if let e = error {
//                     self.errorMessage = e.localizedDescription
//                     self.isLoading = false
//                 } else if let docs = snapshot?.documents {
//                     do {
//                         self.playlist = try docs.compactMap { try $0.data(as: RadioContent.self) }
//                         self.isLoading = false
                        
//                         if !self.isLive && !self.playlist.isEmpty && self.player == nil {
//                             self.currentIndex = 0
//                             self.playCurrent()
//                             self.updateNextUp()
//                         }
//                     } catch {
//                         self.errorMessage = error.localizedDescription
//                         self.isLoading = false
//                     }
//                 }
//             }
//     }
    
//     private func subscribeLiveStatus() {
//         liveStatusListener = db.collection("liveStatus")
//             .document("current")
//             .addSnapshotListener { [weak self] snapshot, error in
//                 guard let self = self,
//                       let data = snapshot?.data() else { return }
                
//                 let isLiveNow = data["isLive"] as? Bool ?? false
//                 let liveType = data["type"] as? String ?? "icecast"
//                 let liveURL = data["url"] as? String
//                 let liveTitle = data["title"] as? String
                
//                 DispatchQueue.main.async {
//                     if isLiveNow && !self.isLive && liveURL != nil {
//                         // For Twitch, optionally verify stream is actually live
//                         if liveType == "twitch" {
//                             self.verifyTwitchLive(url: liveURL!) { isActuallyLive in
//                                 if isActuallyLive {
//                                     self.resumeIndex = self.currentIndex
//                                     self.resumeTime = self.currentTime
//                                     self.isLive = true
//                                     self.currentLiveType = liveType
//                                     self.liveTrackTitle = liveTitle
//                                     self.playLiveContent(url: liveURL!, type: liveType)
//                                 }
//                             }
//                         } else {
//                             // For other types, trust Firestore
//                             self.resumeIndex = self.currentIndex
//                             self.resumeTime = self.currentTime
//                             self.isLive = true
//                             self.currentLiveType = liveType
//                             self.liveTrackTitle = liveTitle
//                             self.playLiveContent(url: liveURL!, type: liveType)
//                         }
//                     } else if !isLiveNow && self.isLive && liveType != "icecast" {
//                         self.isLive = false
//                         if let idx = self.resumeIndex {
//                             self.currentIndex = idx
//                         }
//                         self.playCurrent(resumeTime: self.resumeTime)
//                         self.resumeIndex = nil
//                         self.resumeTime = nil
//                     }
//                 }
//             }
//     }
    
//     // Optional: Add Twitch live verification
//     private func verifyTwitchLive(url: String, completion: @escaping (Bool) -> Void) {
//         // For now, just trust Firestore setting
//         // In production, you could check Twitch API
//         completion(true)
//     }
    
//     private func startLivePolling() {
//         liveTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
//             self?.checkIcecastStatus()
//         }
//         checkIcecastStatus()
//     }
    
//     private func checkIcecastStatus() {
//         guard let url = URL(string: statusURL) else { return }
//         URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
//             guard let self = self,
//                   let data = data,
//                   let stats = try? JSONDecoder().decode(IcecastStats.self, from: data)
//             else { return }
            
//             let liveMount = stats.icestats.source.first { $0.mount == "/dreamhouse" }
//             DispatchQueue.main.async {
//                 let nowLive = (liveMount?.listeners ?? 0) > 0
//                 self.listenerCount = liveMount?.listeners ?? 0
                
//                 if nowLive && !self.isLive {
//                     self.resumeIndex = self.currentIndex
//                     self.resumeTime = self.currentTime
//                     self.isLive = true
//                     self.currentLiveType = "icecast"
//                     self.liveTrackTitle = liveMount?.title ?? "Live Broadcast"
//                     self.playLiveStream()
//                 } else if !nowLive && self.isLive && self.currentLiveType == "icecast" {
//                     self.isLive = false
//                     if let idx = self.resumeIndex {
//                         self.currentIndex = idx
//                     }
//                     self.playCurrent(resumeTime: self.resumeTime)
//                     self.resumeIndex = nil
//                     self.resumeTime = nil
//                 }
//             }
//         }.resume()
//     }
    
//     private func updateNextUp() {
//         guard !playlist.isEmpty else { return }
//         let nextIndex = (currentIndex + 1) % playlist.count
//         nextUpTitle = playlist[nextIndex].title
//     }
    
//     private func playCurrent(resumeTime: Double? = nil) {
//         guard !playlist.isEmpty else { return }
//         let item = playlist[currentIndex]
//         setupPlayer(item: item, onEnd: advance, resumeTime: resumeTime)
//         updateNextUp()
//     }
    
//     private func playLiveStream() {
//         let liveItem = RadioContent(
//             type: "live",
//             url: icecastURL,
//             title: "Live Broadcast"
//         )
//         setupPlayer(item: liveItem, onEnd: nil)
//     }
    
//     private func playLiveContent(url: String, type: String) {
//         let liveItem = RadioContent(
//             type: type,
//             url: url,
//             title: liveTrackTitle ?? "Live Stream"
//         )
//         setupPlayer(item: liveItem, onEnd: nil)
//     }
    
//     func advance() {
//         guard !playlist.isEmpty else { return }
//         currentIndex = (currentIndex + 1) % playlist.count
//         playCurrent()
//     }
    
//     private func setupPlayer(item: RadioContent, onEnd: (() -> Void)?, resumeTime: Double? = nil) {
//         if let obs = endObserver {
//             NotificationCenter.default.removeObserver(obs)
//         }
//         if let timeObs = timeObserver {
//             player?.removeTimeObserver(timeObs)
//             timeObserver = nil
//         }
        
//         player?.pause()
//         player = nil
//         currentTime = 0
//         duration = 0
//         isBuffering = true
        
//         guard let url = URL(string: item.url) else {
//             isBuffering = false
//             return
//         }
        
//         if item.type == "youtube" || item.type == "twitch" {
//             isBuffering = false
//             return
//         }
        
//         player = AVPlayer(url: url)
        
//         if item.type == "video" {
//             player?.currentItem?.videoComposition = AVVideoComposition(propertiesOf: player!.currentItem!.asset)
//         }
        
//         player?.currentItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
//         player?.currentItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
        
//         if let finish = onEnd {
//             endObserver = NotificationCenter.default.addObserver(
//                 forName: .AVPlayerItemDidPlayToEndTime,
//                 object: player?.currentItem,
//                 queue: .main) { _ in finish() }
//         }
        
//         let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
//         timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
//             guard let self = self else { return }
//             self.currentTime = time.seconds
//             if let duration = self.player?.currentItem?.duration, !duration.isIndefinite {
//                 self.duration = duration.seconds
//             }
//         }
        
//         if let t = resumeTime, t > 0 {
//             player?.seek(to: CMTime(seconds: t, preferredTimescale: 600))
//         }
//         player?.play()
//         isPlaying = true
//     }
    
//     override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//         if keyPath == "playbackBufferEmpty" {
//             isBuffering = true
//         } else if keyPath == "playbackLikelyToKeepUp" {
//             isBuffering = false
//         }
//     }
    
//     func formatTime(_ seconds: Double) -> String {
//         if seconds.isNaN || seconds.isInfinite { return "--:--" }
//         let mins = Int(seconds) / 60
//         let secs = Int(seconds) % 60
//         return String(format: "%d:%02d", mins, secs)
//     }
// }

// // MARK: - Mock ViewModel
// class MockRadioViewModel: ObservableObject, RadioViewModelProtocol {
//     @Published var playlist: [RadioContent] = [
//         RadioContent(id: "1", type: "audio", url: "", title: "Midnight Dreams", artist: "DJ Shon", order: 0),
//         RadioContent(id: "2", type: "audio", url: "", title: "House Classics", artist: "Various Artists", order: 1),
//         RadioContent(id: "3", type: "video", url: "", title: "Live Session", artist: "Guest DJ", order: 2)
//     ]
//     @Published var currentIndex: Int = 0
//     @Published var isLive: Bool = false
//     @Published var isLoading = false
//     @Published var errorMessage: String? = nil
//     @Published var currentTime: Double = 45.5
//     @Published var duration: Double = 180.0
//     @Published var liveTrackTitle: String? = "Live Broadcast"
//     @Published var listenerCount: Int = 42
//     @Published var nextUpTitle: String = "House Classics"
//     @Published var isBuffering: Bool = false
//     @Published var currentLiveType: String = "icecast"
//     @Published var player: AVPlayer? = nil
//     @Published var isPlaying: Bool = true
    
//     func formatTime(_ seconds: Double) -> String {
//         if seconds.isNaN || seconds.isInfinite { return "--:--" }
//         let mins = Int(seconds) / 60
//         let secs = Int(seconds) % 60
//         return String(format: "%d:%02d", mins, secs)
//     }
// }

// // MARK: - Main Radio View
// struct RadioView<VM: RadioViewModelProtocol>: View {
//     @StateObject var vm: VM
//     @State private var showingInfo = false
//     @Namespace private var animation
    
//     var body: some View {
//         ZStack {
//             // Dreamy gradient background
//             DreamyBackground()
            
//             VStack(spacing: 0) {
//                 // Custom Navigation Bar
//                 RadioNavBar(showingInfo: $showingInfo)
//                     .padding(.horizontal)
//                     .padding(.top, 8)
                
//                 // Main Content
//                 ScrollView(.vertical, showsIndicators: false) {
//                     VStack(spacing: 24) {
//                         // Scrolling Ticker
//                         ScrollingTicker(vm: vm)
//                             .padding(.top, 8)
                        
//                         // Live Indicator
//                         if vm.isLive {
//                             LiveIndicator(listenerCount: vm.listenerCount)
//                                 .padding(.top, 8)
//                                 .transition(.scale.combined(with: .opacity))
//                         }
                        
//                         // Main Player
//                         DreamyPlayerCard(vm: vm, namespace: animation)
//                             .padding(.horizontal)
                        
//                         // Now Playing Info
//                         NowPlayingInfo(vm: vm)
//                             .padding(.horizontal)
                        
//                         // Up Next Section
//                         if !vm.isLive && !vm.nextUpTitle.isEmpty {
//                             UpNextCard(title: vm.nextUpTitle)
//                                 .padding(.horizontal)
//                                 .transition(.move(edge: .bottom).combined(with: .opacity))
//                         }
//                     }
//                     .padding(.bottom, 32)
//                 }
//             }
            
//             // Loading Overlay
//             if vm.isLoading {
//                 LoadingOverlay()
//             }
//         }
//         .preferredColorScheme(.dark)
//     }
// }

// // Extension for default init
// extension RadioView where VM == RadioViewModel {
//     init() {
//         self.init(vm: RadioViewModel())
//     }
// }

// // MARK: - Dreamy Background 
// struct DreamyBackground: View {
//     @State private var animateGradient = false
    
//     var body: some View {
//         ZStack {
//             // Base gradient
//             LinearGradient(
//                 colors: [
//                     Color.deepTeal,
//                     Color.deepTeal.opacity(0.8),
//                     Color.charcoal
//                 ],
//                 startPoint: .topLeading,
//                 endPoint: .bottomTrailing
//             )
            
//             // Animated overlay
//             LinearGradient(
//                 colors: [
//                     Color.skyTeal.opacity(0.3),
//                     Color.peachGold.opacity(0.2),
//                     Color.clear
//                 ],
//                 startPoint: animateGradient ? .topLeading : .bottomTrailing,
//                 endPoint: animateGradient ? .bottomTrailing : .topLeading
//             )
//             .animation(
//                 Animation.easeInOut(duration: 8)
//                     .repeatForever(autoreverses: true),
//                 value: animateGradient
//             )
            
//             // Noise texture overlay
//             NoiseOverlay()
//         }
//         .ignoresSafeArea()
//         .onAppear {
//             animateGradient = true
//         }
//     }
// }

// // MARK: - Noise Overlay
// struct NoiseOverlay: View {
//     var body: some View {
//         GeometryReader { geometry in
//             Canvas { context, size in
//                 for _ in 0..<500 {
//                     let x = CGFloat.random(in: 0...size.width)
//                     let y = CGFloat.random(in: 0...size.height)
//                     let opacity = Double.random(in: 0.02...0.08)
                    
//                     context.fill(
//                         Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
//                         with: .color(.white.opacity(opacity))
//                     )
//                 }
//             }
//         }
//         .allowsHitTesting(false)
//     }
// }

// // MARK: - Scrolling Ticker
// struct ScrollingTicker<VM: RadioViewModelProtocol>: View {
//     @ObservedObject var vm: VM
//     @State private var scrollOffset: CGFloat = 0
//     @State private var textSize: CGSize = .zero
//     @State private var tickerMessages: [String] = []
//     @State private var db = Firestore.firestore()
//     @State private var tickerListener: ListenerRegistration?
    
//     // Fallback messages if no Firestore messages
//     let fallbackMessages = [
//         "🎵 Welcome to DreamHouse Radio - Your 24/7 Vibe Station 🎵",
//         "✨ Curated beats for your soul ✨",
//         "🌙 Late night sessions & early morning grooves 🌙",
//         "💫 Follow @shondon11 for live DJ sets 💫",
//         "🎧 Best experienced with good headphones 🎧"
//     ]
    
//     @State private var currentMessageIndex = 0
    
//     var tickerText: String {
//         let messages = tickerMessages.isEmpty ? fallbackMessages : tickerMessages
//         let currentMessage = messages.isEmpty ? "" : messages[currentMessageIndex % messages.count]
//         
//         if vm.isLive {
//             return "🔴 LIVE NOW: \(vm.liveTrackTitle ?? "Live Broadcast") • Listeners: \(vm.listenerCount) • \(currentMessage) • "
//         } else if !vm.playlist.isEmpty {
//             let current = vm.playlist[vm.currentIndex].title
//             let upNext = vm.nextUpTitle.isEmpty ? "End of playlist" : vm.nextUpTitle
//             return "🎵 Now Playing: \(current) • Up Next: \(upNext) • \(currentMessage) • "
//         } else {
//             return currentMessage + " • "
//         }
//     }
    
//     var body: some View {
//         GeometryReader { geometry in
//             ZStack {
//                 // Background
//                 Rectangle()
//                     .fill(
//                         LinearGradient(
//                             colors: [
//                                 Color.charcoal.opacity(0.8),
//                                 Color.deepTeal.opacity(0.6)
//                             ],
//                             startPoint: .leading,
//                             endPoint: .trailing
//                         )
//                     )
//                     .overlay(
//                         Rectangle()
//                             .stroke(Color.skyTeal.opacity(0.3), lineWidth: 1)
//                     )
                
//                 // Scrolling text
//                 HStack(spacing: 0) {
//                     Text(tickerText)
//                         .font(.system(size: 14, weight: .medium, design: .monospaced))
//                         .foregroundColor(.peachGold)
//                         .fixedSize()
//                         .background(
//                             GeometryReader { textGeometry in
//                                 Color.clear.onAppear {
//                                     textSize = textGeometry.size
//                                 }
//                             }
//                         )
                    
//                     Text(tickerText)
//                         .font(.system(size: 14, weight: .medium, design: .monospaced))
//                         .foregroundColor(.peachGold)
//                         .fixedSize()
//                 }
//                 .offset(x: scrollOffset)
//             }
//             .clipped()
//             .onAppear {
//                 startScrolling()
//                 startMessageRotation()
//                 subscribeToTickerMessages()
//             }
//             .onChange(of: vm.currentIndex) { _ in
//                 resetScrolling()
//             }
//             .onChange(of: vm.isLive) { _ in
//                 resetScrolling()
//             }
//             .onDisappear {
//                 tickerListener?.remove()
//             }
//         }
//         .frame(height: 32)
//         .shadow(color: Color.black.opacity(0.3), radius: 4, y: 2)
//     }
    
//     private func startScrolling() {
//         scrollOffset = 0
        
//         // ESPN-style continuous scrolling - faster and smoother
//         withAnimation(
//             Animation.linear(duration: Double(textSize.width) / 50)
//                 .repeatForever(autoreverses: false)
//         ) {
//             scrollOffset = -textSize.width
//         }
//     }
    
//     private func resetScrolling() {
//         scrollOffset = 0
//         DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//             startScrolling()
//         }
//     }
    
//     private func startMessageRotation() {
//         Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { _ in
//             if !vm.isLive {
//                 let messages = tickerMessages.isEmpty ? fallbackMessages : tickerMessages
//                 withAnimation {
//                     currentMessageIndex = (currentMessageIndex + 1) % messages.count
//                 }
//             }
//         }
//     }
//     
//     private func subscribeToTickerMessages() {
//         tickerListener = db.collection("tickerMessages")
//             .whereField("isActive", isEqualTo: true)
//             .order(by: "priority", descending: true)
//             .order(by: "createdAt", descending: true)
//             .addSnapshotListener { snapshot, error in
//                 if let docs = snapshot?.documents {
//                     let messages = docs.compactMap { doc -> String? in
//                         let data = doc.data()
//                         let message = data["message"] as? String ?? ""
//                         let isActive = data["isActive"] as? Bool ?? true
//                         let expiresAt = data["expiresAt"] as? Timestamp
//                         
//                         // Check if message is expired
//                         if let expiresAt = expiresAt {
//                             if expiresAt.dateValue() <= Date() {
//                                 return nil
//                             }
//                         }
//                         
//                         return isActive ? message : nil
//                     }
//                     
//                     DispatchQueue.main.async {
//                         self.tickerMessages = messages
//                         if !messages.isEmpty && self.currentMessageIndex >= messages.count {
//                             self.currentMessageIndex = 0
//                         }
//                     }
//                 }
//             }
//     }
// }

// // MARK: - Navigation Bar (Title)
// struct RadioNavBar: View {
//     @Binding var showingInfo: Bool
    
//     var body: some View {
//         HStack {
//             Text("DREAMHOUSE")
//                 .font(.system(size: 28, weight: .heavy, design: .rounded))
//                 .foregroundColor(.white)
            
//             Text("RADIO")
//                 .font(.system(size: 28, weight: .thin, design: .rounded))
//                 .foregroundColor(.skyTeal)
            
//             Spacer()
            
//             Button(action: { showingInfo.toggle() }) {
//                 Image(systemName: "info.circle.fill")
//                     .font(.system(size: 24))
//                     .foregroundColor(.white.opacity(0.8))
//             }
//         }
//         .padding(.vertical, 12)
//     }
// }

// // MARK: - Live Indicator
// struct LiveIndicator: View {
//     let listenerCount: Int
//     @State private var pulse = false
    
//     var body: some View {
//         HStack(spacing: 12) {
//             // Pulsing dot
//             Circle()
//                 .fill(Color.red)
//                 .frame(width: 12, height: 12)
//                 .overlay(
//                     Circle()
//                         .stroke(Color.red, lineWidth: 2)
//                         .scaleEffect(pulse ? 2.5 : 1)
//                         .opacity(pulse ? 0 : 1)
//                 )
//                 .animation(
//                     Animation.easeOut(duration: 1.5)
//                         .repeatForever(autoreverses: false),
//                     value: pulse
//                 )
            
//             Text("LIVE")
//                 .font(.system(size: 16, weight: .bold, design: .rounded))
//                 .foregroundColor(.white)
            
//             if listenerCount > 0 {
//                 Text("•")
//                     .foregroundColor(.white.opacity(0.5))
                
//                 HStack(spacing: 4) {
//                     Image(systemName: "person.2.fill")
//                         .font(.system(size: 14))
//                     Text("\(listenerCount)")
//                         .font(.system(size: 14, weight: .medium, design: .rounded))
//                 }
//                 .foregroundColor(.skyTeal)
//             }
//         }
//         .padding(.horizontal, 20)
//         .padding(.vertical, 10)
//         .background(
//             Capsule()
//                 .fill(Color.red.opacity(0.2))
//                 .background(
//                     Capsule()
//                         .stroke(Color.red.opacity(0.3), lineWidth: 1)
//                 )
//         )
//         .onAppear {
//             pulse = true
//         }
//     }
// }

// // MARK: - Dreamy Player Card
// struct DreamyPlayerCard<VM: RadioViewModelProtocol>: View {
//     @ObservedObject var vm: VM
//     let namespace: Namespace.ID
//     @State private var showWaveform = false
    
//     var body: some View {
//         VStack(spacing: 0) {
//             // Media Display
//             ZStack {
//                 // Background
//                 RoundedRectangle(cornerRadius: 24)
//                     .fill(Color.charcoal.opacity(0.3))
//                     .overlay(
//                         RoundedRectangle(cornerRadius: 24)
//                             .stroke(Color.white.opacity(0.1), lineWidth: 1)
//                     )
                
//                 // Content
//                 Group {
//                     if !vm.playlist.isEmpty {
//                         if vm.isLive {
//                             switch vm.currentLiveType {
//                             case "youtube":
//                                 if let currentItem = vm.playlist[safe: vm.currentIndex] {
//                                     OptimizedYouTubeView(url: currentItem.url)
//                                         .clipShape(RoundedRectangle(cornerRadius: 20))
//                                         .padding(4)
//                                 }
//                             case "twitch":
//                                 if let currentItem = vm.playlist[safe: vm.currentIndex] {
//                                     OptimizedTwitchView(url: currentItem.url)
//                                         .clipShape(RoundedRectangle(cornerRadius: 20))
//                                         .padding(4)
//                                 }
//                             default:
//                                 DreamyAudioVisualizer()
//                                     .padding(4)
//                             }
//                         } else {
//                             let item = vm.playlist[vm.currentIndex]
//                             switch item.type {
//                             case "audio":
//                                 DreamyAudioVisualizer()
//                                     .padding(4)
//                             case "video":
//                                 if let player = vm.player {
//                                     OptimizedVideoPlayer(player: player)
//                                         .clipShape(RoundedRectangle(cornerRadius: 20))
//                                         .padding(4)
//                                 }
//                             case "youtube":
//                                 OptimizedYouTubeView(url: item.url)
//                                     .clipShape(RoundedRectangle(cornerRadius: 20))
//                                     .padding(4)
//                             default:
//                                 DreamyAudioVisualizer()
//                                     .padding(4)
//                             }
//                         }
//                     } else {
//                         EmptyStateView()
//                     }
//                 }
//                 .frame(height: 280)
                
//                 // Buffering Overlay
//                 if vm.isBuffering {
//                     BufferingOverlay()
//                 }
//             }
//             .frame(height: 280)
//             .shadow(color: Color.black.opacity(0.3), radius: 20, y: 10)
            
//             // Progress Bar (for non-live content)
//             if !vm.isLive && vm.duration > 0 {
//                 DreamyProgressBar(
//                     currentTime: vm.currentTime,
//                     duration: vm.duration,
//                     formatTime: vm.formatTime
//                 )
//                 .padding(.horizontal, 24)
//                 .padding(.top, 20)
//             }
//         }
//         .animation(.easeInOut(duration: 0.3), value: vm.isLive)
//     }
// }

// // MARK: - Dreamy Audio Visualizer
// struct DreamyAudioVisualizer: View {
//     @State private var amplitudes: [CGFloat] = Array(repeating: 0.3, count: 40)
//     @State private var phase: CGFloat = 0
//     let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
//     var body: some View {
//         GeometryReader { geometry in
//             ZStack {
//                 // Background gradient
//                 LinearGradient(
//                     colors: [
//                         Color.deepTeal.opacity(0.3),
//                         Color.skyTeal.opacity(0.1)
//                     ],
//                     startPoint: .top,
//                     endPoint: .bottom
//                 )
                
//                 // Waveform
//                 Canvas { context, size in
//                     let width = size.width
//                     let height = size.height
//                     let barWidth = width / CGFloat(amplitudes.count)
//                     let centerY = height / 2
                    
//                     for (index, amplitude) in amplitudes.enumerated() {
//                         let x = CGFloat(index) * barWidth
//                         let barHeight = amplitude * height * 0.8
                        
//                         // Create gradient for each bar
//                         let gradient = Gradient(colors: [
//                             Color.skyTeal,
//                             Color.peachGold.opacity(0.8)
//                         ])
                        
//                         // Top bar
//                         let topRect = CGRect(
//                             x: x + barWidth * 0.2,
//                             y: centerY - barHeight / 2,
//                             width: barWidth * 0.6,
//                             height: barHeight / 2
//                         )
                        
//                         // Bottom bar (mirror)
//                         let bottomRect = CGRect(
//                             x: x + barWidth * 0.2,
//                             y: centerY,
//                             width: barWidth * 0.6,
//                             height: barHeight / 2
//                         )
                        
//                         context.fill(
//                             RoundedRectangle(cornerRadius: barWidth * 0.3).path(in: topRect),
//                             with: .linearGradient(gradient, startPoint: CGPoint(x: 0.5, y: 0.0), endPoint: CGPoint(x: 0.5, y: 1.0))
//                         )
                        
//                         context.fill(
//                             RoundedRectangle(cornerRadius: barWidth * 0.3).path(in: bottomRect),
//                             with: .linearGradient(gradient, startPoint: CGPoint(x: 0.5, y: 0.0), endPoint: CGPoint(x: 0.5, y: 1.0))
//                         )
//                     }
//                 }
                
//                 // Center orb
//                 Circle()
//                     .fill(
//                         RadialGradient(
//                             colors: [
//                                 Color.peachGold.opacity(0.8),
//                                 Color.peachGold.opacity(0.3),
//                                 Color.clear
//                             ],
//                             center: .center,
//                             startRadius: 5,
//                             endRadius: 50
//                         )
//                     )
//                     .frame(width: 100, height: 100)
//                     .blur(radius: 20)
//                     .scaleEffect(1 + sin(phase) * 0.1)
//             }
//             .clipShape(RoundedRectangle(cornerRadius: 20))
//         }
//         .onReceive(timer) { _ in
//             withAnimation(.easeInOut(duration: 0.05)) {
//                 // Update amplitudes with smooth wave
//                 for i in 0..<amplitudes.count {
//                     let wavePosition = sin(phase + CGFloat(i) * 0.2) * 0.3
//                     let randomVariation = CGFloat.random(in: -0.1...0.1)
//                     amplitudes[i] = 0.3 + wavePosition + randomVariation
//                     amplitudes[i] = max(0.1, min(0.9, amplitudes[i]))
//                 }
//                 phase += 0.1
//             }
//         }
//     }
// }

// // MARK: - Optimized Video Player
// struct OptimizedVideoPlayer: View {
//     let player: AVPlayer
    
//     var body: some View {
//         VideoPlayer(player: player)
//             .disabled(true) // Prevent user interaction
//             .onAppear {
//                 player.play()
//             }
//     }
// }

// // MARK: - Optimized YouTube View
// struct OptimizedYouTubeView: UIViewRepresentable {
//     let url: String
    
//     func makeUIView(context: Context) -> WKWebView {
//         let config = WKWebViewConfiguration()
//         config.allowsInlineMediaPlayback = true
//         config.mediaTypesRequiringUserActionForPlayback = []
//         config.allowsPictureInPictureMediaPlayback = false
        
//         let webView = WKWebView(frame: .zero, configuration: config)
//         webView.scrollView.isScrollEnabled = false
//         webView.isUserInteractionEnabled = false
//         webView.backgroundColor = .clear
//         webView.isOpaque = false
        
//         return webView
//     }
    
//     func updateUIView(_ uiView: WKWebView, context: Context) {
//         #if DEBUG
//         if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
//             return
//         }
//         #endif
        
//         let embedURL = convertToEmbedURL(url)
//         if let u = URL(string: embedURL) {
//             let request = URLRequest(url: u)
//             uiView.load(request)
//         }
//     }
    
//     private func convertToEmbedURL(_ urlString: String) -> String {
//         var videoID = ""
//         if urlString.contains("youtube.com/watch?v=") {
//             videoID = urlString.components(separatedBy: "v=")[1].components(separatedBy: "&")[0]
//         } else if urlString.contains("youtu.be/") {
//             videoID = urlString.components(separatedBy: "youtu.be/")[1].components(separatedBy: "?")[0]
//         } else if urlString.contains("youtube.com/embed/") {
//             return urlString
//         }
        
//         return "https://www.youtube.com/embed/\(videoID)?autoplay=1&controls=0&modestbranding=1&playsinline=1&rel=0&showinfo=0&loop=1&playlist=\(videoID)"
//     }
// }

// // MARK: - Optimized Twitch View
// struct OptimizedTwitchView: UIViewRepresentable {
//     let url: String
    
//     func makeUIView(context: Context) -> WKWebView {
//         let config = WKWebViewConfiguration()
//         config.allowsInlineMediaPlayback = true
//         config.mediaTypesRequiringUserActionForPlayback = []
//         config.allowsPictureInPictureMediaPlayback = false
        
//         let webView = WKWebView(frame: .zero, configuration: config)
//         webView.scrollView.isScrollEnabled = false
//         webView.isUserInteractionEnabled = false
//         webView.backgroundColor = .clear
//         webView.isOpaque = false
        
//         return webView
//     }
    
//     func updateUIView(_ uiView: WKWebView, context: Context) {
//         #if DEBUG
//         if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
//             return
//         }
//         #endif
        
//         let channelName = extractTwitchChannel(from: url)
//         let embedHTML = """
// <!DOCTYPE html>
// <html>
// <head>
//     <meta name="viewport" content="width=device-width, initial-scale=1.0">
//     <style>
//         body { 
//             margin: 0; 
//             padding: 0; 
//             background: transparent; 
//             overflow: hidden;
//         }
//         .video-container { 
//             position: relative; 
//             padding-bottom: 56.25%; 
//             height: 0; 
//             overflow: hidden; 
//         }
//         .video-container iframe { 
//             position: absolute; 
//             top: 0; 
//             left: 0; 
//             width: 100%; 
//             height: 100%; 
//             border: none;
//         }
//     </style>
// </head>
// <body>
//     <div class="video-container">
//         <iframe
//             src="https://player.twitch.tv/?channel=\(channelName)&parent=localhost&autoplay=true&muted=false&controls=false"
//             frameborder="0"
//             allowfullscreen="false"
//             scrolling="no"
//             allow="autoplay; fullscreen">
//         </iframe>
//     </div>
// </body>
// </html>
// """
//         uiView.loadHTMLString(embedHTML, baseURL: nil)
//     }
    
//     private func extractTwitchChannel(from url: String) -> String {
//         return url.replacingOccurrences(of: "https://www.twitch.tv/", with: "")
//             .replacingOccurrences(of: "https://twitch.tv/", with: "")
//             .components(separatedBy: "/").first ?? ""
//     }
// }

// // MARK: - Dreamy Progress Bar
// struct DreamyProgressBar: View {
//     let currentTime: Double
//     let duration: Double
//     let formatTime: (Double) -> String
    
//     var body: some View {
//         VStack(spacing: 8) {
//             // Progress bar
//             GeometryReader { geometry in
//                 ZStack(alignment: .leading) {
//                     // Background track
//                     RoundedRectangle(cornerRadius: 4)
//                         .fill(Color.white.opacity(0.1))
//                         .frame(height: 8)
                    
//                     // Progress fill
//                     RoundedRectangle(cornerRadius: 4)
//                         .fill(
//                             LinearGradient(
//                                 colors: [Color.skyTeal, Color.peachGold],
//                                 startPoint: .leading,
//                                 endPoint: .trailing
//                             )
//                         )
//                         .frame(width: geometry.size.width * CGFloat(currentTime / duration), height: 8)
//                         .animation(.linear(duration: 0.1), value: currentTime)
                    
//                     // Glow effect
//                     RoundedRectangle(cornerRadius: 4)
//                         .fill(
//                             LinearGradient(
//                                 colors: [Color.skyTeal, Color.peachGold],
//                                 startPoint: .leading,
//                                 endPoint: .trailing
//                             )
//                         )
//                         .frame(width: geometry.size.width * CGFloat(currentTime / duration), height: 8)
//                         .blur(radius: 8)
//                         .opacity(0.5)
//                 }
//             }
//             .frame(height: 8)
            
//             // Time labels
//             HStack {
//                 Text(formatTime(currentTime))
//                     .font(.system(size: 12, weight: .medium, design: .monospaced))
//                     .foregroundColor(.white.opacity(0.7))
                
//                 Spacer()
                
//                 Text(formatTime(duration))
//                     .font(.system(size: 12, weight: .medium, design: .monospaced))
//                     .foregroundColor(.white.opacity(0.7))
//             }
//         }
//     }
// }

// // MARK: - Now Playing Info
// struct NowPlayingInfo<VM: RadioViewModelProtocol>: View {
//     @ObservedObject var vm: VM
//     @State private var textOffset: CGFloat = 0
//     @State private var needsScrolling = false
    
//     var body: some View {
//         VStack(spacing: 12) {
//             // Title with scrolling effect
//             GeometryReader { geometry in
//                 HStack(spacing: 50) {
//                     Text(currentTitle)
//                         .font(.system(size: 28, weight: .bold, design: .rounded))
//                         .foregroundColor(.white)
//                         .lineLimit(1)
//                         .fixedSize()
//                         .offset(x: needsScrolling ? textOffset : 0)
                    
//                     if needsScrolling {
//                         Text(currentTitle)
//                             .font(.system(size: 28, weight: .bold, design: .rounded))
//                             .foregroundColor(.white)
//                             .lineLimit(1)
//                             .fixedSize()
//                             .offset(x: needsScrolling ? textOffset : 0)
//                     }
//                 }
//                 .onAppear {
//                     checkScrollingNeeded(geometry: geometry)
//                 }
//                 .onChange(of: vm.currentIndex) { _ in
//                     checkScrollingNeeded(geometry: geometry)
//                 }
//             }
//             .frame(height: 35)
//             .clipped()
            
//             // Artist/Type info
//             if let artist = currentArtist {
//                 Text(artist)
//                     .font(.system(size: 18, weight: .medium, design: .rounded))
//                     .foregroundColor(.skyTeal)
//             } else if vm.isLive {
//                 HStack(spacing: 8) {
//                     Image(systemName: "antenna.radiowaves.left.and.right")
//                         .font(.system(size: 16))
//                     Text("Live Broadcast")
//                         .font(.system(size: 18, weight: .medium, design: .rounded))
//                 }
//                 .foregroundColor(.peachGold)
//             }
//         }
//         .padding(.vertical, 16)
//         .padding(.horizontal, 24)
//         .background(
//             RoundedRectangle(cornerRadius: 20)
//                 .fill(Color.charcoal.opacity(0.3))
//                 .overlay(
//                     RoundedRectangle(cornerRadius: 20)
//                         .stroke(Color.white.opacity(0.1), lineWidth: 1)
//                 )
//         )
//     }
    
//     private var currentTitle: String {
//         if vm.isLive {
//             return vm.liveTrackTitle ?? "Live Stream"
//         } else if !vm.playlist.isEmpty {
//             return vm.playlist[vm.currentIndex].title
//         }
//         return "No Track"
//     }
    
//     private var currentArtist: String? {
//         if !vm.isLive && !vm.playlist.isEmpty {
//             return vm.playlist[vm.currentIndex].artist
//         }
//         return nil
//     }
    
//     private func checkScrollingNeeded(geometry: GeometryProxy) {
//         let textWidth = currentTitle.size(
//             withAttributes: [.font: UIFont.systemFont(ofSize: 28, weight: .bold)]
//         ).width
        
//         needsScrolling = textWidth > geometry.size.width
        
//         if needsScrolling {
//             textOffset = 0
//             withAnimation(
//                 Animation.linear(duration: Double(textWidth / 30))
//                     .repeatForever(autoreverses: false)
//             ) {
//                 textOffset = -(textWidth + 50)
//             }
//         }
//     }
// }

// // MARK: - Up Next Card
// struct UpNextCard: View {
//     let title: String
//     @State private var isVisible = false
    
//     var body: some View {
//         HStack(spacing: 16) {
//             Image(systemName: "music.note.list")
//                 .font(.system(size: 20))
//                 .foregroundColor(.peachGold)
            
//             VStack(alignment: .leading, spacing: 4) {
//                 Text("UP NEXT")
//                     .font(.system(size: 12, weight: .semibold, design: .rounded))
//                     .foregroundColor(.white.opacity(0.6))
                
//                 Text(title)
//                     .font(.system(size: 16, weight: .medium, design: .rounded))
//                     .foregroundColor(.white)
//                     .lineLimit(1)
//             }
            
//             Spacer()
//         }
//         .padding(20)
//         .background(
//             RoundedRectangle(cornerRadius: 16)
//                 .fill(
//                     LinearGradient(
//                         colors: [
//                             Color.peachGold.opacity(0.15),
//                             Color.peachGold.opacity(0.05)
//                         ],
//                         startPoint: .leading,
//                         endPoint: .trailing
//                     )
//                 )
//                 .overlay(
//                     RoundedRectangle(cornerRadius: 16)
//                         .stroke(Color.peachGold.opacity(0.3), lineWidth: 1)
//                 )
//         )
//         .scaleEffect(isVisible ? 1 : 0.9)
//         .opacity(isVisible ? 1 : 0)
//         .onAppear {
//             withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
//                 isVisible = true
//             }
//         }
//     }
// }

// // MARK: - Buffering Overlay
// struct BufferingOverlay: View {
//     @State private var isAnimating = false
    
//     var body: some View {
//         ZStack {
//             Color.black.opacity(0.5)
            
//             VStack(spacing: 16) {
//                 ProgressView()
//                     .progressViewStyle(CircularProgressViewStyle(tint: .skyTeal))
//                     .scaleEffect(1.5)
                
//                 Text("Buffering...")
//                     .font(.system(size: 14, weight: .medium, design: .rounded))
//                     .foregroundColor(.white)
//             }
//             .padding(24)
//             .background(
//                 RoundedRectangle(cornerRadius: 16)
//                     .fill(Color.charcoal.opacity(0.9))
//             )
//         }
//         .clipShape(RoundedRectangle(cornerRadius: 20))
//     }
// }

// // MARK: - Loading Overlay
// struct LoadingOverlay: View {
//     @State private var rotation: Double = 0
    
//     var body: some View {
//         ZStack {
//             Color.black.opacity(0.7)
//                 .ignoresSafeArea()
            
//             VStack(spacing: 24) {
//                 ZStack {
//                     Circle()
//                         .stroke(
//                             LinearGradient(
//                                 colors: [
//                                     Color.skyTeal,
//                                     Color.peachGold,
//                                     Color.skyTeal
//                                 ],
//                                 startPoint: .top,
//                                 endPoint: .bottom
//                             ),
//                             lineWidth: 4
//                         )
//                         .frame(width: 60, height: 60)
//                         .rotationEffect(.degrees(rotation))
                    
//                     Image(systemName: "music.note")
//                         .font(.system(size: 24))
//                         .foregroundColor(.white)
//                 }
                
//                 Text("Loading your vibe...")
//                     .font(.system(size: 16, weight: .medium, design: .rounded))
//                     .foregroundColor(.white.opacity(0.8))
//             }
//             .onAppear {
//                 withAnimation(
//                     Animation.linear(duration: 1)
//                         .repeatForever(autoreverses: false)
//                 ) {
//                     rotation = 360
//                 }
//             }
//         }
//     }
// }

// // MARK: - Empty State View
// struct EmptyStateView: View {
//     var body: some View {
//         VStack(spacing: 16) {
//             Image(systemName: "music.quarternote.3")
//                 .font(.system(size: 48))
//                 .foregroundColor(.white.opacity(0.3))
            
//             Text("No tracks available")
//                 .font(.system(size: 18, weight: .medium, design: .rounded))
//                 .foregroundColor(.white.opacity(0.5))
//         }
//         .frame(maxWidth: .infinity, maxHeight: .infinity)
//     }
// }

// // MARK: - Safe Array Extension
// extension Array {
//     subscript(safe index: Int) -> Element? {
//         return indices.contains(index) ? self[index] : nil
//     }
// }

// // MARK: - String Extension for Size
// extension String {
//     func size(withAttributes attributes: [NSAttributedString.Key: Any]) -> CGSize {
//         let nsString = self as NSString
//         return nsString.size(withAttributes: attributes)
//     }
// }

// // MARK: - Preview
// #Preview {
//     RadioView(vm: MockRadioViewModel())
// }
