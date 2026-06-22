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
        TabView(selection: $activeTab) {
            Tab("Metrics", systemImage: "chart.xyaxis.line", value: .metrics) {
                MetricsView(selectedTab: $selectedMetricsTab)
                    .safeAreaPadding(.top, headerHeight + glassTabBarHeight)
                    .overlay(alignment: .top) {
                        GlassTabBar(selectedTab: $selectedMetricsTab)
                            .padding(.top, headerHeight)
                    }
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
        .overlay(alignment: .top) {
            FormaHeader()
        }
    }
}

#Preview {
    SwiftUIView()
}
