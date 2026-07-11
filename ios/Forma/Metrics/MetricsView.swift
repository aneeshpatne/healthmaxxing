//
//  MetricsView.swift
//  Forma
//
//  Created by Aneesh Patne on 19/06/26.
//

import SwiftUI

let glassTabBarHeight: CGFloat = 52

struct MetricsView: View {
    @Binding var selectedTab: MetricsTab
    @Binding var isHeaderCollapsed: Bool
    @StateObject private var reportStore = MetricsReportStore()

    var body: some View {
        ScrollView(showsIndicators: false) {
            GeometryReader { proxy in
                Color.clear
                    .preference(
                        key: MetricsScrollOffsetKey.self,
                        value: proxy.frame(in: .named("metricsScroll")).minY
                    )
            }
            .frame(height: 0)

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
        .task {
            await reportStore.loadAndPollReport()
        }
        .coordinateSpace(name: "metricsScroll")
        .onPreferenceChange(MetricsScrollOffsetKey.self) { offset in
            let shouldCollapse = offset < -24
            guard shouldCollapse != isHeaderCollapsed else { return }

            withAnimation(.easeInOut(duration: 0.22)) {
                isHeaderCollapsed = shouldCollapse
            }
        }
        .safeAreaPadding(
            .top,
            (isHeaderCollapsed ? collapsedHeaderHeight : headerHeight) + glassTabBarHeight
        )
        .scrollEdgeEffectStyle(.hard, for: .top)
        .background(Color.appBackground.ignoresSafeArea())
    }
}

private struct MetricsScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
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
        .background(Color.appTertiaryBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
    let isCollapsed: Bool

    var body: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                ForEach(MetricsTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            selectedTab = tab
                        }
                    } label: {
                        Text(tab.title)
                            .font(.subheadline.weight(selectedTab == tab ? .semibold : .medium))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .frame(minWidth: 58)
                            .frame(minHeight: isCollapsed ? 42 : 48)
                            .padding(.horizontal, 8)
                            .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                    }
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                    .accessibilityValue(selectedTab == tab ? "Selected" : "")
                    .glassEffect(
                        selectedTab == tab
                            ? .regular.tint(.accentColor.opacity(0.3)).interactive()
                            : .regular
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, isCollapsed ? 4 : 8)
        }
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
            RoundedRectangle(cornerRadius: 10, style: .continuous)
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
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.secondary.opacity(0.05))
                .frame(height: 150)
            
            // Separator
            Rectangle()
                .fill(Color.appSeparator)
                .frame(height: 1)
            
            // Bottom Row
            SkeletonRow()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.appSecondaryBackground)
                .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.appSeparator, lineWidth: 0.5)
        )
        .padding(.horizontal, 16)
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .modifier(AnimatedShimmerModifier(phase: phase))
            .onAppear {
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
        isHeaderCollapsed: .constant(false)
    )
        .background(Color.appBackground)
}
