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
                HStack {
                    if activeTab != .metrics || isMetricsAtTop {
                        FormaBrandLockup(variant: .header)
                            .transition(.opacity.combined(with: .offset(y: -4)))
                    }

                    Spacer(minLength: 0)

                    FloatingSettingsButton()
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, FormaSpacing.screenGutter)
                .safeAreaPadding(.top, FormaSpacing.xs)
                .animation(.easeOut(duration: 0.22), value: activeTab != .metrics || isMetricsAtTop)
            }
        }
    }
}

enum FormaLayout {
    static let floatingSettingsClearance: CGFloat = 60
}

struct FloatingSettingsButton: View {
    var body: some View {
        NavigationLink {
            Settings()
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 17, weight: .semibold))
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
