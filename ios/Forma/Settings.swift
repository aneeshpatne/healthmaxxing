//
//  Settings.swift
//  Forma
//
//  Created by Aneesh Patne on 30/06/26.
//
import SwiftUI
import ClerkKit
import ClerkKitUI

struct Settings: View {
    let reportStore: MetricsReportStore

    @AppStorage(FormaFeedbackPreferences.soundEffectsKey) private var soundEffectsEnabled = true
    @AppStorage(FormaFeedbackPreferences.hapticsKey) private var hapticsEnabled = true
    @EnvironmentObject private var soundPlayer: FormaSoundPlayer
    @State private var isDebugRecordPresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FormaSpacing.sectionGap) {
                settingsSection("Profiles") {
                    settingsRow(
                        title: "Manage Profiles",
                        subtitle: "People, goals, and primary profile",
                        systemImage: "person.crop.circle",
                        tint: .secondary
                    ) {
                        Profiles()
                    }
                }

                settingsSection("Account") {
                    settingsRow(
                        title: "Account",
                        subtitle: "Identity and sign-in settings",
                        systemImage: "person.fill",
                        tint: .sleekAccent
                    ) {
                        UserProfileView()
                    }
                }

                settingsSection("Experience") {
                    VStack(spacing: FormaSpacing.md) {
                        experienceToggle(
                            title: "Sound Effects",
                            subtitle: "Soft cues for confirmations and milestones",
                            systemImage: "speaker.wave.2.fill",
                            tint: .secondary,
                            isOn: $soundEffectsEnabled
                        )

                        FormaDivider()

                        experienceToggle(
                            title: "Haptics",
                            subtitle: "Tactile feedback for actions and progress",
                            systemImage: "waveform.path",
                            tint: .secondary,
                            isOn: $hapticsEnabled
                        )
                    }
                }

                settingsSection("Debug") {
                    Button {
                        isDebugRecordPresented = true
                    } label: {
                        rowContent(
                            title: "Record Test Measurement",
                            subtitle: "76.6 kg · 574 Ω · 72 bpm",
                            systemImage: "waveform.path.ecg",
                            tint: .sleekAccent
                        )
                    }
                    .buttonStyle(FormaPressableButtonStyle())
                    .accessibilityIdentifier("debug-record-measurement")
                }

                settingsSection("About") {
                    HStack(spacing: FormaSpacing.sm) {
                        FormaIconTile(
                            systemImage: "app.badge",
                            tint: .secondary,
                            size: 34,
                            radius: 10
                        )

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Forma")
                                .font(FormaTypography.textStyle(.body, weight: .semibold))
                            Text("Version \(appVersion)")
                                .font(FormaTypography.textStyle(.caption))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, FormaSpacing.screenGutter)
            .padding(.vertical, FormaSpacing.lg)
        }
        .background(FormaBackground())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: soundEffectsEnabled) { wasEnabled, isEnabled in
            guard !wasEnabled, isEnabled else { return }
            soundPlayer.play(.confirm)
        }
        // Haptic only when enabling the preference itself — not on every row push.
        .formaFeedback(.softImpact, trigger: hapticsEnabled) { wasEnabled, isEnabled in
            !wasEnabled && isEnabled
        }
        .sheet(isPresented: $isDebugRecordPresented) {
            RecordView(
                reportStore: reportStore,
                debugMeasurement: ScaleMeasurement(
                    weightKg: 76.6,
                    heartRate: 72,
                    impedanceOhms: 574,
                    isFinal: true
                ),
                onSuccess: { isDebugRecordPresented = false }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(FormaRadius.card)
        }
    }

    private func settingsRow<Destination: View>(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            rowContent(title: title, subtitle: subtitle, systemImage: systemImage, tint: tint)
        }
        .buttonStyle(FormaPressableButtonStyle())
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        switch (version, build) {
        case let (.some(version), .some(build)):
            return "\(version) (\(build))"
        case let (.some(version), nil):
            return version
        default:
            return "Development"
        }
    }

    private func rowContent(title: String, subtitle: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: FormaSpacing.sm) {
            FormaIconTile(
                systemImage: systemImage,
                tint: tint,
                size: 34,
                radius: 10,
                symbolFont: FormaTypography.system(size: 14, weight: .semibold)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(FormaTypography.textStyle(.body, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(FormaTypography.supporting)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(FormaTypography.textStyle(.caption, weight: .bold))
                .foregroundStyle(.tertiary)
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }

    private func experienceToggle(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        isOn: Binding<Bool>
    ) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: FormaSpacing.sm) {
                FormaIconTile(
                    systemImage: systemImage,
                    tint: tint,
                    size: 34,
                    radius: 10,
                    symbolFont: FormaTypography.system(size: 14, weight: .semibold)
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(FormaTypography.textStyle(.body, weight: .semibold))
                    Text(subtitle)
                        .font(FormaTypography.supporting)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .tint(.sleekAccent)
        .frame(minHeight: 44)
    }

    private func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: FormaSpacing.xs) {
            Text(title)
                .font(FormaTypography.cardTitle)
                .foregroundStyle(.primary)
                .padding(.horizontal, FormaSpacing.xxs)

            content()
                .formaSurface(.card, padding: FormaSpacing.cardInset)
        }
    }
}

#Preview {
    Settings(reportStore: MetricsReportStore())
        .environmentObject(FormaSoundPlayer())
}
