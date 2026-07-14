//
//  RecordView.swift
//  Forma
//
//  Created by Aneesh Patne on 19/06/26.
//

import SwiftUI
import UIKit

enum RecordMetricStage: Int, Equatable {
    case weight
    case impedance
    case heartRate
}

enum RecordMetricProgression {
    static func nextStage(
        after currentStage: RecordMetricStage?,
        measurement: ScaleMeasurement
    ) -> RecordMetricStage? {
        switch currentStage {
        case nil:
            return measurement.weightKg == nil ? nil : .weight
        case .weight:
            return measurement.impedanceOhms == nil ? nil : .impedance
        case .impedance:
            return measurement.heartRate == nil ? nil : .heartRate
        case .heartRate:
            return nil
        }
    }
}

enum RecordCircleState: Equatable {
    case ready
    case connecting(String)
    case weight(Float)
    case impedance(Float)
    case heartRate(Int, isSubmitting: Bool)
    case saved
    case recordingFailed(String)
    case submissionFailed(String)

    var isActionable: Bool {
        switch self {
        case .ready, .connecting, .weight, .impedance, .saved, .recordingFailed, .submissionFailed:
            return true
        case .heartRate(_, let isSubmitting):
            return !isSubmitting
        }
    }
}

private enum RecordOutcome: Equatable {
    case saved
    case recordingFailed(String)
    case submissionFailed(String)
}

@MainActor
protocol IdleTimerControlling: AnyObject {
    var isIdleTimerDisabled: Bool { get set }
}

extension UIApplication: IdleTimerControlling {}

@MainActor
final class IdleTimerLease {
    private weak var controller: (any IdleTimerControlling)?
    private let previousValue: Bool
    private var isReleased = false

    convenience init() {
        self.init(controller: UIApplication.shared)
    }

    init(controller: any IdleTimerControlling) {
        self.controller = controller
        previousValue = controller.isIdleTimerDisabled
        controller.isIdleTimerDisabled = true
    }

    func release() {
        guard !isReleased else { return }
        controller?.isIdleTimerDisabled = previousValue
        isReleased = true
    }

    deinit {
        MainActor.assumeIsolated {
            release()
        }
    }
}

struct RecordView: View {
    private static let minimumMetricDisplayDuration = Duration.milliseconds(800)

    @StateObject private var scaleManager = ScaleBLEManager()

    @State private var isSubmittingMeasurement = false
    @State private var submittedMeasurement: ScaleMeasurement?
    @State private var outcome: RecordOutcome?
    @State private var displayedMetricStage: RecordMetricStage?
    @State private var metricStageStartedAt = ContinuousClock.now
    @State private var canRevealSubmissionOutcome = false
    @State private var metricAdvanceTask: Task<Void, Never>?
    @State private var outcomeRevealTask: Task<Void, Never>?
    @State private var idleTimerLease: IdleTimerLease?

    private let apiClient = APIClient()
    private let clock = ContinuousClock()

