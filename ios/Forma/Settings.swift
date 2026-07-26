//
//  Settings.swift
//  Forma
//
//  Created by Aneesh Patne on 30/06/26.
//
import SwiftUI
import ClerkKit
import ClerkKitUI

struct Settings: View {
    @State private var navigationFeedbackNonce = 0
    @EnvironmentObject private var soundPlayer: FormaSoundPlayer

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FormaSpacing.sectionGap) {
                settingsSection("Profiles") {
                    settingsRow(
                        title: "Manage Profiles",
                        subtitle: "People, goals, and primary profile",
                        systemImage: "person.crop.circle",
                        tint: .formaTeal
                    ) {
                        Profiles()
                    }
                }

                settingsSection("Account") {
                    settingsRow(
                        title: "Account",
                        subtitle: "Identity and sign-in settings",
                        systemImage: "person.fill",
                        tint: .sleekAccent
                    ) {
                        UserProfileView()
                    }
                }
            }
            .padding(.horizontal, FormaSpacing.screenGutter)
            .padding(.vertical, FormaSpacing.lg)
        }
        .background(FormaBackground())
        .navigationTitle("Settings")
        .sensoryFeedback(FormaUIFeedback.softImpact.sensoryFeedback, trigger: navigationFeedbackNonce)
    }

    private func settingsRow<Destination: View>(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            rowContent(title: title, subtitle: subtitle, systemImage: systemImage, tint: tint)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            TapGesture().onEnded {
                navigationFeedbackNonce += 1
                soundPlayer.play(FormaUIFeedback.softImpact)
            }
        )
    }

    private func rowContent(title: String, subtitle: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: FormaSpacing.sm) {
            FormaIconTile(
                systemImage: systemImage,
                tint: tint,
                size: 34,
                radius: 10,
                symbolFont: .system(size: 14, weight: .semibold)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }

    private func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: FormaSpacing.xs) {
            Text(title)
                .font(FormaTypography.cardTitle)
                .foregroundStyle(.primary)
                .padding(.horizontal, FormaSpacing.xxs)

            content()
                .formaSurface(.card, padding: FormaSpacing.cardInset)
        }
    }
}

#Preview {
    Settings()
        .environmentObject(FormaSoundPlayer())
}
