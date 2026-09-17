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

private struct RecordFeedbackSignal: Equatable {
    let sequence: Int
    let event: RecordFeedbackEvent
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
    /// Brief hold so each stage is readable without feeling staged behind the scale.
    private static let minimumMetricDisplayDuration = Duration.milliseconds(400)
    /// Hold long enough for the success ritual to land before the sheet auto-dismisses.
    private static let successDismissDelay = Duration.milliseconds(350)

    let reportStore: MetricsReportStore
    var debugMeasurement: ScaleMeasurement? = nil
    /// Called after a successful save so the host can dismiss the sheet.
    var onSuccess: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @StateObject private var scaleManager = ScaleBLEManager()

    @State private var isSubmittingMeasurement = false
    @State private var submittedMeasurement: ScaleMeasurement?
    @State private var outcome: RecordOutcome?
    @State private var displayedMetricStage: RecordMetricStage?
    @State private var metricStageStartedAt = ContinuousClock.now
    @State private var canRevealSubmissionOutcome = false
    @State private var metricAdvanceTask: Task<Void, Never>?
    @State private var outcomeRevealTask: Task<Void, Never>?
    @State private var successDismissTask: Task<Void, Never>?
    @State private var idleTimerLease: IdleTimerLease?
    @State private var feedbackSignal = RecordFeedbackSignal(sequence: 0, event: .start)

    private let apiClient = APIClient()
    private let clock = ContinuousClock()

    private var isBusy: Bool {
        scaleManager.isReading || isSubmittingMeasurement
    }