    var body: some View {
        GeometryReader { proxy in
            let availableDimension = min(proxy.size.width - (FormaSpacing.screenGutter * 2), proxy.size.height - 40)
            let diameter = min(240, max(180, availableDimension))

            ZStack {
                FormaBackground()

                RecordCircle(
                    state: circleState,
                    diameter: diameter,
                    isEnabled: circleIsEnabled,
                    showsActivityRing: scaleManager.isReading,
                    action: handleCircleAction
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, FormaLayout.floatingSettingsClearance)
        }
        .onChange(of: scaleManager.isReading, initial: true) { _, isReading in
            updateIdleTimer(isReading: isReading)
        }
        .onChange(of: scaleManager.latestMeasurement) { _, measurement in
            handleMeasurementUpdate(measurement)
        }
        .onChange(of: scaleManager.state) { _, state in
            handleScaleStateChange(state)
        }
        .onDisappear {
            if !scaleManager.isReading {
                releaseIdleTimerLease()
            }
        }
    }

    private var circleState: RecordCircleState {
        if let outcome {
            switch outcome {
            case .saved where canRevealSubmissionOutcome:
                return .saved
            case .submissionFailed(let message) where canRevealSubmissionOutcome:
                return .submissionFailed(message)
            case .recordingFailed(let message):
                return .recordingFailed(message)
            case .saved, .submissionFailed:
                break
            }
        }

        switch displayedMetricStage {
        case .weight:
            if let weight = scaleManager.latestMeasurement.weightKg {
                return .weight(weight)
            }
        case .impedance:
            if let impedance = scaleManager.latestMeasurement.impedanceOhms {
                return .impedance(impedance)
            }
        case .heartRate:
            if let heartRate = scaleManager.latestMeasurement.heartRate {
                let isWaitingForResult = isSubmittingMeasurement || outcome != nil
                return .heartRate(heartRate, isSubmitting: isWaitingForResult)
            }
        case nil:
            break
        }

        if scaleManager.isReading {
            return .connecting(connectionLabel)
        }

        return .ready
    }

    private var connectionLabel: String {
        switch scaleManager.state {
        case .idle:
            return "Starting"
        case .waitingForBluetooth:
            return "Bluetooth"
        case .scanning:
            return "Searching"
        case .connecting:
            return "Connecting"
        case .discoveringServices:
            return "Preparing"
        case .listening:
            return "Reading"
        case .finished:
            return "Complete"
        case .failed:
            return "Try Again"
        }
    }

    private var circleIsEnabled: Bool {
        switch circleState {
        case .ready, .saved, .recordingFailed, .submissionFailed:
            return true
        case .connecting, .weight, .impedance, .heartRate:
            return scaleManager.isReading
        }
    }

    private func handleCircleAction() {
        switch circleState {
        case .ready, .recordingFailed:
            startNewReading()

        case .saved:
            resetToReady()

        case .submissionFailed:
            Task {
                await submitLatestMeasurement()
            }

        case .connecting, .weight, .impedance, .heartRate:
            guard scaleManager.isReading else { return }
            cancelReading()
        }
    }

    private func startNewReading() {
        resetPresentation()
        submittedMeasurement = nil
        scaleManager.startReading()
    }

    private func resetToReady() {
        resetPresentation()
        submittedMeasurement = nil
    }

    private func cancelReading() {
        scaleManager.stopReading()
        resetPresentation()
        submittedMeasurement = nil
    }

    private func resetPresentation() {
        metricAdvanceTask?.cancel()
        metricAdvanceTask = nil
        outcomeRevealTask?.cancel()
        outcomeRevealTask = nil
        outcome = nil
        displayedMetricStage = nil
        canRevealSubmissionOutcome = false
        isSubmittingMeasurement = false
    }

    private func handleMeasurementUpdate(_ measurement: ScaleMeasurement) {
        if displayedMetricStage == nil, measurement.weightKg != nil {
            showMetricStage(.weight)
        }

        scheduleNextMetricStageIfNeeded()
    }

    private func handleScaleStateChange(_ state: ScaleConnectionState) {
        switch state {
        case .finished:
            Task {
                await submitLatestMeasurement()
            }

        case .failed(let message):
            outcome = .recordingFailed(message)

        case .idle, .waitingForBluetooth, .scanning, .connecting, .discoveringServices, .listening:
            break
        }
    }

    private func showMetricStage(_ stage: RecordMetricStage) {
        displayedMetricStage = stage
        metricStageStartedAt = clock.now

        if stage == .heartRate {
            scheduleSubmissionOutcomeReveal()
        } else {
            scheduleNextMetricStageIfNeeded()
        }
    }

    private func scheduleNextMetricStageIfNeeded() {
        guard let nextStage = nextAvailableMetricStage else { return }

        metricAdvanceTask?.cancel()
        let elapsed = metricStageStartedAt.duration(to: clock.now)
        let delay = max(.zero, Self.minimumMetricDisplayDuration - elapsed)

        metricAdvanceTask = Task { @MainActor in
            do {
                try await Task.sleep(for: delay)
            } catch {
                return
            }

            guard !Task.isCancelled else { return }
            metricAdvanceTask = nil

            guard nextStageIsStillAvailable(nextStage) else { return }
            showMetricStage(nextStage)
        }
    }

    private var nextAvailableMetricStage: RecordMetricStage? {
        RecordMetricProgression.nextStage(
            after: displayedMetricStage,
            measurement: scaleManager.latestMeasurement
        )
    }

    private func nextStageIsStillAvailable(_ stage: RecordMetricStage) -> Bool {
        switch stage {
        case .weight:
            return scaleManager.latestMeasurement.weightKg != nil
        case .impedance:
            return scaleManager.latestMeasurement.impedanceOhms != nil
        case .heartRate:
            return scaleManager.latestMeasurement.heartRate != nil
        }
    }

    private func scheduleSubmissionOutcomeReveal() {
        outcomeRevealTask?.cancel()
        canRevealSubmissionOutcome = false

        outcomeRevealTask = Task { @MainActor in
            do {
                try await Task.sleep(for: Self.minimumMetricDisplayDuration)
            } catch {
                return
            }

            guard !Task.isCancelled else { return }
            canRevealSubmissionOutcome = true
            outcomeRevealTask = nil
        }
    }

    @MainActor
    private func submitLatestMeasurement() async {
        let measurement = scaleManager.latestMeasurement

        guard submittedMeasurement != measurement, !isSubmittingMeasurement else {
            return
        }

        guard let profileId = PrimaryProfileStore.primaryProfileId else {
            outcome = .submissionFailed("Create or select a primary profile before saving measurements.")
            return
        }

        guard let weight = measurement.weightKg,
              let heartRate = measurement.heartRate,
              let impedance = measurement.impedanceOhms else {
            outcome = .recordingFailed("A complete scale reading is required before saving.")
            return
        }

        isSubmittingMeasurement = true
        outcome = nil

        defer {
            isSubmittingMeasurement = false
        }

        do {
            let body = AddMeasurementBody(
                profileId: profileId,
                weight: Double(weight),
                heartbeat: heartRate,
                impedance: Double(impedance)
            )

            let response = try await apiClient.send(AddMeasurementRequest(body: body))
            submittedMeasurement = measurement
            InsightReportJobStore.add(response.jobId, for: profileId)
            outcome = .saved
        } catch APIError.missingAuthToken {
            outcome = .submissionFailed("Missing auth token.")
        } catch APIError.serverError(let statusCode, let responseBody) {
            outcome = .submissionFailed(Self.serverErrorMessage(statusCode: statusCode, responseBody: responseBody))
        } catch {
            if (error as? URLError)?.code == .cancelled || error is CancellationError {
                return
            }

            outcome = .submissionFailed("Failed to save measurement.")
        }
    }

    private func updateIdleTimer(isReading: Bool) {
        if isReading {
            if idleTimerLease == nil {
                idleTimerLease = IdleTimerLease()
            }
        } else {
            releaseIdleTimerLease()
        }
    }

    private func releaseIdleTimerLease() {
        idleTimerLease?.release()
        idleTimerLease = nil
    }

    private static func serverErrorMessage(statusCode: Int, responseBody: String?) -> String {
        let trimmedBody = responseBody?.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let trimmedBody, !trimmedBody.isEmpty else {
            return "Server returned \(statusCode)."
        }

        return "Server returned \(statusCode): \(trimmedBody)"
    }
}

private struct RecordCircle: View {
    let state: RecordCircleState
    let diameter: CGFloat
    let isEnabled: Bool
    let showsActivityRing: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(backgroundFill)
                    .overlay {
                        Circle()
                            .fill(highlightGradient)
                    }
                    .shadow(color: shadowColor, radius: 24, x: 0, y: 14)

