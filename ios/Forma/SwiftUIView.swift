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

    var body: some View {
        NavigationStack {
            TabView(selection: $activeTab) {
                Tab("Metrics", systemImage: "chart.xyaxis.line", value: .metrics) {
                    MetricsView(selectedTab: $selectedMetricsTab)
                        .safeAreaPadding(.top, headerHeight + glassTabBarHeight)
                        .ignoresSafeArea(.container, edges: .top)
                }

                Tab("Workouts", systemImage: "figure.strengthtraining.traditional", value: .workouts) {
                    WorkoutsView()
                        .ignoresSafeArea(.container, edges: .top)
                }

                Tab("Record", systemImage: "record.circle", value: .record) {
                    RecordView()
                        .ignoresSafeArea(.container, edges: .top)
                }

                Tab("Vitals", systemImage: "heart.text.square", value: .vitals) {
                    VitalsView()
                        .ignoresSafeArea(.container, edges: .top)
                }
            }
            .tabBarMinimizeBehavior(.onScrollDown)
            .background(Color.appBackground.ignoresSafeArea())
            .overlay(alignment: .top) {
                FormaHeader(activeTab: $activeTab, selectedMetricsTab: $selectedMetricsTab)
            }
        }
    }
}

#Preview {
    SwiftUIView()
}
