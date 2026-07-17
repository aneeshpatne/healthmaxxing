//
//  RecordFeedback.swift
//  Forma
//

import AVFAudio
import Combine
import Foundation
import SwiftUI

enum RecordFeedbackEvent: Hashable {
    case start
    case retry
    case cancel
    case metric(RecordMetricStage)
    case success
    case error

    var sensoryFeedback: SensoryFeedback {
        switch self {
        case .start:
            return .impact(weight: .medium, intensity: 0.72)
        case .retry:
            return .impact(weight: .light, intensity: 0.62)
        case .cancel:
            return .impact(weight: .medium, intensity: 0.58)
        case .metric:
            return .selection
        case .success:
            return .success
        case .error:
            return .error
        }
    }
}

enum RecordFeedbackCue: Equatable {
    case metric(RecordMetricStage)
    case success
    case error

    var event: RecordFeedbackEvent {
        switch self {
        case .metric(let stage):
            return .metric(stage)
        case .success:
            return .success
        case .error:
            return .error
        }
    }
}

extension RecordCircleState {
    var feedbackCue: RecordFeedbackCue? {
        switch self {
        case .weight:
            return .metric(.weight)
        case .impedance:
            return .metric(.impedance)
        case .heartRate:
            return .metric(.heartRate)
        case .saved:
            return .success
        case .recordingFailed, .submissionFailed:
            return .error
        case .ready, .connecting:
            return nil
        }
    }
}

@MainActor
final class RecordSoundPlayer: ObservableObject {
    private static let sampleRate = 44_100.0

    private var audioPlayer: AVAudioPlayer?
    private var hasConfiguredAudioSession = false

    func play(_ event: RecordFeedbackEvent) {
        configureAudioSessionIfNeeded()

        do {
            let player = try AVAudioPlayer(data: Self.soundData(for: event))
            player.prepareToPlay()
            player.play()
            audioPlayer = player
        } catch {
            // Sound is an enhancement; recording must remain usable if audio is unavailable.
        }
    }

    private func configureAudioSessionIfNeeded() {
        guard !hasConfiguredAudioSession else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            hasConfiguredAudioSession = true
        } catch {
            // Try again next time in case the audio session was temporarily interrupted.
        }
    }

    private static func soundData(for event: RecordFeedbackEvent) -> Data {
        let tones: [Tone]

        switch event {
        case .start:
            tones = [
                Tone(frequency: 392.00, duration: 0.055, amplitude: 0.075),
                Tone(frequency: 523.25, duration: 0.075, amplitude: 0.095),
            ]
        case .retry:
            tones = [Tone(frequency: 440.00, duration: 0.065, amplitude: 0.070)]
        case .cancel:
            tones = [Tone(frequency: 293.66, duration: 0.075, amplitude: 0.075)]
        case .metric(.weight):
            tones = [Tone(frequency: 440.00, duration: 0.045, amplitude: 0.050)]
        case .metric(.impedance):
            tones = [Tone(frequency: 523.25, duration: 0.045, amplitude: 0.050)]
        case .metric(.heartRate):
            tones = [Tone(frequency: 659.25, duration: 0.050, amplitude: 0.055)]
        case .success:
            tones = [
                Tone(frequency: 523.25, duration: 0.060, amplitude: 0.075),
                Tone(frequency: 659.25, duration: 0.065, amplitude: 0.085),
                Tone(frequency: 783.99, duration: 0.090, amplitude: 0.100),
            ]
        case .error:
            tones = [
                Tone(frequency: 311.13, duration: 0.070, amplitude: 0.075),
                Tone(frequency: 233.08, duration: 0.105, amplitude: 0.085),
            ]
        }

        return makeWaveFile(tones: tones)
    }

    private static func makeWaveFile(tones: [Tone]) -> Data {
        let gapSampleCount = Int(sampleRate * 0.012)
        var samples: [Int16] = []
        var phase = 0.0

        for (toneIndex, tone) in tones.enumerated() {
            let sampleCount = Int(sampleRate * tone.duration)

            for sampleIndex in 0..<sampleCount {
                let progress = Double(sampleIndex) / Double(max(sampleCount - 1, 1))
                let attack = min(1, progress / 0.16)
                let release = min(1, (1 - progress) / 0.30)
                let envelope = attack * release
                let fundamental = sin(phase)
                let softOvertone = 0.12 * sin(phase * 2)
                let value = (fundamental + softOvertone) * tone.amplitude * envelope
                samples.append(Int16(clamping: Int(value * Double(Int16.max))))
                phase += (2 * Double.pi * tone.frequency) / sampleRate
            }

            if toneIndex < tones.count - 1 {
                samples.append(contentsOf: repeatElement(0, count: gapSampleCount))
            }
        }

        var pcmData = Data(capacity: samples.count * MemoryLayout<Int16>.size)
        for sample in samples {
            appendLittleEndian(sample, to: &pcmData)
        }

        var waveData = Data()
        waveData.append(contentsOf: "RIFF".utf8)
        appendLittleEndian(UInt32(36 + pcmData.count), to: &waveData)
        waveData.append(contentsOf: "WAVE".utf8)
        waveData.append(contentsOf: "fmt ".utf8)
        appendLittleEndian(UInt32(16), to: &waveData)
        appendLittleEndian(UInt16(1), to: &waveData)
        appendLittleEndian(UInt16(1), to: &waveData)
        appendLittleEndian(UInt32(sampleRate), to: &waveData)
        appendLittleEndian(UInt32(sampleRate * 2), to: &waveData)
        appendLittleEndian(UInt16(2), to: &waveData)
        appendLittleEndian(UInt16(16), to: &waveData)
        waveData.append(contentsOf: "data".utf8)
        appendLittleEndian(UInt32(pcmData.count), to: &waveData)
        waveData.append(pcmData)

        return waveData
    }

    private static func appendLittleEndian<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
        var littleEndianValue = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndianValue) { bytes in
            data.append(contentsOf: bytes)
        }
    }
}

private struct Tone {
    let frequency: Double
    let duration: TimeInterval
    let amplitude: Double
}
