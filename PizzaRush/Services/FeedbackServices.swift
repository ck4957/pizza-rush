import AVFoundation
import GameKit
import Observation
import UIKit

enum GameFeedbackEvent: CaseIterable, Sendable {
    case buttonTap
    case ingredientDrop
    case sauceSpread
    case cheeseSprinkle
    case ovenOpen
    case ovenReady
    case perfectBake
    case burnAlarm
    case slice
    case boxClose
    case delivery
    case coinCollection
    case comboIncrease
    case customerLeaves
    case levelComplete

    var frequency: Double {
        switch self {
        case .buttonTap: 520
        case .ingredientDrop: 420
        case .sauceSpread: 330
        case .cheeseSprinkle: 680
        case .ovenOpen: 220
        case .ovenReady: 760
        case .perfectBake: 940
        case .burnAlarm: 145
        case .slice: 360
        case .boxClose: 250
        case .delivery: 620
        case .coinCollection: 1_080
        case .comboIncrease: 840
        case .customerLeaves: 180
        case .levelComplete: 720
        }
    }

    var duration: TimeInterval {
        switch self {
        case .buttonTap, .ingredientDrop, .slice, .boxClose: 0.07
        case .sauceSpread, .cheeseSprinkle, .ovenOpen, .delivery, .coinCollection, .comboIncrease: 0.12
        case .ovenReady, .perfectBake, .customerLeaves, .levelComplete: 0.20
        case .burnAlarm: 0.32
        }
    }
}

@MainActor
protocol AudioPlaying: AnyObject {
    func play(_ event: GameFeedbackEvent)
    func setEnabled(effects: Bool, music: Bool)
    func stop()
}

@MainActor
final class AudioManager: AudioPlaying {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var buffers: [GameFeedbackEvent: AVAudioPCMBuffer] = [:]
    private var configured = false
    private var effectsEnabled = true
    private var musicEnabled = true

    init() {
        prepare()
    }

    func play(_ event: GameFeedbackEvent) {
        guard effectsEnabled else { return }
        if !engine.isRunning {
            prepare()
        }
        guard engine.isRunning, let buffer = buffers[event] else { return }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !player.isPlaying {
            player.play()
        }
    }

    func setEnabled(effects: Bool, music: Bool) {
        effectsEnabled = effects
        musicEnabled = music
        if !effects && !music {
            stop()
        } else if !engine.isRunning {
            prepare()
        }
    }

    func stop() {
        player.stop()
        engine.stop()
    }

    private func prepare() {
        if !configured {
            guard let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2) else {
                return
            }
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            for event in GameFeedbackEvent.allCases {
                buffers[event] = makeBuffer(event: event, format: format)
            }
            configured = true
        }
        engine.prepare()
        do {
            try engine.start()
            player.play()
        } catch {
            // Gameplay remains fully usable without sound.
        }
    }

    private func makeBuffer(
        event: GameFeedbackEvent,
        format: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(format.sampleRate * event.duration)
        guard
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
            let channelData = buffer.floatChannelData
        else { return nil }

        buffer.frameLength = frameCount
        for channel in 0 ..< Int(format.channelCount) {
            let samples = channelData[channel]
            for frame in 0 ..< Int(frameCount) {
                let time = Double(frame) / format.sampleRate
                let progress = time / event.duration
                let attack = min(1, progress * 18)
                let release = max(0, 1 - progress)
                let envelope = attack * release * release
                let fundamental = sin(2 * .pi * event.frequency * time)
                let harmonic = sin(2 * .pi * event.frequency * 1.5 * time) * 0.10
                samples[frame] = Float((fundamental + harmonic) * envelope * 0.14)
            }
        }
        return buffer
    }
}

enum GameHaptic: Sendable {
    case light
    case medium
    case success
    case warning
    case error
}

@MainActor
protocol HapticProviding: AnyObject {
    func play(_ event: GameHaptic)
    func setEnabled(_ enabled: Bool)
}

@MainActor
final class HapticManager: HapticProviding {
    private var enabled = true

    func setEnabled(_ enabled: Bool) {
        self.enabled = enabled
    }

    func play(_ event: GameHaptic) {
        guard enabled else { return }
        switch event {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

protocol AnalyticsTracking: AnyObject {
    func track(_ event: String, properties: [String: String])
}

final class NoOpAnalytics: AnalyticsTracking {
    func track(_ event: String, properties: [String: String] = [:]) {}
}

@MainActor
@Observable
final class GameCenterService {
    private(set) var isAvailable = false
    private(set) var lastError: String?

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                if let viewController {
                    self?.present(viewController)
                }
                self?.isAvailable = GKLocalPlayer.local.isAuthenticated
                self?.lastError = error?.localizedDescription
            }
        }
    }

    private func present(_ viewController: UIViewController) {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let root = scenes.flatMap(\.windows).first(where: \.isKeyWindow)?.rootViewController
        root?.present(viewController, animated: true)
    }
}
