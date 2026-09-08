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
    @State private var continueFeedbackNonce = 0

    var body: some View {
        ZStack {
            FormaBackground()

            VStack(alignment: .leading, spacing: FormaSpacing.xxl) {
                VStack(alignment: .leading, spacing: FormaSpacing.sm) {
                    FormaBrandLockup(variant: .hero)

                    Text("Your body,\nunderstood over time.")
                        .font(FormaTypography.sectionTitle)
                        .foregroundStyle(Color.formaTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Sign in to record measurements and follow the changes that matter.")
                        .font(FormaTypography.body)
                        .foregroundStyle(Color.formaTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    continueFeedbackNonce += 1
                    authIsPresented = true
                } label: {
                    Text("Continue")
                        .font(FormaTypography.action)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 54)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
                .tint(.sleekAccent)
            }
            .formaSurface(.hero, padding: FormaSpacing.xxl)
            .padding(FormaSpacing.screenGutter)
            .frame(maxWidth: 430, alignment: .leading)
        }
        .sheet(isPresented: $authIsPresented) {
            AuthView()
        }
        .formaFeedback(.confirm, trigger: continueFeedbackNonce)
    }
}

#Preview {
    ClerkSignInView()
        .environmentObject(FormaSoundPlayer())
}
