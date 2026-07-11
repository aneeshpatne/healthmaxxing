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
            VStack(alignment: .leading, spacing: 20) {
                DeviceStatusCard(
                    state: scaleManager.state,
                    measurement: scaleManager.latestMeasurement
                )

                MetricCardsSection(measurement: scaleManager.latestMeasurement)

                VStack(alignment: .leading, spacing: 12) {
                    LiquidGlassButton(
                        state: currentButtonState,
                        readingStatusLabel: scaleManager.state.label,
                        action: handleMainButtonAction
                    )

                    if let submissionStatus, currentButtonState == .queued {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(submissionStatus)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 6)
                    }

                    if let latestReportJobId, currentButtonState == .queued {
                        Text("Job ID: \(latestReportJobId.uuidString)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .padding(.horizontal, 6)
                    }

                    if let activeErrorMessage {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(activeErrorMessage)
                                .font(.subheadline)
                                .foregroundStyle(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .contentMargins(.top, FormaLayout.floatingSettingsClearance, for: .scrollContent)
        .background(Color.appBackground.ignoresSafeArea())
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

// MARK: - Device Status Card

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
        .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
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
        .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
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
        .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.appSeparator, lineWidth: 1)
        )
    }
}

// MARK: - Liquid Glass Action Button

private struct LiquidGlassButton: View {
    let state: RecordView.MainButtonState
    let readingStatusLabel: String
    let action: () -> Void

    var body: some View {
        if #available(iOS 26.0, *) {
            nativeGlassButton
        } else {
            fallbackGlassButton
        }
    }

    @available(iOS 26.0, *)
    private var nativeGlassButton: some View {
        Button(action: action) {
            buttonContent
                .frame(maxWidth: .infinity, minHeight: 58)
                .padding(.horizontal, 18)
                .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.roundedRectangle(radius: 24))
        .controlSize(.large)
        .tint(tintColor)
        .disabled(isDisabled)
    }

    private var fallbackGlassButton: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(baseGradient)

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.32),
                                Color.white.opacity(0.12),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.52),
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )

                HStack(spacing: 10) {
                    buttonContent
                }
                .padding(.horizontal, 18)
            }
            .frame(maxWidth: .infinity, minHeight: 58)
            .shadow(color: glowColor, radius: 10, x: 0, y: 5)
        }
        .disabled(isDisabled)
        .buttonStyle(ScaleButtonStyle())
    }

    private var buttonContent: some View {
        HStack(spacing: 10) {
            iconView
                .frame(width: 26, height: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(mainTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)

                if let subtitle = subtitleText {
                    Text(subtitle)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            rightIndicator
        }
    }

    private var mainTitle: String {
        switch state {
        case .ready:
            return "Start Measurement"
        case .reading:
            return readingStatusLabel.isEmpty ? "Searching for scale..." : readingStatusLabel
        case .submitting:
            return "Saving Measurement..."
        case .queued:
            return "Measurement Queued"
        case .failed:
            return "Retry Measurement"
        }
    }

    private var subtitleText: String? {
        switch state {
        case .ready:
            return "Tap to connect"
        case .reading:
            return "Tap to cancel"
        case .submitting:
            return "Processing report"
        case .queued:
            return "Saved to your profile"
        case .failed:
            return "Tap to try again"
        }
    }

    @ViewBuilder
    private var iconView: some View {
        switch state {
        case .ready:
            Image(systemName: "play.fill")
                .font(.headline)
                .foregroundStyle(.white)
        case .reading:
            ProgressView()
                .tint(.white)
        case .submitting:
            ProgressView()
                .tint(.white)
        case .queued:
            Image(systemName: "checkmark.circle.fill")
                .font(.headline)
                .foregroundStyle(.white)
        case .failed:
            Image(systemName: "arrow.clockwise")
                .font(.headline)
                .foregroundStyle(.white)
        }
    }

    @ViewBuilder
    private var rightIndicator: some View {
        switch state {
        case .ready, .failed:
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.85))

        case .reading:
            HStack(spacing: 5) {
                Image(systemName: "xmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                Text("Cancel")
                    .font(.subheadline.weight(.bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.18), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.24), lineWidth: 1)
            )

        case .submitting:
            EmptyView()

        case .queued:
            Image(systemName: "lock.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.6))
        }
    }

    private var baseGradient: LinearGradient {
        switch state {
        case .ready:
            return LinearGradient(
                colors: [
                    Color(red: 0.55, green: 0.45, blue: 1.0).opacity(0.95),
                    Color(red: 0.24, green: 0.48, blue: 0.95).opacity(0.95)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

        case .reading:
            return LinearGradient(
                colors: [
                    Color(red: 0.90, green: 0.26, blue: 0.32).opacity(0.95),
                    Color(red: 0.72, green: 0.14, blue: 0.22).opacity(0.95)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

        case .submitting:
            return LinearGradient(
                colors: [
                    Color(red: 0.45, green: 0.36, blue: 0.88).opacity(0.9),
                    Color(red: 0.25, green: 0.42, blue: 0.85).opacity(0.9)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

        case .queued:
            return LinearGradient(
                colors: [
                    Color.gray.opacity(0.28),
                    Color.gray.opacity(0.2)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

        case .failed:
            return LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.48, blue: 0.18).opacity(0.95),
                    Color(red: 0.85, green: 0.28, blue: 0.25).opacity(0.95)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    private var tintColor: Color {
        switch state {
        case .ready:
            return Color.sleekAccent
        case .reading:
            return .red
        case .submitting:
            return .indigo
        case .queued:
            return .gray
        case .failed:
            return .orange
        }
    }

    private var glowColor: Color {
        switch state {
        case .ready:
            return Color(red: 0.40, green: 0.34, blue: 0.90).opacity(0.28)
        case .reading:
            return Color.red.opacity(0.3)
        case .submitting:
            return Color.indigo.opacity(0.24)
        case .queued:
            return Color.clear
        case .failed:
            return Color.orange.opacity(0.28)
        }
    }

    private var isDisabled: Bool {
        switch state {
        case .submitting, .queued:
            return true
        case .ready, .reading, .failed:
            return false
        }
    }
}

// MARK: - Button Press Animation Style

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
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
                        colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.4)],
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
