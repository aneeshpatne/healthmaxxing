//
//  RecordView.swift
//  Forma
//
//  Created by Aneesh Patne on 19/06/26.
//

import SwiftUI

struct RecordView: View {
    @StateObject private var scaleManager = ScaleBLEManager()

    @State private var isSubmittingMeasurement = false
    @State private var submissionStatus: String?
    @State private var submissionError: String?
    @State private var latestReportJobId: UUID?
    @State private var submittedMeasurement: ScaleMeasurement?

    private let apiClient = APIClient()

    fileprivate enum MainButtonState {
        case ready
        case reading
        case submitting
        case queued
        case failed
    }

    private var currentButtonState: MainButtonState {
        if isSubmittingMeasurement {
            return .submitting
        }

        if scaleManager.isReading {
            return .reading
        }

        if submissionError != nil {
            return .failed
        }

        if case .failed = scaleManager.state {
            return .failed
        }

        if let submitted = submittedMeasurement, submitted == scaleManager.latestMeasurement {
            return .queued
        }

        if scaleManager.state == .finished && submissionStatus != nil && submissionError == nil {
            return .queued
        }

        return .ready
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FormaSpacing.sectionGap) {
                LiveMeasurementHero(
                    state: scaleManager.state,
                    measurement: scaleManager.latestMeasurement,
                    submissionState: currentButtonState,
                    errorMessage: activeErrorMessage
                )

                if let submissionStatus, currentButtonState == .queued {
                    Label(submissionStatus, systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, FormaSpacing.xxs)
                }
            }
            .padding(.horizontal, FormaSpacing.screenGutter)
            .padding(.vertical, FormaSpacing.md)
            .padding(.bottom, 92)
        }
        .contentMargins(.top, FormaLayout.floatingSettingsClearance, for: .scrollContent)
        .background(FormaBackground())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MeasurementActionBar(
                state: currentButtonState,
                readingStatusLabel: scaleManager.state.label,
                action: handleMainButtonAction
            )
        }
        .onChange(of: scaleManager.state) { _, state in
            guard state == .finished else { return }

            Task {
                await submitLatestMeasurement()
            }
        }
    }

    private var activeErrorMessage: String? {
        if let submissionError {
            return submissionError
        }
        if case .failed(let message) = scaleManager.state {
            return message
        }
        return nil
    }

    private func handleMainButtonAction() {
        switch currentButtonState {
        case .ready:
            submissionError = nil
            submissionStatus = nil
            submittedMeasurement = nil
            scaleManager.startReading()

        case .reading:
            scaleManager.stopReading()

        case .failed:
            submissionError = nil
            if scaleManager.latestMeasurement.isFinal && canSubmitMeasurement(scaleManager.latestMeasurement) && submittedMeasurement != scaleManager.latestMeasurement {
                Task {
                    await submitLatestMeasurement()
                }
            } else {
                submittedMeasurement = nil
                scaleManager.startReading()
            }

        case .submitting, .queued:
            break
        }
    }

    private func canSubmitMeasurement(_ measurement: ScaleMeasurement) -> Bool {
        measurement.weightKg != nil && measurement.heartRate != nil && measurement.impedanceOhms != nil
    }

    @MainActor
    private func submitLatestMeasurement() async {
        let measurement = scaleManager.latestMeasurement

        guard submittedMeasurement != measurement else {
            return
        }

        guard !isSubmittingMeasurement else {
            return
        }

        guard let profileId = PrimaryProfileStore.primaryProfileId else {
            submissionStatus = nil
            submissionError = "Create or select a primary profile before saving measurements."
            return
        }

        guard let weight = measurement.weightKg,
              let heartbeat = measurement.heartRate,
              let impedance = measurement.impedanceOhms else {
            submissionStatus = nil
            submissionError = "A complete scale reading is required before saving."
            return
        }

        await submitMeasurement(
            weight: Double(weight),
            heartbeat: heartbeat,
            impedance: Double(impedance),
            successStatusPrefix: "Report"
        ) {
            submittedMeasurement = measurement
        }
    }

    @MainActor
    private func submitMeasurement(
        weight: Double,
        heartbeat: Int,
        impedance: Double,
        successStatusPrefix: String,
        afterSuccess: (() -> Void)? = nil
    ) async {
        guard !isSubmittingMeasurement else {
            return
        }

        guard let profileId = PrimaryProfileStore.primaryProfileId else {
            submissionStatus = nil
            submissionError = "Create or select a primary profile before saving measurements."
            return
        }

        isSubmittingMeasurement = true
        submissionStatus = "Saving measurement"
        submissionError = nil
        latestReportJobId = nil

        defer {
            isSubmittingMeasurement = false
        }

        do {
            let body = AddMeasurementBody(
                profileId: profileId,
                weight: weight,
                heartbeat: heartbeat,
                impedance: impedance
            )

            let response = try await apiClient.send(AddMeasurementRequest(body: body))
            afterSuccess?()
            latestReportJobId = response.jobId
            InsightReportJobStore.add(response.jobId, for: profileId)
            submissionStatus = "\(successStatusPrefix) \(response.reportStatus)"
        } catch APIError.missingAuthToken {
            submissionError = "Missing auth token."
            submissionStatus = nil
        } catch APIError.serverError(let statusCode, let responseBody) {
            submissionError = Self.serverErrorMessage(statusCode: statusCode, responseBody: responseBody)
            submissionStatus = nil
        } catch {
            if (error as? URLError)?.code == .cancelled || error is CancellationError {
                return
            }

            submissionError = "Failed to save measurement."
            submissionStatus = nil
        }
    }

    private static func serverErrorMessage(statusCode: Int, responseBody: String?) -> String {
        let trimmedBody = responseBody?.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let trimmedBody, !trimmedBody.isEmpty else {
            return "Server returned \(statusCode)."
        }

        return "Server returned \(statusCode): \(trimmedBody)"
    }
}

