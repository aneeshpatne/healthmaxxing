//
//  ClerkSignInView.swift
//  Forma
//
//  Created by Codex on 29/06/26.
//

import SwiftUI
import ClerkKitUI

struct ClerkSignInView: View {
    @State private var authIsPresented = false

    var body: some View {
        ZStack {
            FormaBackground()

            VStack(alignment: .leading, spacing: FormaSpacing.xxl) {
                VStack(alignment: .leading, spacing: FormaSpacing.xs) {
                    Text("Forma")
                        .font(.system(size: 48, weight: .bold, design: .default))
                        .tracking(-1.4)
                        .foregroundStyle(.primary)

                    Text("Your body, understood over time.")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("Sign in to record measurements and follow the changes that matter.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    authIsPresented = true
                } label: {
                    Label("Continue with Clerk", systemImage: "person.crop.circle.badge.checkmark")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 54)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.roundedRectangle(radius: FormaRadius.inset))
                .tint(.sleekAccent)
            }
            .formaSurface(.hero, padding: FormaSpacing.xxl)
            .padding(FormaSpacing.screenGutter)
            .frame(maxWidth: 430, alignment: .leading)
        }
        .sheet(isPresented: $authIsPresented) {
            AuthView()
        }
    }
}

#Preview {
    ClerkSignInView()
}
