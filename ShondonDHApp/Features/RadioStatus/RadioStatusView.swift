//
//  RadioStatusView.swift
//  ShondonDHApp
//

import SwiftUI

struct RadioStatusView: View {
    @State private var listenerCount = 0
    @State private var currentTrack = "Loading..."
    @State private var isLive = false
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "radio.fill")
                                .font(.title)
                                .foregroundColor(.blue)

                            VStack(alignment: .leading) {
                                Text("DreamHouse Radio")
                                    .font(.title2)
                                    .bold()
                                Text("24/7 Vibe Station")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if isLive {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                    Text("LIVE")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.red)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }

                        Divider()

                        VStack(spacing: 12) {
                            StatusRow(
                                icon: "antenna.radiowaves.left.and.right",
                                title: "Listeners",
                                value: "\(listenerCount)",
                                color: .green
                            )

                            StatusRow(
                                icon: "music.note",
                                title: "Current Track",
                                value: currentTrack,
                                color: .blue
                            )
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    if isLoading {
                        ProgressView("Loading status...")
                            .padding()
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Radio Status")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadRadioStatus()
            }
        }
    }

    private func loadRadioStatus() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            listenerCount = Int.random(in: 10...50)
            currentTrack = "DreamHouse Vibes"
            isLive = true
        }
    }
}

struct StatusRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .bold()
                .foregroundColor(color)
        }
    }
}
