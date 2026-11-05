// File Name: CallHistoryView.swift

import SwiftUI
import AVFoundation
import Foundation
import Combine

// MARK: - Call Log Model
struct CallLog: Identifiable, Codable {
    let id: Int
    let userId: Int?
    let callerPhone: String
    let calledPhone: String
    let status: String
    let voicemailUrl: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case callerPhone = "caller_phone"
        case calledPhone = "called_phone"
        case status
        case voicemailUrl = "voicemail_url"
        case createdAt = "created_at"
    }
}

// MARK: - View Model Service
class TrustedContactService: ObservableObject {
    @Published var callLogs: [CallLog] = []
    @Published var isLoading: Bool = false

    func fetchCallLogs(userId: Int) {
        isLoading = true
        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/call-logs/\(userId)") else {
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false
                guard let data = data, error == nil else { return }
                
                let decoder = JSONDecoder()
                if let decodedLogs = try? decoder.decode([CallLog].self, from: data) {
                    self.callLogs = decodedLogs
                }
            }
        }.resume()
    }
}

// MARK: - Call History View
struct CallHistoryView: View {
    @ObservedObject private var service = TrustedContactService()
    let currentUserId: Int = 1
    @Environment(\.dismiss) private var dismiss
    
    // State for managing in-app audio playback
    @State private var audioPlayer: AVPlayer?
    @State private var playingUrlString: String?

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    if service.isLoading && service.callLogs.isEmpty {
                        ProgressView()
                            .padding(.top, 40)
                    } else if service.callLogs.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "phone.bubble.left")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("No call activity logged yet.")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 60)
                    } else {
                        ForEach(service.callLogs) { log in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(log.callerPhone)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.primary)
                                     
                                    Spacer()
                                     
                                    StatusBadge(status: log.status)
                                }
                                 
                                Text("Called: \(log.calledPhone)")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.secondary)

                                // In-App Voicemail Audio Player Button
                                if let urlString = log.voicemailUrl, let url = URL(string: urlString) {
                                    Button(action: {
                                        togglePlayback(for: urlString, url: url)
                                    }) {
                                        HStack(spacing: 10) {
                                            Image(systemName: playingUrlString == urlString ? "stop.circle.fill" : "play.circle.fill")
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundColor(.green)
                                             
                                            Text(playingUrlString == urlString ? "Stop Voicemail" : "Play Voicemail")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.primary)
                                             
                                            Spacer()
                                        }
                                        .padding(12)
                                        .background(Color(.systemGroupedBackground).opacity(0.8))
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(.plain)
                                }
                                 
                                Text(log.createdAt)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .padding(18)
                            .background(Color(.systemBackground))
                            .cornerRadius(18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color(.systemGray4).opacity(0.6), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Call History")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .bold))
                        Text("Back")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .tertiarySystemFill))
                    .cornerRadius(20)
                }
            }
        }
        .refreshable {
            service.fetchCallLogs(userId: currentUserId)
        }
        .onAppear {
            service.fetchCallLogs(userId: currentUserId)
        }
        .onDisappear {
            audioPlayer?.pause()
        }
    }

    private func togglePlayback(for urlString: String, url: URL) {
        if playingUrlString == urlString {
            audioPlayer?.pause()
            playingUrlString = nil
        } else {
            audioPlayer?.pause()
            let playerItem = AVPlayerItem(url: url)
            audioPlayer = AVPlayer(playerItem: playerItem)
            audioPlayer?.play()
            playingUrlString = urlString
        }
    }
}

// MARK: - Status Badge Component
struct StatusBadge: View {
    let status: String

    var body: some View {
        Text(formattedStatus)
            .font(.system(size: 13, weight: .bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(badgeColor.opacity(0.15))
            .foregroundColor(badgeColor)
            .cornerRadius(8)
    }

    var formattedStatus: String {
        switch status {
        case "PASSED_PASSCODE": return "Passed"
        case "SENT_TO_VOICEMAIL": return "Voicemail"
        case "DIRECT_DIAL": return "Direct Dial"
        default: return status
        }
    }

    var badgeColor: Color {
        switch status {
        case "PASSED_PASSCODE": return .green
        case "SENT_TO_VOICEMAIL": return .orange
        case "DIRECT_DIAL": return .blue
        default: return .gray
        }
    }
}
