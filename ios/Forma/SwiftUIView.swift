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
            MetricsView(selectedTab: $selectedMetricsTab)
                .safeAreaPadding(.top, headerHeight + glassTabBarHeight)
                .overlay(alignment: .top) {
                    GlassTabBar(selectedTab: $selectedMetricsTab)
                        .padding(.top, headerHeight)
                }
                .ignoresSafeArea(.container, edges: .top)
                .tabItem {
                    Image(systemName: "chart.xyaxis.line")
                    Text("Metrics")
                }

            WorkoutsView()
                .ignoresSafeArea(.container, edges: .top)
                .tabItem {
                    Image(systemName: "figure.strengthtraining.traditional")
                    Text("Workouts")
                }

            RecordView()
                .ignoresSafeArea(.container, edges: .top)
                .tabItem {
                    Image(systemName: "record.circle")
                    Text("Record")
                }

            VitalsView()
                .ignoresSafeArea(.container, edges: .top)
                .tabItem {
                    Image(systemName: "heart.text.square")
                    Text("Vitals")
                }
        }
        .overlay(alignment: .top) {
            FormaHeader()
        }
    }
}

#Preview {
    SwiftUIView()
}