// MARK: - Live measurement presentation

private struct LiveMeasurementHero: View {
    let state: ScaleConnectionState
    let measurement: ScaleMeasurement
    let submissionState: RecordView.MainButtonState
    let errorMessage: String?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var accent: Color {
        switch submissionState {
        case .queued: .green
        case .failed: .red
        case .reading: .formaTeal
        case .ready, .submitting: .sleekAccent
        }
    }

    private var stateTitle: String {
        switch submissionState {
        case .ready: "Ready to measure"
        case .reading: state.label
        case .submitting: "Saving measurement"
        case .queued: "Measurement saved"
        case .failed: "Measurement interrupted"
        }
    }

    private var instruction: String {
        switch submissionState {
        case .ready: "Step onto your Forma scale and remain still while the reading settles."
        case .reading: "Stay balanced. Your live measurements will appear as the scale sends them."
        case .submitting: "Your reading is complete and is being added to your profile."
        case .queued: "Your latest reading is ready for the next report."
        case .failed: errorMessage ?? "Check Bluetooth and try the measurement again."
        }
    }

    var body: some View {
        VStack(spacing: FormaSpacing.xl) {
            HStack(spacing: FormaSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: statusIcon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("FORMA SCALE")
                        .font(FormaTypography.eyebrow)
                        .tracking(0.6)
                        .foregroundStyle(.tertiary)

                    HStack(spacing: FormaSpacing.xs) {
                        LiveStatusDot(color: accent, isActive: submissionState == .reading)
                        Text(stateTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                Text(connectionLabel)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(accent)
                    .padding(.horizontal, 9)
                    .frame(height: 26)
                    .background(accent.opacity(0.10), in: Capsule())
            }

            VStack(spacing: FormaSpacing.xs) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(measurement.weightKg.map { String(format: "%.1f", $0) } ?? "—")
                        .font(FormaTypography.heroMetric)
                        .contentTransition(.numericText())
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.72)

                    Text("kg")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Text(instruction)
                    .font(FormaTypography.body)
                    .foregroundStyle(errorMessage == nil ? Color.secondary : Color.red)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 290)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FormaSpacing.xs)

            HStack(spacing: FormaSpacing.sm) {
                SupportingMeasurement(
                    title: "Heart rate",
                    value: measurement.heartRate.map(String.init) ?? "—",
                    unit: "bpm",
                    systemImage: "heart.fill",
                    tint: .formaCoral
                )

                SupportingMeasurement(
                    title: "Impedance",
                    value: measurement.impedanceOhms.map { String(format: "%.0f", $0) } ?? "—",
                    unit: "Ω",
                    systemImage: "waveform.path.ecg",
                    tint: .formaCyan
                )
            }
        }
        .padding(FormaSpacing.xl)
        .background {
            RoundedRectangle(cornerRadius: FormaRadius.hero, style: .continuous)
                .fill(Color.appSecondaryBackground)
                .overlay {
                    RadialGradient(
                        colors: [accent.opacity(0.13), .clear],
                        center: .topTrailing,
                        startRadius: 0,
                        endRadius: 260
                    )
                    .clipShape(RoundedRectangle(cornerRadius: FormaRadius.hero, style: .continuous))
                }
                .shadow(color: Color.cardShadow, radius: 20, x: 0, y: 10)
                .shadow(color: Color.contactShadow, radius: 3, x: 0, y: 1)
        }
        .overlay {
            RoundedRectangle(cornerRadius: FormaRadius.hero, style: .continuous)
                .strokeBorder(
                    LinearGradient(colors: [Color.appSurfaceHighlight, accent.opacity(0.12)], startPoint: .top, endPoint: .bottom),
                    lineWidth: 0.5
                )
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.24), value: submissionState)
        .accessibilityElement(children: .combine)
    }

    private var statusIcon: String {
        switch submissionState {
        case .ready: "scalemass.fill"
        case .reading: "antenna.radiowaves.left.and.right"
        case .submitting: "arrow.up.doc.fill"
        case .queued: "checkmark.circle.fill"
        case .failed: "exclamationmark.triangle.fill"
        }
    }

    private var connectionLabel: String {
        switch submissionState {
        case .ready: "BLE READY"
        case .reading: "LIVE"
        case .submitting: "SAVING"
        case .queued: "SAVED"
        case .failed: "RETRY"
        }
    }
}

