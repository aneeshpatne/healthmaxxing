//
//  SwiftUIView.swift
//  Forma
//
//  Created by Aneesh Patne on 19/06/26.
//

import SwiftUI

enum AppTab {
    case metrics
    case workouts
    case record
    case vitals
}

struct SwiftUIView: View {
    @State private var activeTab: AppTab = .metrics
    @State private var selectedMetricsTab: MetricsTab = .insights
    @State private var isMetricsAtTop = true

    var body: some View {
        NavigationStack {
            TabView(selection: $activeTab) {
                Tab("Metrics", systemImage: "chart.xyaxis.line", value: .metrics) {
                    MetricsView(
                        selectedTab: $selectedMetricsTab,
                        isAtTop: $isMetricsAtTop
                    )
                }

                Tab("Workouts", systemImage: "figure.strengthtraining.traditional", value: .workouts) {
                    WorkoutsView()
                }

                Tab("Record", systemImage: "record.circle", value: .record) {
                    RecordView()
                }

                Tab("Vitals", systemImage: "heart.text.square", value: .vitals) {
                    VitalsView()
                }
            }
            .tabBarMinimizeBehavior(.onScrollDown)
            .background(FormaBackground())
            .overlay(alignment: .top) {
                GlassEffectContainer(spacing: 12) {
                    HStack {
                        if activeTab != .metrics || isMetricsAtTop {
                            FormaBrandMark()
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }

                        Spacer(minLength: 0)

                        FloatingSettingsButton()
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, FormaSpacing.screenGutter)
                .safeAreaPadding(.top, FormaSpacing.xs)
                .animation(.easeOut(duration: 0.2), value: activeTab != .metrics || isMetricsAtTop)
            }
        }
    }
}

enum FormaLayout {
    static let floatingSettingsClearance: CGFloat = 60
}

struct FormaBrandMark: View {
    var body: some View {
        Text("Forma")
            .font(FormaTypography.wordmark)
            .tracking(-0.35)
            .foregroundStyle(.primary)
            .padding(.horizontal, FormaSpacing.sm)
            .frame(height: 44)
            .glassEffect(.regular, in: Capsule())
            .accessibilityLabel("Forma")
    }
}

struct FloatingSettingsButton: View {
    var body: some View {
        NavigationLink {
            Settings()
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.title3)
                .foregroundStyle(Color.primary)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .frame(width: 44, height: 44)
        .accessibilityLabel("Settings")
    }
}

#Preview {
    SwiftUIView()
}
