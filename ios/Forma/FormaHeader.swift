//
//  FormaHeader.swift
//  Forma
//
//  Created by Aneesh Patne on 19/06/26.
//
import SwiftUI
import ClerkKit
import ClerkKitUI

let headerHeight: CGFloat = 128
let collapsedHeaderHeight: CGFloat = 78

private let headerContentHeight: CGFloat = 68

struct FormaHeader: View {
    @Binding var activeTab: AppTab
    @Binding var selectedMetricsTab: MetricsTab
    let isCollapsed: Bool

    @Environment(Clerk.self) private var clerk

    private var headerIsCollapsed: Bool {
        activeTab == .metrics && isCollapsed
    }
    
    // Dynamic greeting based on the current time of day
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let firstName = clerk.user?.firstName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = firstName?.isEmpty == false ? firstName! : "there"

        switch hour {
        case 0..<12:
            return "Good Morning, \(name)"
        case 12..<17:
            return "Good Afternoon, \(name)"
        default:
            return "Good Evening, \(name)"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Forma")
                        .font(Font.cormorantGaramond(size: headerIsCollapsed ? 28 : 34).weight(.bold))
                        .foregroundStyle(.primary)
                        .kerning(0.5)
                    
                    Text(greeting)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .opacity(headerIsCollapsed ? 0 : 1)
                        .frame(height: headerIsCollapsed ? 0 : nil)
                }
                
                Spacer()
                NavigationLink {
                    Settings()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(headerIsCollapsed ? .headline : .title2)
                        .foregroundStyle(Color.primary)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.glass)
                .accessibilityLabel("Settings")
            }
            .frame(height: headerIsCollapsed ? 52 : headerContentHeight)
            .padding(.horizontal, 20)
            
            if activeTab == .metrics {
                GlassTabBar(selectedTab: $selectedMetricsTab, isCollapsed: headerIsCollapsed)
            }
        }
        .background {
            GeometryReader { geo in
                Rectangle()
                    .fill(.clear)
                    .glassEffect(
                        .regular.tint(Color.appBackground.opacity(0.06)),
                        in: Rectangle()
                    )
                    .overlay {
                        LinearGradient(
                            colors: [
                                .white.opacity(0.18),
                                .clear,
                                .white.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .allowsHitTesting(false)
                    }
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(.white.opacity(0.16))
                            .frame(height: 0.5)
                    }
                    .shadow(color: .black.opacity(0.08), radius: 14, y: 6)
                // Extend the background into the safe area above
                    .padding(.top, -geo.safeAreaInsets.top)
            }
        }
    }
}

#Preview {
    FormaHeader(
        activeTab: .constant(.metrics),
        selectedMetricsTab: .constant(.insights),
        isCollapsed: false
    )
    .environment(Clerk.shared)
}