    var body: some View {
        GeometryReader { proxy in
            let availableDimension = min(
                proxy.size.width - (FormaSpacing.screenGutter * 2),
                proxy.size.height - FormaSpacing.xxxl
            )
            let diameter = min(240, max(180, availableDimension))

            ZStack {
                FormaBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: FormaSpacing.xl) {
                        RecordCircle(
                            state: circleState,
                            diameter: diameter,
                            isEnabled: circleIsEnabled,
                            showsActivityRing: scaleManager.isReading,
                            action: handleCircleAction
                        )

                        RecordFlowFooter(
                            state: circleState,
                            measurement: scaleManager.latestMeasurement,
                            isReading: scaleManager.isReading
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: max(0, proxy.size.height - FormaSpacing.xxl))
                    .padding(.horizontal, FormaSpacing.screenGutter)
                    .padding(.top, FormaSpacing.lg)
                    .padding(.bottom, FormaSpacing.xl)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .interactiveDismissDisabled(isBusy)
        .onChange(of: scaleManager.isReading, initial: true) { wasReading, isReading in
            updateIdleTimer(isReading: isReading)
            if !wasReading && isReading {
                emitFeedback(.start)
            }
        }
        .onChange(of: scaleManager.latestMeasurement) { _, measurement in
            handleMeasurementUpdate(measurement)
        }
        .onChange(of: scaleManager.state) { _, state in
            handleScaleStateChange(state)
        }
        .onChange(of: displayedMetricStage) { _, stage in
            if let stage {
                emitFeedback(.metric(stage))
            }
        }
        .onChange(of: circleState) { previousState, state in
            if previousState != .saved && state == .saved {
                emitFeedback(.success)
                scheduleSuccessDismiss()
            } else if !previousState.isFailure && state.isFailure {
                emitFeedback(.error)
            }
        }
        .onDisappear {
            tearDownSession()
        }
        .recordFeedback(signal: feedbackSignal)
        .accessibilityIdentifier("record-sheet")
        .task {
            guard let debugMeasurement,
                  let weight = debugMeasurement.weightKg,
                  let impedance = debugMeasurement.impedanceOhms,
                  let heartRate = debugMeasurement.heartRate else { return }

            scaleManager.startDebugReading(
                weightKg: weight,
                impedanceOhms: impedance,
                heartRate: heartRate
            )
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
            return "Turn on Bluetooth"
        case .scanning:
            return "Finding your scale"
        case .connecting:
            return "Connecting"
        case .discoveringServices:
            return "Waking your scale"
        case .listening:
            return "Step on your scale"
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
            emitFeedback(.retry)
            Task {
                await submitLatestMeasurement()
            }

        case .connecting, .weight, .impedance, .heartRate:
            guard scaleManager.isReading else { return }
            emitFeedback(.cancel)
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
        successDismissTask?.cancel()
        successDismissTask = nil
        outcome = nil
        displayedMetricStage = nil
        canRevealSubmissionOutcome = false
        isSubmittingMeasurement = false
    }

    private func scheduleSuccessDismiss() {
        successDismissTask?.cancel()

        let delay = reduceMotion ? Duration.milliseconds(250) : Self.successDismissDelay
        successDismissTask = Task { @MainActor in
            do {
                try await Task.sleep(for: delay)
            } catch {
                return
            }

            guard !Task.isCancelled else { return }
            successDismissTask = nil
            dismissAfterSuccess()
        }
    }

    private func dismissAfterSuccess() {
        if let onSuccess {
            onSuccess()
        } else {
            dismiss()
        }
    }

    private func tearDownSession() {
        successDismissTask?.cancel()
        successDismissTask = nil
        metricAdvanceTask?.cancel()
        metricAdvanceTask = nil
        outcomeRevealTask?.cancel()
        outcomeRevealTask = nil

        if scaleManager.isReading {
            scaleManager.stopReading()
        }
        releaseIdleTimerLease()
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
            reportStore.reportQueued(for: profileId, jobId: response.jobId)
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

    private func emitFeedback(_ event: RecordFeedbackEvent) {
        feedbackSignal = RecordFeedbackSignal(sequence: feedbackSignal.sequence + 1, event: event)
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

private struct RecordFeedbackSignalModifier: ViewModifier {
    let signal: RecordFeedbackSignal

    @EnvironmentObject private var soundPlayer: FormaSoundPlayer
    @AppStorage(FormaFeedbackPreferences.hapticsKey) private var hapticsEnabled = true

    func body(content: Content) -> some View {
        content
            .onChange(of: signal) { _, signal in
                soundPlayer.play(signal.event)
            }
            .sensoryFeedback(signal.event.sensoryFeedback, trigger: signal.sequence) { previous, current in
                hapticsEnabled && previous != current
            }
    }
}

private extension View {
    func recordFeedback(signal: RecordFeedbackSignal) -> some View {
        modifier(RecordFeedbackSignalModifier(signal: signal))
    }
}

private struct RecordCircle: View {
    let state: RecordCircleState
    let diameter: CGFloat
    let isEnabled: Bool
    let showsActivityRing: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var metricValueSize: CGFloat = 54

    private var isSaved: Bool {
        if case .saved = state { return true }
        return false
    }

    private var isReady: Bool {
        if case .ready = state { return true }
        return false
    }

    var body: some View {
        Button(action: action) {
            ZStack {

                circleBackground
                    .shadow(
                        color: shadowColor,
                        radius: 8,
                        x: 0,
                        y: 4
                    )

                content
                    .padding(FormaSpacing.xl)
            }
            .frame(width: diameter, height: diameter)
            .contentShape(Circle())
            .overlay(alignment: .topTrailing) {
                if showsActivityRing {
                    FormaLoadingIndicator()
                        .padding(6)
                        .background(.regularMaterial, in: Circle())
                        .overlay(Circle().strokeBorder(Color.appBorder, lineWidth: 1))
                        .offset(x: 8, y: -8)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }

        }
        .buttonStyle(FormaPressableButtonStyle(depth: .prominent))
        .disabled(!isEnabled)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(accessibilityHint)
        .accessibilityIdentifier("record-primary-control")
        .animation(
            FormaMotion.preferred(FormaMotion.standard, reduceMotion: reduceMotion),
            value: state
        )
    }

    @ViewBuilder
    private var circleBackground: some View {
        switch state {
        case .ready:
            ReadyRecordPalette(diameter: diameter)

        case .saved:
            Circle().fill(Color.actionInk).frame(width: diameter, height: diameter)

        case .recordingFailed, .submissionFailed, .connecting, .weight, .impedance, .heartRate:
            Circle()
                .fill(backgroundFill)
                .overlay {
                    Circle()
                        .fill(highlightGradient)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .ready:
            ReadyRecordLabel()

        case .connecting(let label):
            VStack(spacing: FormaSpacing.md) {
                Image(forma: "antenna.radiowaves.left.and.right")
                    .resizable().scaledToFit().frame(width: 28, height: 28)
                    .foregroundStyle(Color.sleekAccent)
                Text(label)
                    .font(FormaTypography.textStyle(.headline, weight: .semibold))
            }

        case .weight(let value):
            metricContent(title: "Weight", value: String(format: "%.1f", value), unit: "kg")

        case .impedance(let value):
            metricContent(title: "Impedance", value: String(format: "%.0f", value), unit: "Ω")

        case .heartRate(let value, let isSubmitting):
            VStack(spacing: FormaSpacing.sm) {
                metricContent(title: "Heart Rate", value: String(value), unit: "bpm")

                if isSubmitting {
                    FormaLoadingIndicator(tint: .sleekAccent)
                        .transition(.opacity)
                }
            }

        case .saved:
            RecordSuccessMark()

        case .recordingFailed:
            resultContent(title: "Try Again", systemImage: "exclamationmark")

        case .submissionFailed:
            resultContent(title: "Retry Save", systemImage: "arrow.clockwise")
        }
    }

    private func metricContent(title: String, value: String, unit: String) -> some View {
        VStack(spacing: FormaSpacing.xs) {
            Text(title.uppercased())
                .font(FormaTypography.textStyle(.caption, weight: .bold))
                .tracking(0.8)
                .opacity(0.72)

            Text(value)
                .font(FormaTypography.system(size: metricValueSize, weight: .semibold))
                .contentTransition(reduceMotion ? .identity : .numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Text(unit)
                .font(FormaTypography.textStyle(.subheadline, weight: .semibold))
                .opacity(0.72)
        }
    }

    private func resultContent(title: String, systemImage: String) -> some View {
        VStack(spacing: FormaSpacing.sm) {
            resultSymbol(systemImage)
            Text(title)
                .font(FormaTypography.textStyle(.title3, weight: .semibold))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(Color.actionForeground)
    }

    @ViewBuilder
    private func resultSymbol(_ systemImage: String) -> some View {
        Image(forma: systemImage)
            .resizable().scaledToFit().frame(width: 32, height: 32)
    }

    private var backgroundFill: Color {
        switch state {
        case .ready:
            return .actionInk
        case .saved:
            return .formaPositive
        case .recordingFailed, .submissionFailed:
            return .formaNegativeFill
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
            color = .sleekAccent.opacity(0.12)
        }

        return RadialGradient(
            colors: [color, .clear],
            center: .topLeading,
            startRadius: 0,
            endRadius: diameter
        )
    }

    private var shadowColor: Color { .cardShadow }

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
            return "Saved"
        case .recordingFailed(let message), .submissionFailed(let message):
            return message
        }
    }

    private var accessibilityHint: String {
        switch state {
        case .ready:
            return "Starts a new scale reading"
        case .saved:
            return "Sheet will close automatically"
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

// MARK: - Success microinteractions

/// Immediate, readable confirmation.
private struct RecordSuccessMark: View {
    var body: some View {
        VStack(spacing: FormaSpacing.xs) {
            Image(forma: "checkmark").resizable().scaledToFit()
                .frame(width: 36, height: 36)
            Text("Saved").font(FormaTypography.sectionHeadline)
        }
        .foregroundStyle(Color.actionForeground)
    }
}

/// Guidance area beneath the record circle: stage progress during a reading,
/// and a visible error message when something goes wrong.
private struct RecordFlowFooter: View {
    let state: RecordCircleState
    let measurement: ScaleMeasurement
    let isReading: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            switch state {
            case .recordingFailed(let message):
                VStack(spacing: FormaSpacing.xs) {
                    Text(message)
                        .font(FormaTypography.body)
                        .foregroundStyle(Color.formaNegative)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(recoveryGuidance(for: message))
                        .font(FormaTypography.textStyle(.caption))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Text(state.actionGuidance)
                        .font(FormaTypography.textStyle(.caption, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, FormaSpacing.xxl)
                .transition(FormaTransition.content(reduceMotion: reduceMotion))

            case .submissionFailed(let message):
                VStack(spacing: FormaSpacing.xs) {
                    Text(message)
                        .font(FormaTypography.body)
                        .foregroundStyle(Color.formaNegative)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Check your connection. The captured values are still ready to save.")
                        .font(FormaTypography.textStyle(.caption))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Text(state.actionGuidance)
                        .font(FormaTypography.textStyle(.caption, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, FormaSpacing.xxl)
                .transition(FormaTransition.content(reduceMotion: reduceMotion))

            case .connecting(let label) where isReading:
                VStack(spacing: FormaSpacing.sm) {
                    RecordStageTracker(measurement: measurement)
                    Text(connectingGuidance(for: label))
                        .font(FormaTypography.textStyle(.caption))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .transition(FormaTransition.fade)

            case .weight, .impedance, .heartRate:
                if isReading {
                    VStack(spacing: FormaSpacing.sm) {
                        RecordStageTracker(measurement: measurement)
                        Text("Stay still on the scale. Tap the circle to cancel.")
                            .font(FormaTypography.textStyle(.caption))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .transition(FormaTransition.fade)
                } else {
                    Text(state.actionGuidance)
                        .font(FormaTypography.textStyle(.caption, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

            case .saved:
                RecordMeasurementSummary(measurement: measurement)
                    .transition(
                        reduceMotion
                            ? FormaTransition.fade
                            : .asymmetric(
                                insertion: .scale(scale: 0.94).combined(with: .opacity).combined(with: .offset(y: 10)),
                                removal: .opacity
                            )
                    )

            case .ready:
                Text(state.actionGuidance)
                    .font(FormaTypography.textStyle(.subheadline, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .transition(FormaTransition.fade)

            case .connecting:
                Text(state.actionGuidance)
                    .font(FormaTypography.textStyle(.caption, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minHeight: 60, alignment: .top)
        .animation(
            FormaMotion.preferred(
                isSavedState ? FormaMotion.successSoft : FormaMotion.standard,
                reduceMotion: reduceMotion
            ),
            value: state
        )
        .accessibilityIdentifier(state.accessibilityIdentifier)
    }

    private var isSavedState: Bool {
        if case .saved = state { return true }
        return false
    }

    private func connectingGuidance(for label: String) -> String {
        switch label {
        case "Turn on Bluetooth":
            return "Enable Bluetooth in Control Center, then keep Forma open."
        case "Finding your scale":
            return "Wake the scale and keep your phone nearby. Tap the circle to cancel."
        case "Step on your scale":
            return "Step on barefoot and remain still. Tap the circle to cancel."
        default:
            return "Keep your phone near the scale. Tap the circle to cancel."
        }
    }

    private func recoveryGuidance(for message: String) -> String {
        let normalized = message.lowercased()
        if normalized.contains("bluetooth") {
            return "Turn on Bluetooth, keep your phone nearby, and wake the scale."
        }
        if normalized.contains("scale") || normalized.contains("connect") {
            return "Wake the scale and try again with your phone nearby."
        }
        if normalized.contains("complete") {
            return "Stay on the scale until weight, impedance, and heart rate are all captured."
        }
        return "Check the scale, keep your phone nearby, and try once more."
    }
}

private extension RecordCircleState {
    var isFailure: Bool {
        switch self {
        case .recordingFailed, .submissionFailed:
            return true
        case .ready, .connecting, .weight, .impedance, .heartRate, .saved:
            return false
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .ready:
            return "record-state-ready"
        case .connecting:
            return "record-state-connecting"
        case .weight:
            return "record-state-weight"
        case .impedance:
            return "record-state-impedance"
        case .heartRate(_, let isSubmitting):
            return isSubmitting ? "record-state-submitting" : "record-state-heart-rate"
        case .saved:
            return "record-state-saved"
        case .recordingFailed:
            return "record-state-recording-failed"
        case .submissionFailed:
            return "record-state-submission-failed"
        }
    }

    var actionGuidance: String {
        switch self {
        case .ready:
            return "Tap the circle to begin"
        case .connecting, .weight, .impedance:
            return "Tap to cancel"
        case .heartRate(_, let isSubmitting):
            return isSubmitting ? "Saving your measurement…" : "Tap to cancel"
        case .saved:
            return "All set"
        case .recordingFailed:
            return "Tap the circle to try again"
        case .submissionFailed:
            return "Tap the circle to retry saving"
        }
    }
}

private struct RecordMeasurementSummary: View {
    let measurement: ScaleMeasurement
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false

    var body: some View {
        VStack(spacing: FormaSpacing.md) {
            Text("All set")
                .font(FormaTypography.supporting.weight(.semibold))
                .foregroundStyle(Color.formaPositive)
                .opacity(revealed ? 1 : 0)
                .offset(y: revealed ? 0 : 6)

            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: FormaSpacing.xs) {
                        summaryItems
                    }
                } else {
                    HStack(spacing: FormaSpacing.sm) {
                        summaryItems
                    }
                }
            }
            .scaleEffect(revealed ? 1 : 0.94)
            .opacity(revealed ? 1 : 0)

            Text("Closing…")
                .font(FormaTypography.micro)
                .foregroundStyle(.tertiary)
                .opacity(revealed ? 1 : 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
        .onAppear {
            guard !revealed else { return }
            if reduceMotion {
                revealed = true
            } else {
                withAnimation(FormaMotion.fast) {
                    revealed = true
                }
            }
        }
    }

    private var accessibilitySummary: String {
        var parts = ["All set"]
        if let weight = measurement.weightKg {
            parts.append(String(format: "%.1f kilograms", weight))
        }
        if let impedance = measurement.impedanceOhms {
            parts.append(String(format: "%.0f ohms", impedance))
        }
        if let heartRate = measurement.heartRate {
            parts.append("\(heartRate) beats per minute")
        }
        return parts.joined(separator: ", ")
    }

    @ViewBuilder
    private var summaryItems: some View {
        if let weight = measurement.weightKg {
            summaryChip(String(format: "%.1f kg", weight), label: "Weight", order: 0)
        }
        if let impedance = measurement.impedanceOhms {
            summaryChip(String(format: "%.0f Ω", impedance), label: "Impedance", order: 1)
        }
        if let heartRate = measurement.heartRate {
            summaryChip("\(heartRate) bpm", label: "Heart rate", order: 2)
        }
    }

    private func summaryChip(_ value: String, label: String, order: Int) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(FormaTypography.textStyle(.caption, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(.primary)
            Text(label)
                .font(FormaTypography.micro)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, FormaSpacing.sm)
        .padding(.vertical, FormaSpacing.xs)
        .background(
            Color.appTertiaryBackground.opacity(0.9),
            in: RoundedRectangle(cornerRadius: FormaRadius.badge, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: FormaRadius.badge, style: .continuous)
                .strokeBorder(Color.formaPositive.opacity(revealed ? 0.28 : 0), lineWidth: 1)
        }
        .scaleEffect(revealed ? 1 : 0.88)
        .opacity(revealed ? 1 : 0)
        .animation(
            FormaMotion.preferred(FormaMotion.successSoft.delay(0.06 + Double(order) * 0.05), reduceMotion: reduceMotion),
            value: revealed
        )
    }
}

/// Three-stage progress indicator for the measurement ritual.
private struct RecordStageTracker: View {
    let measurement: ScaleMeasurement

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var stages: [(title: String, isComplete: Bool)] {
        [
            ("Weight", measurement.weightKg != nil),
            ("Impedance", measurement.impedanceOhms != nil),
            ("Heart Rate", measurement.heartRate != nil)
        ]
    }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: FormaSpacing.xs) {
                    compactProgress
                    Text(accessibleProgressLabel)
                        .font(FormaTypography.textStyle(.caption, weight: .semibold))
                        .foregroundStyle(.primary)
                }
            } else {
                fullProgress
            }
        }
        .animation(
            FormaMotion.preferred(FormaMotion.selection, reduceMotion: reduceMotion),
            value: measurement
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Measurement progress")
        .accessibilityValue(accessibleProgressLabel)
    }

    private var fullProgress: some View {
        HStack(spacing: FormaSpacing.xs) {
            ForEach(0..<stages.count, id: \.self) { index in
                let stage = stages[index]
                let isActive = !stage.isComplete
                    && stages.prefix(index).allSatisfy { $0.isComplete }

                HStack(spacing: FormaSpacing.xs) {
                    ZStack {
                        Circle()
                            .fill(Color.appTertiaryBackground)
                            .frame(width: 20, height: 20)

                        if stage.isComplete {
                            Image(forma: "checkmark")
                                .resizable().scaledToFit().frame(width: 9, height: 9)
                                .foregroundStyle(Color.formaPositive)
                                .transition(reduceMotion ? .identity : .scale.combined(with: .opacity))
                        } else if isActive {
                            Circle()
                                .fill(Color.sleekAccent)
                                .frame(width: 6, height: 6)
                        }
                    }

                    Text(stage.title)
                        .font(FormaTypography.textStyle(.caption2, weight: stage.isComplete || isActive ? .semibold : .medium))
                        .foregroundStyle(stage.isComplete || isActive ? .primary : .secondary)
                }

                if index < stages.count - 1 {
                    Capsule()
                        .fill(stage.isComplete ? Color.formaPositive.opacity(0.65) : Color.appTertiaryBackground)
                        .frame(maxWidth: 24)
                        .frame(height: 2)
                }
            }
        }
    }

    private var compactProgress: some View {
        HStack(spacing: FormaSpacing.xs) {
            ForEach(0..<stages.count, id: \.self) { index in
                let stage = stages[index]
                let isActive = !stage.isComplete
                    && stages.prefix(index).allSatisfy { $0.isComplete }

                Image(forma: stage.isComplete ? "checkmark.circle.fill" : "\(index + 1).circle.fill")
                    .foregroundStyle(
                        stage.isComplete
                            ? Color.formaPositive
                            : (isActive ? Color.sleekAccent : Color.secondary)
                    )

                if index < stages.count - 1 {
                    Capsule()
                        .fill(stage.isComplete ? Color.formaPositive.opacity(0.65) : Color.appTertiaryBackground)
                        .frame(width: 24, height: 2)
                }
            }
        }
    }

    private var accessibleProgressLabel: String {
        let completedCount = stages.filter(\.isComplete).count
        if completedCount == stages.count {
            return "All three stages complete"
        }

        let activeStage = stages.first(where: { !$0.isComplete })?.title ?? "Complete"
        return "\(completedCount) of \(stages.count) complete. Current stage: \(activeStage)"
    }
}

/// Solid high-contrast recording control.
private struct ReadyRecordPalette: View {
    let diameter: CGFloat
    var body: some View {
        Circle().fill(Color.actionInk)
            .frame(width: diameter, height: diameter)
            .accessibilityHidden(true)
    }
}

private struct ReadyRecordLabel: View {
    var body: some View {
        Text("Record")
            .font(FormaTypography.system(size: 22, weight: .bold))
            .foregroundStyle(Color.actionForeground)
    }
}

#Preview("Record") {
    RecordCircle(state: .ready, diameter: 240, isEnabled: true, showsActivityRing: false, action: {})
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FormaBackground())
}

#Preview("Record — Ready palette") {
    ReadyRecordPalette(diameter: 240)
        .overlay {
            ReadyRecordLabel()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FormaBackground())
}

#Preview("Record header button") {
    // Header + is intentionally quiet glass — idle energy lives on the big Record disc.
    Button(action: {}) {
        Image(forma: "plus")
            .resizable().scaledToFit().frame(width: 15, height: 15)
            .frame(width: 36, height: 36)
    }
    .buttonStyle(FormaIconButtonStyle())
    .buttonBorderShape(.circle)
    .controlSize(.regular)
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