private struct SupportingMeasurement: View {
    let title: String
    let value: String
    let unit: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: FormaSpacing.sm) {
            HStack {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
                Spacer(minLength: 0)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 25, weight: .semibold, design: .rounded))
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(unit)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .formaSurface(.inset, padding: FormaSpacing.md)
    }
}

private struct LiveStatusDot: View {
    let color: Color
    let isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        ZStack {
            if isActive && !reduceMotion {
                Circle()
                    .fill(color.opacity(0.28))
                    .frame(width: 8, height: 8)
                    .scaleEffect(pulse ? 2 : 1)
                    .opacity(pulse ? 0 : 0.8)
            }
            Circle().fill(color).frame(width: 7, height: 7)
        }
        .frame(width: 12, height: 12)
        .onAppear {
            guard isActive, !reduceMotion else { return }
            withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
    }
}

private struct MeasurementActionBar: View {
    let state: RecordView.MainButtonState
    let readingStatusLabel: String
    let action: () -> Void

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                nativeAction
            } else {
                fallbackAction
            }
        }
        .padding(.horizontal, FormaSpacing.screenGutter)
        .padding(.top, FormaSpacing.sm)
        .padding(.bottom, FormaSpacing.xs)
        .background {
            LinearGradient(
                colors: [.clear, Color.appBackground.opacity(0.94)],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        }
    }

    @available(iOS 26.0, *)
    @ViewBuilder
    private var nativeAction: some View {
        switch state {
        case .queued:
            statusContent(title: "Measurement saved", systemImage: "checkmark.circle.fill", tint: .green)
                .glassEffect(.regular, in: .rect(cornerRadius: FormaRadius.action))

        case .submitting:
            statusContent(title: "Saving measurement", showsProgress: true)
                .glassEffect(.regular, in: .rect(cornerRadius: FormaRadius.action))

        case .reading:
            Button(action: action) {
                actionLabel(title: "Stop measurement", systemImage: "stop.fill")
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.roundedRectangle(radius: FormaRadius.action))
            .tint(.red.opacity(0.18))
            .foregroundStyle(.red)
            .accessibilityHint(readingStatusLabel)

        case .ready, .failed:
            Button(action: action) {
                actionLabel(title: buttonTitle, systemImage: buttonIcon)
                    .foregroundStyle(Color.actionForeground)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.roundedRectangle(radius: FormaRadius.action))
            .tint(.actionInk)
        }
    }

    @ViewBuilder
    private var fallbackAction: some View {
        switch state {
        case .queued:
            statusContent(title: "Measurement saved", systemImage: "checkmark.circle.fill", tint: .green)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: FormaRadius.action, style: .continuous))

        case .submitting:
            statusContent(title: "Saving measurement", showsProgress: true)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: FormaRadius.action, style: .continuous))

        case .reading:
            Button(action: action) {
                actionLabel(title: "Stop measurement", systemImage: "stop.fill")
                    .foregroundStyle(.red)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: FormaRadius.action, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: FormaRadius.action, style: .continuous)
                            .stroke(Color.red.opacity(0.18), lineWidth: 0.5)
                    }
            }
            .buttonStyle(QuietActionButtonStyle())

        case .ready, .failed:
            Button(action: action) {
                actionLabel(title: buttonTitle, systemImage: buttonIcon)
                    .foregroundStyle(Color.actionForeground)
                    .background(Color.actionInk, in: RoundedRectangle(cornerRadius: FormaRadius.action, style: .continuous))
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: FormaRadius.action, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 0.5)
                    }
                    .shadow(color: Color.contactShadow, radius: 8, y: 4)
            }
            .buttonStyle(QuietActionButtonStyle())
        }
    }

    private func actionLabel(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 56)
            .padding(.horizontal, FormaSpacing.md)
            .contentShape(RoundedRectangle(cornerRadius: FormaRadius.action, style: .continuous))
    }

    private func statusContent(
        title: String,
        systemImage: String? = nil,
        tint: Color = .secondary,
        showsProgress: Bool = false
    ) -> some View {
        HStack(spacing: FormaSpacing.sm) {
            if showsProgress {
                ProgressView()
            } else if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
            }

            Text(title)
                .font(.headline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, minHeight: 56)
        .padding(.horizontal, FormaSpacing.md)
    }

    private var buttonTitle: String {
        switch state {
        case .ready: "Start measurement"
        case .reading: "Stop measurement"
        case .failed: "Try again"
        case .submitting: "Saving measurement"
        case .queued: "Measurement saved"
        }
    }

    private var buttonIcon: String {
        switch state {
        case .ready: "play.fill"
        case .reading: "stop.fill"
        case .failed: "arrow.clockwise"
        case .submitting: "arrow.up.doc.fill"
        case .queued: "checkmark.circle.fill"
        }
    }
}

