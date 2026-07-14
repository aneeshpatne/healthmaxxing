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

    var body: some View {
        ScrollView(showsIndicators: false) {
            MetricsTabBar(selectedTab: $selectedTab)
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
                        InsightsTab(reportStore: reportStore)
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
            if isLoading {
                MetricsReportLoadingIndicator(tint: tint)
            } else {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.12))
                        .frame(width: 64, height: 64)

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

private struct MetricsReportLoadingIndicator: View {
    let tint: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let elapsed = context.date.timeIntervalSinceReferenceDate
            let progress = reduceMotion ? 0.1 : elapsed.truncatingRemainder(dividingBy: 3.2) / 3.2
            let breathe = reduceMotion ? 1.0 : 0.985 + (0.015 * sin(elapsed * .pi))

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [tint.opacity(0.18), tint.opacity(0.055)],
                            center: .center,
                            startRadius: 2,
                            endRadius: 48
                        )
                    )

                Circle()
                    .stroke(tint.opacity(0.14), lineWidth: 10)
                    .blur(radius: 8)
                    .padding(8)

                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [Color.appSeparator, tint.opacity(0.22), Color.appSeparator],
                            center: .center
                        ),
                        lineWidth: 1
                    )
                    .padding(4)

                Circle()
                    .trim(from: 0.03, to: 0.27)
                    .stroke(
                        AngularGradient(
                            colors: [tint.opacity(0.12), tint, Color.formaCyan, tint.opacity(0.12)],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                    )
                    .padding(4)
                    .rotationEffect(.degrees(progress * 360))

                Circle()
                    .trim(from: 0.54, to: 0.72)
                    .stroke(
                        LinearGradient(
                            colors: [Color.formaCyan.opacity(0.18), Color.formaCyan.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2.25, lineCap: .round)
                    )
                    .padding(14)
                    .rotationEffect(.degrees(-progress * 220))

                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(index == 0 ? tint : Color.formaCyan.opacity(0.7))
                        .frame(width: index == 0 ? 5 : 3.5, height: index == 0 ? 5 : 3.5)
                        .shadow(color: tint.opacity(0.7), radius: 4)
                        .offset(y: -42)
                        .rotationEffect(.degrees((progress * 360) + (Double(index) * 120)))
                }

                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)

                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.2), tint.opacity(0.16)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.75
                        )

                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(tint)
                }
                .frame(width: 48, height: 48)
                .shadow(color: Color.black.opacity(0.22), radius: 10, y: 5)
                .scaleEffect(breathe)
            }
        }
        .frame(width: 96, height: 96)
        .accessibilityHidden(true)
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
        isAtTop: .constant(true),
        reportStore: MetricsReportStore()
    )
        .background(Color.appBackground)
}

#Preview("Report loading") {
    MetricsReportStatusScreen(
        title: "Preparing report",
        message: "Waiting for report generation.",
        isLoading: true
    )
    .background(FormaBackground())
}
