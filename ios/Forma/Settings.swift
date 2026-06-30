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
    var body: some View {
        Form {
            Section("Profiles") {
                settingsRow(
                    title: "Manage Profiles",
                    systemImage: "person.crop.circle",
                    tint: .blue
                ) {
                    Profiles()
                }

            }

            Section("User Management") {
                settingsRow(
                    title: "Account",
                    systemImage: "person.fill",
                    tint: .purple,
                ){
                    UserProfileView()
                }
            }
        }
        .navigationTitle("Settings")
    }

    private func settingsRow(title: String, systemImage: String, tint: Color) -> some View {
        rowContent(title: title, systemImage: systemImage, tint: tint)
    }

    private func settingsRow<Destination: View>(
        title: String,
        systemImage: String,
        tint: Color,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            rowContent(title: title, systemImage: systemImage, tint: tint)
        }
    }

    private func rowContent(title: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(tint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(title)
                .foregroundStyle(.primary)

            Spacer()
        }
    }
}

private struct SettingsDetailView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title2)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    Settings()
}
