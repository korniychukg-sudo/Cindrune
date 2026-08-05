import Foundation
import AVFoundation
import UIKit

// Every sound in Cindrune is synthesised at build time into the bundled
// Audio folder and played back through a small pool of nodes.

enum ForgeSample: String, CaseIterable {
    case hitHot = "fx_hit_hot"
    case hitCold = "fx_hit_cold"
    case ring = "fx_ring"
    case bellows = "fx_bellows"
    case quench = "fx_quench"
    case crack = "fx_crack"
    case punch = "fx_punch"
    case twist = "fx_twist"
    case chime = "fx_chime"
    case tap = "fx_tap"
}

final class ForgeSound {
    static let shared = ForgeSound()

    var enabled = true {
        didSet { if !enabled { stopAmbient() } }
    }
    var hapticsEnabled = true

    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private let ambientPlayer = AVAudioPlayerNode()
    private var buffers: [String: AVAudioPCMBuffer] = [:]
    private var nextPlayer = 0
    private var ambientName = ""
    private let loadQueue = DispatchQueue(label: "cindrune.audio")

    private let lightTap = UIImpactFeedbackGenerator(style: .light)
    private let mediumTap = UIImpactFeedbackGenerator(style: .medium)
    private let heavyTap = UIImpactFeedbackGenerator(style: .heavy)

    private init() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default)
        try? session.setActive(true)
        for _ in 0..<14 {
            let node = AVAudioPlayerNode()
            players.append(node)
            engine.attach(node)
        }
        engine.attach(ambientPlayer)
        loadQueue.async { [weak self] in self?.loadAll() }
    }

    private func loadAll() {
        var names = ForgeSample.allCases.map { $0.rawValue }
        names.append("amb_forge")
        var loaded: [String: AVAudioPCMBuffer] = [:]
        for name in names {
            guard let url = Bundle.main.url(forResource: name, withExtension: "wav",
                                            subdirectory: "Audio"),
                  let file = try? AVAudioFile(forReading: url),
                  let buf = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                             frameCapacity: AVAudioFrameCount(file.length))
            else { continue }
            try? file.read(into: buf)
            loaded[name] = buf
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.buffers = loaded
            if let fmt = loaded.values.first?.format {
                for node in self.players {
                    self.engine.connect(node, to: self.engine.mainMixerNode, format: fmt)
                }
                self.engine.connect(self.ambientPlayer, to: self.engine.mainMixerNode, format: fmt)
                self.ambientPlayer.volume = 0.28
            }
        }
    }

    @discardableResult
    private func ensureRunning() -> Bool {
        if !engine.isRunning {
            do { try engine.start() } catch { return false }
        }
        return true
    }

    func play(_ sample: ForgeSample, volume: Float = 1.0) {
        guard enabled, let buf = buffers[sample.rawValue], ensureRunning() else { return }
        let node = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        node.stop()
        node.volume = volume
        node.scheduleBuffer(buf, at: nil, options: [])
        node.play()
    }

    func startAmbient() {
        guard enabled else { stopAmbient(); return }
        guard ambientName != "amb_forge" else { return }
        guard let buf = buffers["amb_forge"], ensureRunning() else { return }
        ambientName = "amb_forge"
        ambientPlayer.stop()
        ambientPlayer.scheduleBuffer(buf, at: nil, options: .loops)
        ambientPlayer.play()
    }

    func stopAmbient() {
        ambientName = ""
        ambientPlayer.stop()
    }

    // MARK: - Haptics

    func bump(_ strength: Int) {
        guard hapticsEnabled else { return }
        switch strength {
        case 0: lightTap.impactOccurred()
        case 1: mediumTap.impactOccurred()
        default: heavyTap.impactOccurred()
        }
    }
}