                content
                    .padding(FormaSpacing.xl)
            }
            .frame(width: diameter, height: diameter)
            .contentShape(Circle())
            .overlay {
                if showsActivityRing {
                    OrbitingRecordRing(diameter: diameter + 18)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
        }
        .buttonStyle(RecordCircleButtonStyle(isEnabled: isEnabled))
        .disabled(!isEnabled)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(accessibilityHint)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.22), value: state)
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .ready:
            Text("Record")
                .font(.title2.weight(.semibold))

        case .connecting(let label):
            VStack(spacing: FormaSpacing.md) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.formaTeal)
                Text(label)
                    .font(.headline.weight(.semibold))
            }

        case .weight(let value):
            metricContent(title: "Weight", value: String(format: "%.1f", value), unit: "kg")

        case .impedance(let value):
            metricContent(title: "Impedance", value: String(format: "%.0f", value), unit: "Ω")

        case .heartRate(let value, let isSubmitting):
            VStack(spacing: FormaSpacing.sm) {
                metricContent(title: "Heart Rate", value: String(value), unit: "bpm")

                if isSubmitting {
                    ProgressView()
                        .controlSize(.small)
                        .transition(.opacity)
                }
            }

        case .saved:
            resultContent(title: "Saved", systemImage: "checkmark")

        case .recordingFailed:
            resultContent(title: "Try Again", systemImage: "exclamationmark")

        case .submissionFailed:
            resultContent(title: "Retry Save", systemImage: "arrow.clockwise")
        }
    }

    private func metricContent(title: String, value: String, unit: String) -> some View {
        VStack(spacing: FormaSpacing.xs) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .tracking(0.8)
                .opacity(0.72)

            Text(value)
                .font(.system(size: 54, weight: .semibold, design: .rounded))
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Text(unit)
                .font(.subheadline.weight(.semibold))
                .opacity(0.72)
        }
    }

    private func resultContent(title: String, systemImage: String) -> some View {
        VStack(spacing: FormaSpacing.sm) {
            Image(systemName: systemImage)
                .font(.system(size: 32, weight: .bold))
            Text(title)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
        }
    }

    private var backgroundFill: Color {
        switch state {
        case .ready:
            return .actionInk
        case .saved:
            return .green
        case .recordingFailed, .submissionFailed:
            return .red
        case .connecting, .weight, .impedance, .heartRate:
            return .appSecondaryBackground
        }
    }

    private var highlightGradient: RadialGradient {
        let color: Color
        switch state {
        case .ready:
            color = .white.opacity(0.16)
        case .saved, .recordingFailed, .submissionFailed:
            color = .white.opacity(0.18)
        case .connecting, .weight, .impedance, .heartRate:
            color = .formaTeal.opacity(0.15)
        }

        return RadialGradient(
            colors: [color, .clear],
            center: .topLeading,
            startRadius: 0,
            endRadius: diameter
        )
    }

    private var shadowColor: Color {
        switch state {
        case .saved:
            return .green.opacity(0.24)
        case .recordingFailed, .submissionFailed:
            return .red.opacity(0.24)
        case .ready:
            return .actionInk.opacity(0.24)
        case .connecting, .weight, .impedance, .heartRate:
            return .cardShadow
        }
    }

    private var accessibilityLabel: String {
        switch state {
        case .ready:
            return "Record"
        case .connecting:
            return "Connecting to scale"
        case .weight:
            return "Weight"
        case .impedance:
            return "Impedance"
        case .heartRate:
            return "Heart rate"
        case .saved:
            return "Measurement saved"
        case .recordingFailed:
            return "Measurement failed"
        case .submissionFailed:
            return "Submission failed"
        }
    }

    private var accessibilityValue: String {
        switch state {
        case .ready:
            return "Ready"
        case .connecting(let label):
            return label
        case .weight(let value):
            return String(format: "%.1f kilograms", value)
        case .impedance(let value):
            return String(format: "%.0f ohms", value)
        case .heartRate(let value, let isSubmitting):
            return "\(value) beats per minute\(isSubmitting ? ", submitting" : "")"
        case .saved:
            return "Tap to record another measurement"
        case .recordingFailed(let message), .submissionFailed(let message):
            return message
        }
    }

    private var accessibilityHint: String {
        switch state {
        case .ready:
            return "Starts a new scale reading"
        case .saved:
            return "Resets the recorder"
        case .recordingFailed:
            return "Starts a new scale reading"
        case .submissionFailed:
            return "Retries saving this measurement"
        case .connecting, .weight, .impedance:
            return "Tap to cancel this scale reading"
        case .heartRate(_, let isSubmitting):
            return isSubmitting ? "Measurement is being saved" : "Tap to cancel this scale reading"
        }
    }
}

