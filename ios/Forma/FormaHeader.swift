//
//  FormaHeader.swift
//  Forma
//
//  Created by Aneesh Patne on 19/06/26.
//
import SwiftUI
import ClerkKitUI

let headerHeight: CGFloat = 128

private let headerContentHeight: CGFloat = 68

struct FormaHeader: View {
    @Binding var activeTab: AppTab
    @Binding var selectedMetricsTab: MetricsTab

    // Dynamic greeting based on the current time of day
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good Morning, Aneesh"
        case 12..<17:
            return "Good Afternoon, Aneesh"
        default:
            return "Good Evening, Aneesh"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Forma")
                        .font(Font.cormorantGaramond(size: 34).weight(.bold))
                        .foregroundStyle(.primary)
                        .kerning(0.5)

                    Text(greeting)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                UserButton()
                    .frame(width: 42, height: 42)
                    .glassEffect(.regular, in: Circle())
            }
            .frame(height: headerContentHeight)
            .padding(.horizontal, 20)

            if activeTab == .metrics {
                GlassTabBar(selectedTab: $selectedMetricsTab)
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
    FormaHeader(activeTab: .constant(.metrics), selectedMetricsTab: .constant(.insights))
}