// MARK: - Legacy presentation (retained temporarily for source compatibility)

private struct DeviceStatusCard: View {
    let state: ScaleConnectionState
    let measurement: ScaleMeasurement

    private var isConnected: Bool {
        switch state {
        case .connecting, .discoveringServices, .listening, .finished:
            return true
        default:
            return false
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: iconName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.sleekAccent)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Forma BLE Scale")
                        .font(.headline.weight(.semibold))

                    HStack(spacing: 4) {
                        Image(systemName: isConnected ? "bluetooth.fill" : "bluetooth")
                            .font(.system(size: 10, weight: .bold))
                        Text(isConnected ? "CONNECTED" : "BLE")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(isConnected ? Color.sleekAccent : Color.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        (isConnected ? Color.sleekAccent : Color.secondary).opacity(0.12),
                        in: Capsule()
                    )
                }

                HStack(spacing: 6) {
                    PulsingDot(color: statusDotColor)

                    Text(statusText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if state == .idle {
                    Text("Keep Bluetooth on and stand still while Forma reads the scale.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.appSeparator, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Forma BLE Scale")
        .accessibilityValue(statusText)
    }

    private var iconName: String {
        switch state {
        case .finished:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        case .waitingForBluetooth, .scanning, .connecting, .discoveringServices, .listening:
            return "antenna.radiowaves.left.and.right"
        case .idle:
            return "scalemass.fill"
        }
    }

    private var statusDotColor: Color {
        switch state {
        case .finished:
            return .green
        case .failed:
            return .red
        case .waitingForBluetooth, .scanning, .connecting, .discoveringServices, .listening:
            return Color.sleekAccent
        case .idle:
            return .green
        }
    }

    private var statusText: String {
        switch state {
        case .failed(let message):
            return message
        case .finished where measurement.weightKg == nil:
            return "Reading complete. No weight decoded."
        case .idle:
            return "Ready to measure"
        default:
            return state.label
        }
    }
}

// MARK: - Pulsing Status Dot

private struct PulsingDot: View {
    var color: Color = .green
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.35))
                .frame(width: 12, height: 12)
                .scaleEffect(isPulsing ? 1.6 : 1.0)
                .opacity(isPulsing ? 0.0 : 0.8)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: false)) {
                        isPulsing = true
                    }
                }

            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
        }
    }
}