private struct OrbitingRecordRing: View {
    let diameter: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.formaTeal.opacity(0.12), lineWidth: 3)

            if reduceMotion {
                Circle()
                    .trim(from: 0, to: 0.24)
                    .stroke(
                        Color.formaTeal,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
                    let revolutionDuration = 1.6
                    let progress = context.date.timeIntervalSinceReferenceDate
                        .truncatingRemainder(dividingBy: revolutionDuration) / revolutionDuration

                    Circle()
                        .trim(from: 0, to: 0.24)
                        .stroke(
                            AngularGradient(
                                colors: [.formaTeal.opacity(0.22), .formaTeal],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .rotationEffect(.degrees((progress * 360) - 90))
                }
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityHidden(true)
    }
}

private struct RecordCircleButtonStyle: ButtonStyle {
    let isEnabled: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && isEnabled && !reduceMotion ? 0.96 : 1)
            .opacity(configuration.isPressed && isEnabled ? 0.92 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

#Preview("Record") {
    RecordCircle(state: .ready, diameter: 240, isEnabled: true, showsActivityRing: false, action: {})
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FormaBackground())
}

#Preview("Live measurements") {
    VStack(spacing: FormaSpacing.xl) {
        RecordCircle(state: .weight(73.5), diameter: 210, isEnabled: true, showsActivityRing: true, action: {})
        RecordCircle(state: .heartRate(72, isSubmitting: true), diameter: 210, isEnabled: false, showsActivityRing: false, action: {})
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(FormaBackground())
}

#Preview("Results") {
    HStack(spacing: FormaSpacing.md) {
        RecordCircle(state: .saved, diameter: 170, isEnabled: true, showsActivityRing: false, action: {})
        RecordCircle(state: .submissionFailed("Failed to save measurement."), diameter: 170, isEnabled: true, showsActivityRing: false, action: {})
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(FormaBackground())
}
