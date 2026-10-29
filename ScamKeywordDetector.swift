import Foundation
import Speech
import AVFoundation

class ScamKeywordDetector {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private let scamKeywords = ["gift card", "social security", "wire transfer", "irs", "warrant", "bank account"]
    
    var onScamDetected: ((String) -> Void)?
    var onSecretWordVerified: (() -> Void)?
    
    func requestPermissionsAndStart(secretWord: String) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                if status == .authorized {
                    self.startListening(secretWord: secretWord.lowercased().trimmingCharacters(in: .whitespaces))
                }
            }
        }
    }
    
    private func startListening(secretWord: String) {
        audioEngine.stop()
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try? audioEngine.start()
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            guard let result = result else { return }
            let spokenText = result.bestTranscription.formattedString.lowercased()
            
            for keyword in self.scamKeywords {
                if spokenText.contains(keyword) {
                    self.onScamDetected?(keyword)
                }
            }
            
            if !secretWord.isEmpty && spokenText.contains(secretWord) {
                self.onSecretWordVerified?()
            }
        }
    }
    
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
    }
}
