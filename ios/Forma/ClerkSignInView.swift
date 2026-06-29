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
            Color.appBackground
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Forma")
                        .font(Font.cormorantGaramond(size: 54).weight(.bold))
                        .foregroundStyle(.primary)

                    Text("Sign in to continue")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Button {
                    authIsPresented = true
                } label: {
                    Label("Continue with Clerk", systemImage: "person.crop.circle.badge.checkmark")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(28)
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
