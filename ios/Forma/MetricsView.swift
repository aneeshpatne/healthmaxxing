//
//  MetricsView.swift
//  Forma
//
//  Created by Aneesh Patne on 19/06/26.
//
import SwiftUI

struct MetricsView: View {
    @State private var selectedTab: MetricsTab = .insights

    var body: some View {
        VStack(spacing: 0) {
            ScrollableTabBar(selectedTab: $selectedTab)

            ScrollView {
                switch selectedTab {
                case .insights:
                    InsightsTab()
                case .performance:
                    PerformanceTab()
                case .fat:
                    FatTab()
                case .muscle:
                    MuscleTab()
                }
            }
        }
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

struct ScrollableTabBar: View {
    @Binding var selectedTab: MetricsTab
    @Namespace private var namespace

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(MetricsTab.allCases, id: \.self) { tab in
                            tabButton(for: tab)
                                .id(tab)

                            if tab != MetricsTab.allCases.last {
                                Spacer(minLength: 30)
                            }
                        }
                    }
                    .frame(minWidth: geometry.size.width)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                }
                .padding(.vertical, 4)
                .onChange(of: selectedTab) { _, newValue in
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
        .frame(height: 52)
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.secondarySystemBackground).opacity(0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func tabButton(for tab: MetricsTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 6) {
                Text(tab.title)
                    .font(.subheadline)
                    .fontWeight(selectedTab == tab ? .semibold : .medium)
                    .kerning(0.3)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .foregroundStyle(selectedTab == tab ? .primary : .secondary)

                ZStack {
                    Capsule()
                        .fill(Color.clear)
                        .frame(height: 2)

                    if selectedTab == tab {
                        Capsule()
                            .fill(Color.primary)
                            .frame(height: 2)
                            .matchedGeometryEffect(id: "selector", in: namespace)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct InsightsTab: View {
    var body: some View {
        Text("Insights")
            .frame(maxWidth: .infinity)
            .padding()
    }
}

struct PerformanceTab: View {
    var body: some View {
        Text("Performance")
            .frame(maxWidth: .infinity)
            .padding()
    }
}

struct FatTab: View {
    var body: some View {
        Text("Fat")
            .frame(maxWidth: .infinity)
            .padding()
    }
}

struct MuscleTab: View {
    var body: some View {
        Text("Muscle")
            .frame(maxWidth: .infinity)
            .padding()
    }
}

#Preview {
    MetricsView()
}
