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

                Group {
                    if reportStore.isWaitingForReport || (reportStore.isLoading && reportStore.payload == nil) {
                        MetricsSkeletonView(status: reportStore.statusMessage)
                            .transition(FormaTransition.card)
                    } else if let errorMessage = reportStore.errorMessage {
                        FormaStatusView(
                            title: "Report unavailable",
                            message: errorMessage,
                            systemImage: "exclamationmark.triangle.fill",
                            tint: .formaCoral
                        )
                        .transition(FormaTransition.card)
                    } else if let payload = reportStore.payload {
                        switch selectedTab {
                        case .insights:
                            InsightsTab(reportStore: reportStore)
                                .transition(FormaTransition.card)
                        case .performance:
                            PerformanceTab(payload: payload)
                                .transition(FormaTransition.card)
                        case .fat:
                            FatTab(payload: payload)
                                .transition(FormaTransition.card)
                        case .muscle:
                            MuscleTab(payload: payload)
                                .transition(FormaTransition.card)
                        }
                    } else {
                        FormaStatusView(
                            title: "No report yet",
                            message: "Record a measurement to generate your first report.",
                            systemImage: "doc.text.magnifyingglass",
                            tint: .secondary
                        )
                        .transition(FormaTransition.card)
                    }
                }
            }
            .background(alignment: .top) {
                FormaAccentWash(accent: pageAccent)
                    .offset(y: -FormaLayout.floatingSettingsClearance)
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
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: selectedTab)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: reportStore.payload != nil)
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
    @Namespace private var selectionNamespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MetricsTab.allCases.indices, id: \.self) { index in
                let tab = MetricsTab.allCases[index]

                Button {
                    let update = {
                        selectedTab = tab
                    }

                    if reduceMotion {
                        update()
                    } else {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                            update()
                        }
                    }
                } label: {
                    VStack(spacing: 7) {
                        Text(tab.title)
                            .font(.subheadline.weight(selectedTab == tab ? .semibold : .medium))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .foregroundStyle(selectedTab == tab ? .primary : .secondary)

                        ZStack {
                            Capsule()
                                .fill(.clear)
                                .frame(height: 2)

                            if selectedTab == tab {
                                Capsule()
                                    .fill(Color.sleekAccent)
                                    .frame(width: 24, height: 2)
                                    .matchedGeometryEffect(id: "metrics-selection", in: selectionNamespace)
                            }
                        }
                    }
                    .padding(.horizontal, FormaSpacing.xxs)
                    .frame(minWidth: 44, minHeight: 48)
                    .contentShape(Rectangle())
                }
                .buttonStyle(MetricTabButtonStyle())
                .accessibilityValue(selectedTab == tab ? "Selected" : "")

                if index < MetricsTab.allCases.count - 1 {
                    Spacer(minLength: FormaSpacing.xxs)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(alignment: .bottom) {
            Rectangle()
                .fill(Color.appSeparator)
                .frame(height: 0.5)
        }
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

            FormaSkeletonCard()
            FormaSkeletonCard()
            FormaSkeletonCard()
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
}

#Preview("Report loading") {
    MetricsSkeletonView(status: "Preparing your report…")
        .background(FormaBackground(accent: .sleekAccent))
}
