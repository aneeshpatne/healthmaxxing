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
    @StateObject private var reportStore = MetricsReportStore()
    @EnvironmentObject private var soundPlayer: FormaSoundPlayer

    var body: some View {
        NavigationStack {
            TabView(selection: $activeTab) {
                Tab("Metrics", systemImage: "chart.xyaxis.line", value: .metrics) {
                    MetricsView(
                        selectedTab: $selectedMetricsTab,
                        isAtTop: $isMetricsAtTop,
                        reportStore: reportStore
                    )
                }

                Tab("Workouts", systemImage: "figure.strengthtraining.traditional", value: .workouts) {
                    WorkoutsView()
                }

                Tab("Record", systemImage: "record.circle", value: .record) {
                    RecordView(reportStore: reportStore)
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
                        FormaBrandLockup(variant: .header, wordmarkColor: .white)
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
            .task(id: activeTab) {
                guard activeTab == .metrics else { return }
                await reportStore.loadAndPollReport()
            }
            .onChange(of: activeTab) { _, _ in
                soundPlayer.play(FormaUIFeedback.selection)
            }
            .sensoryFeedback(FormaUIFeedback.selection.sensoryFeedback, trigger: activeTab)
        }
    }
}

enum FormaLayout {
    static let floatingSettingsClearance: CGFloat = 60
}

struct FloatingSettingsButton: View {
    @State private var openFeedbackNonce = 0
    @EnvironmentObject private var soundPlayer: FormaSoundPlayer

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
        .simultaneousGesture(
            TapGesture().onEnded {
                openFeedbackNonce += 1
                soundPlayer.play(FormaUIFeedback.softImpact)
            }
        )
        .sensoryFeedback(FormaUIFeedback.softImpact.sensoryFeedback, trigger: openFeedbackNonce)
    }
}

#Preview {
    SwiftUIView()
        .environmentObject(FormaSoundPlayer())
}