// MARK: - Metric Cards Section

private struct MetricCardsSection: View {
    let measurement: ScaleMeasurement

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                HalfMetricCard(
                    title: "Weight",
                    value: measurement.weightKg.map { String(format: "%.1f", $0) } ?? "--.-",
                    unit: "kg",
                    systemImage: "scalemass.fill",
                    accentColor: Color.sleekAccent
                )

                HalfMetricCard(
                    title: "Heart Rate",
                    value: measurement.heartRate.map(String.init) ?? "--",
                    unit: "bpm",
                    systemImage: "heart.fill",
                    accentColor: Color(red: 0.92, green: 0.25, blue: 0.55)
                )
            }

            FullBioDataCard(
                title: "Impedance",
                value: measurement.impedanceOhms.map { String(format: "%.0f", $0) } ?? "---",
                unit: "ohms",
                systemImage: "waveform.path.ecg",
                accentColor: Color(red: 0.15, green: 0.75, blue: 0.95)
            )
        }
    }
}

// MARK: - Metric Cards

private struct HalfMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let systemImage: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(accentColor)
                .frame(width: 28, height: 28, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 31, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(unit)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 122, alignment: .leading)
        .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.appSeparator, lineWidth: 1)
        )
    }
}

private struct FullBioDataCard: View {
    let title: String
    let value: String
    let unit: String
    let systemImage: String
    let accentColor: Color

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(accentColor)
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Spacer()
                }

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(value)
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(unit)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.appSeparator, lineWidth: 1)
        )
    }
}


private struct QuietActionButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.94 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

// MARK: - Wave Drawing Utilities

private struct SineWaveChart: View {
    let color: Color

    var body: some View {
        ZStack {
            SineWaveFillShape(amplitude: 10, frequency: 1.8)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.22), color.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            SineWaveShape(amplitude: 10, frequency: 1.8)
                .stroke(color.opacity(0.55), lineWidth: 1.5)
        }
    }
}

private struct MeshWaveChart: View {
    var body: some View {
        ZStack {
            SineWaveFillShape(amplitude: 14, frequency: 1.4)
                .fill(
                    LinearGradient(
                        colors: [Color.sleekAccent.opacity(0.2), Color.cyan.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            SineWaveShape(amplitude: 14, frequency: 1.4)
                .stroke(
                    LinearGradient(
                        colors: [Color.sleekAccent, Color.cyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )

            SineWaveShape(amplitude: 8, frequency: 2.6)
                .stroke(
                    LinearGradient(
                        colors: [Color.sleekAccent.opacity(0.55), Color.formaCyan.opacity(0.32)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1.2
                )
        }
    }
}

private struct SineWaveShape: Shape {
    var amplitude: CGFloat = 12
    var frequency: CGFloat = 2

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2

        path.move(to: CGPoint(x: 0, y: midY))

        for x in stride(from: 0, through: width, by: 2) {
            let relativeX = x / width
            let y = midY + sin(relativeX * .pi * frequency * 2) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}

private struct SineWaveFillShape: Shape {
    var amplitude: CGFloat = 12
    var frequency: CGFloat = 2

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height / 2

        path.move(to: CGPoint(x: 0, y: height))
        path.addLine(to: CGPoint(x: 0, y: midY))

        for x in stride(from: 0, through: width, by: 2) {
            let relativeX = x / width
            let y = midY + sin(relativeX * .pi * frequency * 2) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()
        return path
    }
}
