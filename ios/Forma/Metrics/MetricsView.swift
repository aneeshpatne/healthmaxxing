//
//  MetricsView.swift
//  Forma
//
//  Created by Aneesh Patne on 19/06/26.
//

import SwiftUI

struct MetricsView: View {
    @Binding var selectedTab: MetricsTab
    @Binding var isAtTop: Bool
    @ObservedObject var reportStore: MetricsReportStore
    var onRecordRequested: () -> Void = {}
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var pageAccent: Color {
        guard let payload = reportStore.payload else { return .formaAmber }

        switch selectedTab {
        case .insights:
            return payload.factor?.factorColor?.color ?? .formaAmber
        case .performance:
            return payload.performance["ffmi_gauge"]?.factorColor?.color ?? .sleekAccent
        case .fat:
            return payload.fat["fat_ratio"]?.factorColor?.color ?? .formaCoral
        case .muscle:
            return payload.muscle["skeletal_muscle_gauge"]?.factorColor?.color
                ?? ["muscle_mass", "bone_mass_trend", "muscle_ratio_trend", "skeletal_muscle_mass_trend"]
                    .compactMap { payload.muscle[$0]?.factorColor?.color }
                    .first
                ?? .formaTeal
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                MetricsTabBar(selectedTab: $selectedTab)
                    .padding(.horizontal, FormaSpacing.screenGutter)
                    .padding(.bottom, FormaSpacing.md)

                if reportStore.payload != nil,
                   reportStore.isWaitingForReport || reportStore.isLoading {
                    FormaRefreshStatus(
                        message: reportStore.statusMessage
                    )
                    .padding(.horizontal, FormaSpacing.screenGutter)
                    .padding(.bottom, FormaSpacing.md)
                    .transition(.opacity.combined(with: .offset(y: -6)))
                }

                // Tab body swaps without a parent animation transaction so Charts
                // don't interpolate on selection. Gauges still run their own
                // appear sweep via withAnimation inside FormaSemicircularGauge.
                Group {
                    if reportStore.payload == nil,
                       reportStore.isWaitingForReport || reportStore.isLoading {
                        MetricsSkeletonView(status: reportStore.statusMessage)
                    } else if reportStore.payload == nil,
                              let errorMessage = reportStore.errorMessage {
                        FormaStatusView(
                            title: "Report unavailable",
                            message: errorMessage,
                            systemImage: "exclamationmark.triangle.fill",
                            tint: .formaCoral,
                            actionTitle: "Try Again",
                            actionTint: .sleekAccent
                        ) {
                            Task {
                                await reportStore.refreshReport()
                            }
                        }
                    } else if let payload = reportStore.payload {
                        switch selectedTab {
                        case .insights:
                            InsightsTab(reportStore: reportStore)
                        case .performance:
                            PerformanceTab(payload: payload)
                        case .fat:
                            FatTab(payload: payload)
                        case .muscle:
                            MuscleTab(payload: payload)
                        }
                    } else {
                        FormaStatusView(
                            title: "No report yet",
                            message: "Record a measurement to generate your first report.",
                            systemImage: "doc.text.magnifyingglass",
                            tint: .sleekAccent,
                            actionTitle: "Record Measurement",
                            actionTint: .sleekAccent,
                            action: onRecordRequested
                        )
                        .formaEntrance()
                    }
                }
            }
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
            .background(alignment: .top) {
                // Keep the wash above the viewport during pull-to-refresh while
                // still letting it leave naturally when the page scrolls up.
                FormaAccentWash(accent: pageAccent, topExtension: 1_000)
                    .offset(y: -1_000)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.28), value: selectedTab)
            }
        }
        .refreshable {
            await reportStore.refreshReport()
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, offset in
            let shouldShowBrand = offset < 24
            guard shouldShowBrand != isAtTop else { return }

            if reduceMotion {
                isAtTop = shouldShowBrand
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    isAtTop = shouldShowBrand
                }
            }
        }
        .contentMargins(.top, FormaLayout.floatingSettingsClearance, for: .scrollContent)
        .background(FormaBackground())
        .animation(reduceMotion ? nil : FormaMotion.enter, value: reportStore.payload != nil)
        .animation(
            reduceMotion ? nil : FormaMotion.enter,
            value: reportStore.isWaitingForReport || reportStore.isLoading
        )
    }
}

