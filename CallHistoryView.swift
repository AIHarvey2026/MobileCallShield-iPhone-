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

        URLSession.shared.dataTask(with: url) { data, response, error in
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
    
    // State for managing in-app audio playback
    @State private var audioPlayer: AVPlayer?
    @State private var playingUrlString: String?

    var body: some View {
        List {
            if service.isLoading && service.callLogs.isEmpty {
                ProgressView()
            } else if service.callLogs.isEmpty {
                Text("No call activity logged yet.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(service.callLogs) { log in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(log.callerPhone)
                                .font(.headline)
                            Spacer()
                            StatusBadge(status: log.status)
                        }
                       
                        Text("Called: \(log.calledPhone)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        // In-App Voicemail Audio Player
                        if let urlString = log.voicemailUrl, let url = URL(string: urlString) {
                            Button(action: {
                                togglePlayback(for: urlString, url: url)
                            }) {
                                HStack {
                                    Image(systemName: playingUrlString == urlString ? "stop.circle.fill" : "play.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.green)
                                    Text(playingUrlString == urlString ? "Stop Voicemail" : "Play Voicemail")
                                        .font(.caption)
                                        .bold()
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                       
                        Text(log.createdAt)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let log = service.callLogs[index]
                        deleteCallLog(logId: log.id)
                    }
                }
            }
        }
        .navigationTitle("Call History")
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

    private func deleteCallLog(logId: Int) {
        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/call-logs/\(logId)") else { return }
         
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        URLSession.shared.dataTask(with: request) { _, response, _ in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    service.callLogs.removeAll { $0.id == logId }
                }
            }
        }.resume()
    }
}

struct StatusBadge: View {
    let status: String

    var body: some View {
        Text(formattedStatus)
            .font(.caption2)
            .bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.15))
            .foregroundColor(badgeColor)
            .cornerRadius(6)
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
