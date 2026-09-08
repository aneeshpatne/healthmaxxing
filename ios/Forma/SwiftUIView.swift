//
//  SwiftUIView.swift
//  Forma
//
//  Created by Aneesh Patne on 19/06/26.
//

import SwiftUI

enum AppTab: String {
    case metrics
    case food
    case settings
}

struct SwiftUIView: View {
    @State private var activeTab: AppTab = .metrics
    @State private var selectedMetricsTab: MetricsTab = .insights
    @State private var isMetricsAtTop = true
    @State private var isRecordPresented = false
    @StateObject private var reportStore: MetricsReportStore

    init() {
        let reportStore = MetricsReportStore()

        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let markerIndex = arguments.firstIndex(of: "-FormaUITestTab"),
           arguments.indices.contains(markerIndex + 1),
           let requestedTab = AppTab(rawValue: arguments[markerIndex + 1]) {
            _activeTab = State(initialValue: requestedTab)
        }

        // UI tests can open the record sheet directly (legacy tab name "record" still works).
        if arguments.contains("-FormaUITestRecordSheet") {
            _isRecordPresented = State(initialValue: true)
        } else if let markerIndex = arguments.firstIndex(of: "-FormaUITestTab"),
                  arguments.indices.contains(markerIndex + 1),
                  arguments[markerIndex + 1] == "record" {
            _isRecordPresented = State(initialValue: true)
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

    private var showsBrandLockup: Bool {
        activeTab != .metrics || isMetricsAtTop
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
                            isRecordPresented = true
                        }
                    )
                }

                Tab("Food", systemImage: "fork.knife", value: .food) {
                    FoodView()
                }

                Tab("Settings", systemImage: "gearshape", value: .settings) {
                    Settings(reportStore: reportStore)
                }
            }
            .tabBarMinimizeBehavior(.onScrollDown)
            .tint(.sleekAccent)
            .background(FormaBackground())
            .overlay(alignment: .top) {
                topChrome
            }
            .sheet(isPresented: $isRecordPresented) {
                RecordView(reportStore: reportStore) {
                    isRecordPresented = false
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(FormaRadius.card)
            }
            .task {
                guard !isUITestShell else { return }
                await reportStore.loadAndPollReport()
            }
            .formaFeedback(.selection, trigger: activeTab)
        }
    }

    private var topChrome: some View {
        HStack(alignment: .center, spacing: FormaSpacing.sm) {
            if showsBrandLockup {
                FormaBrandLockup(variant: .header, wordmarkColor: .primary)

                Spacer(minLength: 0)

                recordHeaderButton
            }
        }
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 44, alignment: .center)
        .padding(.horizontal, FormaSpacing.screenGutter)
        .safeAreaPadding(.top, FormaSpacing.xs)
    }

    private var recordHeaderButton: some View {
        Button {
            isRecordPresented = true
        } label: {
            Image(systemName: "plus")
                .font(FormaTypography.system(size: 15, weight: .semibold))
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .controlSize(.regular)
        .accessibilityIdentifier("header-record-button")
        .accessibilityLabel("Record measurement")
        .formaFeedback(.selection, trigger: isRecordPresented) { wasPresented, isPresented in
            !wasPresented && isPresented
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