struct MetricsUnavailableContent: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FormaSpacing.md)
        .background(Color.appTertiaryBackground, in: RoundedRectangle(cornerRadius: FormaRadius.inset, style: .continuous))
    }
}

enum MetricsTab: String, CaseIterable {
    case insights
    case performance
    case fat
    case muscle

    var title: String {
        rawValue.capitalized
    }
}

struct MetricsTabBar: View {
    @Binding var selectedTab: MetricsTab
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @EnvironmentObject private var soundPlayer: FormaSoundPlayer
    @Namespace private var selectionNamespace

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: FormaSpacing.xs) {
                        ForEach(MetricsTab.allCases, id: \.self) { tab in
                            tabButton(tab, expands: false)
                        }
                    }
                    .padding(.vertical, FormaSpacing.xxs)
                }
            } else {
                HStack(spacing: FormaSpacing.xs) {
                    ForEach(MetricsTab.allCases, id: \.self) { tab in
                        tabButton(tab, expands: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(alignment: .bottom) {
            Rectangle()
                .fill(Color.appSeparator)
                .frame(height: 0.5)
        }
        // Scope selection motion to the tab bar only — not the report body.
        .animation(reduceMotion ? nil : FormaMotion.selection, value: selectedTab)
        .sensoryFeedback(FormaUIFeedback.selection.sensoryFeedback, trigger: selectedTab)
    }

    private func tabButton(_ tab: MetricsTab, expands: Bool) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            // Assign without withAnimation so chart content never inherits the
            // selector's spring transaction.
            guard !isSelected else { return }
            selectedTab = tab
            soundPlayer.play(FormaUIFeedback.selection)
        } label: {
            VStack(spacing: 7) {
                Text(tab.title)
                    .font(.subheadline.weight(isSelected ? .semibold : .medium))
                    .lineLimit(1)
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)

                ZStack {
                    Capsule()
                        .fill(.clear)
                        .frame(height: 3)

                    if isSelected {
                        Capsule()
                            .fill(Color.sleekAccent)
                            .frame(width: 24, height: 3)
                            .matchedGeometryEffect(id: "metrics-selection", in: selectionNamespace)
                    }
                }
            }
            .padding(.horizontal, FormaSpacing.sm)
            .frame(maxWidth: expands ? .infinity : nil)
            .frame(minWidth: 64, minHeight: 48)
            .background(
                isSelected ? Color.sleekAccent.opacity(0.10) : Color.clear,
                in: RoundedRectangle(cornerRadius: FormaRadius.badge, style: .continuous)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(MetricTabButtonStyle())
        .accessibilityLabel(tab.title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct MetricTabButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(
                reduceMotion ? nil : .easeOut(duration: 0.12),
                value: configuration.isPressed
            )
    }
}

/// Skeleton stand-in for the report while it is being prepared.
struct MetricsSkeletonView: View {
    var status: String?

    var body: some View {
        VStack(spacing: FormaSpacing.cardGap) {
            if let status, !status.isEmpty {
                HStack(spacing: FormaSpacing.xs) {
                    Image(systemName: "sparkles")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.sleekAccent)

                    Text(status)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            FormaSkeletonCard(kind: .gauge)
            FormaSkeletonCard(kind: .narrative)
            FormaSkeletonCard(kind: .chart)
        }
        .padding(.horizontal, FormaSpacing.screenGutter)
        .padding(.top, FormaSpacing.xxs)
        .padding(.bottom, FormaSpacing.xl)
    }
}

#Preview {
    MetricsView(
        selectedTab: .constant(.insights),
        isAtTop: .constant(true),
        reportStore: MetricsReportStore()
    )
        .background(Color.appBackground)
        .environmentObject(FormaSoundPlayer())
}

#Preview("Report loading") {
    MetricsSkeletonView(status: "Preparing your report…")
        .background(FormaBackground(accent: .sleekAccent))
}
