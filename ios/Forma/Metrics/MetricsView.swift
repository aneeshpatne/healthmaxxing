//
//  MetricsView.swift
//  Forma
//
//  Created by Aneesh Patne on 19/06/26.
//

import SwiftUI

let glassTabBarHeight: CGFloat = 52

struct MetricsView: View {
    @Binding var selectedTab: MetricsTab
    @StateObject private var reportStore = MetricsReportStore()

    var body: some View {
        ScrollView {
            switch selectedTab {
            case .insights:
                InsightsTab()
            case .performance:
                PerformanceTab(payload: reportStore.payload)
            case .fat:
                FatTab(payload: reportStore.payload)
            case .muscle:
                MuscleTab(payload: reportStore.payload)
            }
        }
        .task {
            await reportStore.loadLatestReport()
        }
        .scrollEdgeEffectStyle(.hard, for: .top)
        .background(Color.appBackground.ignoresSafeArea())
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

struct GlassTabBar: View {
    @Binding var selectedTab: MetricsTab

    var body: some View {
        HStack(spacing: 10) {
            ForEach(MetricsTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.title)
                        .font(.subheadline.weight(selectedTab == tab ? .semibold : .medium))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                }
                .buttonStyle(.plain)
                .glassEffect(
                    selectedTab == tab
                        ? .regular.tint(.accentColor.opacity(0.3)).interactive()
                        : .regular
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

struct MetricsPlaceholderContent: View {
    let title: String

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            ForEach(0..<14, id: \.self) { index in
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(title) — card \(index + 1)")
                        .font(.headline)
                    Text("Placeholder content for \(title). Replace with real metrics, charts and summaries.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

#Preview {
    MetricsView(selectedTab: .constant(.insights))
        .background(Color.appBackground)
}
