import AVFoundation
import UIKit

@MainActor
final class TextToSpeechService: ObservableObject {
    static let shared = TextToSpeechService()

    @Published private(set) var isPlaying = false
    @Published private(set) var currentArticleID: String?

    private let synthesizer = AVSpeechSynthesizer()
    private var speechState: SpeechState = .idle

    enum SpeechState: Equatable {
        case idle
        case speaking(String)
        case paused(String)
    }

    var isSpeaking: Bool {
        if case .speaking = speechState { return true }
        return false
    }

    var isPaused: Bool {
        if case .paused = speechState { return true }
        return false
    }

    func speak(_ text: String, articleID: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        if isPlaying && currentArticleID == articleID {
            pause()
            return
        }

        stop()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        synthesizer.delegate = self
        synthesizer.speak(utterance)

        isPlaying = true
        currentArticleID = articleID
        speechState = .speaking(articleID)
    }

    func pause() {
        guard isSpeaking else { return }
        synthesizer.pauseSpeaking(at: .word)
        isPlaying = false
        if case let .speaking(id) = speechState {
            speechState = .paused(id)
        }
    }

    func resumeIfNeeded() {
        guard case let .paused(id) = speechState else { return }
        synthesizer.continueSpeaking()
        isPlaying = true
        speechState = .speaking(id)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        currentArticleID = nil
        speechState = .idle
    }

    func toggle() {
        if isPlaying {
            pause()
        } else if isPaused {
            resumeIfNeeded()
        }
    }
}

extension TextToSpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isPlaying = false
            currentArticleID = nil
            speechState = .idle
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isPlaying = false
            currentArticleID = nil
            speechState = .idle
        }
    }
}
