//
//  SwiftUIView.swift
//  Forma
//
//  Created by Aneesh Patne on 19/06/26.
//

import SwiftUI

enum AppTab: String {
    case metrics
    case record
    case settings
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

                Tab("Record", systemImage: "record.circle", value: .record) {
                    RecordView(reportStore: reportStore)
                }

                Tab("Settings", systemImage: "gearshape", value: .settings) {
                    Settings()
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
    static let topOverlayClearance: CGFloat = 60
}

#Preview {
    SwiftUIView()
        .environmentObject(FormaSoundPlayer())
}
