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
    @StateObject private var reportStore = MetricsReportStore()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView(showsIndicators: false) {
            GlassTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, FormaSpacing.screenGutter)
                .padding(.bottom, FormaSpacing.md)

            Group {
                if reportStore.isLoading && reportStore.payload == nil {
                    MetricsReportStatusScreen(
                        title: "Preparing report",
                        message: reportStore.statusMessage,
                        isLoading: true
                    )
                } else if let payload = reportStore.payload {
                    switch selectedTab {
                    case .insights:
                        InsightsTab()
                    case .performance:
                        PerformanceTab(payload: payload)
                    case .fat:
                        FatTab(payload: payload)
                    case .muscle:
                        MuscleTab(payload: payload)
                    }
                } else if let errorMessage = reportStore.errorMessage {
                    MetricsReportStatusScreen(
                        title: "Report unavailable",
                        message: errorMessage,
                        systemImage: "exclamationmark.triangle.fill",
                        tint: .red
                    )
                } else {
                    MetricsReportStatusScreen(
                        title: "No report yet",
                        message: "Record a measurement to generate your first report.",
                        systemImage: "doc.text.magnifyingglass",
                        tint: .secondary
                    )
                }
            }
        }
        .task {
            await reportStore.loadAndPollReport()
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
    }
}

struct MetricsReportStatusScreen: View {
    let title: String
    let message: String
    var systemImage = "hourglass"
    var tint: Color = .accentColor
    var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.12))
                    .frame(width: 64, height: 64)

                if isLoading {
                    ProgressView()
                        .controlSize(.large)
                } else {
                    Image(systemName: systemImage)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(tint)
                }
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 80)
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
        .padding(16)
        .background(Color.appTertiaryBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
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

struct GlassTabBar: View {
    @Binding var selectedTab: MetricsTab
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                ForEach(MetricsTab.allCases, id: \.self) { tab in
                    Button {
                        let update = {
                            selectedTab = tab
                        }

                        if reduceMotion {
                            update()
                        } else {
                            withAnimation(.spring(response: 0.28, dampingFraction: 1.0)) {
                                update()
                            }
                        }
                    } label: {
                        Text(tab.title)
                            .font(.subheadline.weight(selectedTab == tab ? .semibold : .medium))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .frame(minWidth: 58)
                            .frame(minHeight: 48)
                            .padding(.horizontal, 8)
                            .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                    }
                    .contentShape(Rectangle())
                    .buttonStyle(MetricTabButtonStyle())
                    .accessibilityValue(selectedTab == tab ? "Selected" : "")
                    .glassEffect(
                        selectedTab == tab
                            ? .regular.tint(.accentColor.opacity(0.3)).interactive()
                            : .regular
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
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

struct MetricsSkeletonView: View {
    var body: some View {
        VStack(spacing: 20) {
            SkeletonCard()
            SkeletonCard()
            SkeletonCard()
        }
        .padding(.vertical, 16)
    }
}

struct SkeletonRow: View {
    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.secondary.opacity(0.12))
                .frame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.secondary.opacity(0.12))
                    .frame(width: 140, height: 16)
                
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.secondary.opacity(0.08))
                    .frame(width: 220, height: 12)
            }
            Spacer()
        }
        .shimmering()
    }
}

struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.secondary.opacity(0.15))
                    .frame(width: 160, height: 20)
                
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.secondary.opacity(0.08))
                    .frame(width: 240, height: 14)
            }
            
            // Visualization Area
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.secondary.opacity(0.05))
                .frame(height: 150)
            
            // Separator
            Rectangle()
                .fill(Color.appSeparator)
                .frame(height: 1)
            
            // Bottom Row
            SkeletonRow()
        }
        .formaSurface(.card, padding: FormaSpacing.cardInset)
        .padding(.horizontal, FormaSpacing.screenGutter)
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    func body(content: Content) -> some View {
        content
            .modifier(AnimatedShimmerModifier(phase: reduceMotion ? 0.5 : phase))
            .onAppear {
                guard !reduceMotion else { return }

                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

struct AnimatedShimmerModifier: AnimatableModifier {
    var phase: CGFloat
    
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    let w = geo.size.width
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.3),
                            .init(color: .white.opacity(0.3), location: 0.5),
                            .init(color: .clear, location: 0.7)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: w * 2)
                    .offset(x: -w + (w * 2 * phase))
                    .blendMode(.overlay)
                }
                .mask(content)
            )
    }
}

extension View {
    func shimmering() -> some View {
        self.modifier(ShimmerModifier())
    }
}

#Preview {
    MetricsView(
        selectedTab: .constant(.insights),
        isAtTop: .constant(true)
    )
        .background(Color.appBackground)
}
