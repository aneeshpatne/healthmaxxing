//
//  SwiftUIView.swift
//  Forma
//
//  Created by Aneesh Patne on 19/06/26.
//

import SwiftUI

enum AppTab: String {
    case metrics
    case workouts
    case record
    case vitals
}

struct SwiftUIView: View {
    @State private var activeTab: AppTab = .metrics
    @State private var selectedMetricsTab: MetricsTab = .insights
    @State private var isMetricsAtTop = true
    @StateObject private var reportStore: MetricsReportStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init() {
        let reportStore = MetricsReportStore()

        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let markerIndex = arguments.firstIndex(of: "-FormaUITestTab"),
           arguments.indices.contains(markerIndex + 1),
           let requestedTab = AppTab(rawValue: arguments[markerIndex + 1]) {
            _activeTab = State(initialValue: requestedTab)
        }

        if let markerIndex = arguments.firstIndex(of: "-FormaUITestScenario"),
           arguments.indices.contains(markerIndex + 1),
           let scenario = FormaUITestScenario(rawValue: arguments[markerIndex + 1]) {
            reportStore.applyDebugScenario(scenario)
        }
        #endif

        _reportStore = StateObject(wrappedValue: reportStore)
    }

    private var isUITestShell: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-FormaUITestShell")
        #else
        false
        #endif
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $activeTab) {
                Tab("Metrics", systemImage: "chart.xyaxis.line", value: .metrics) {
                    MetricsView(
                        selectedTab: $selectedMetricsTab,
                        isAtTop: $isMetricsAtTop,
                        reportStore: reportStore,
                        onRecordRequested: {
                            // System tab changes are immediate — no spring morph.
                            activeTab = .record
                        }
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
            .tint(.sleekAccent)
            .background(FormaBackground())
            .overlay(alignment: .top) {
                HStack {
                    if activeTab != .metrics || isMetricsAtTop {
                        FormaBrandLockup(variant: .header, wordmarkColor: .primary)
                            .transition(FormaTransition.fade)
                    }

                    Spacer(minLength: 0)

                    FloatingSettingsButton()
                }
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, FormaSpacing.screenGutter)
                .safeAreaPadding(.top, FormaSpacing.xs)
                .animation(
                    FormaMotion.preferred(FormaMotion.fast, reduceMotion: reduceMotion),
                    value: activeTab != .metrics || isMetricsAtTop
                )
            }
            .task(id: activeTab) {
                guard activeTab == .metrics, !isUITestShell else { return }
                await reportStore.loadAndPollReport()
            }
            .formaFeedback(.selection, trigger: activeTab)
        }
    }
}

enum FormaLayout {
    static let floatingSettingsClearance: CGFloat = 60
}

struct FloatingSettingsButton: View {
    @State private var openFeedbackNonce = 0

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
            }
        )
        .formaFeedback(.softImpact, trigger: openFeedbackNonce)
    }
}

#Preview {
    SwiftUIView()
        .environmentObject(FormaSoundPlayer())
}
