//
//  FormaHeader.swift
//  Forma
//
//  Created by Aneesh Patne on 19/06/26.
//
import SwiftUI

let headerHeight: CGFloat = 150

private let headerContentHeight: CGFloat = 90

struct FormaHeader: View {
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

            // Simple profile image placeholder
            Image(systemName: "person.crop.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .foregroundStyle(.secondary)
        }
        .frame(height: headerContentHeight)
        .padding(.horizontal, 20)
        .background(.ultraThinMaterial)
    }
}
