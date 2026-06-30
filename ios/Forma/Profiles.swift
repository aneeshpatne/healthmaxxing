//
//  Profiles.swift
//  Forma
//
//  Created by Aneesh Patne on 30/06/26.
//

import SwiftUI
import ClerkKit

struct Profiles: View {
    @Environment(Clerk.self) private var clerk

    @State private var profiles: [ClientProfile] = []
    @State private var errorMessage: String?
    @State private var isLoading = false

    private let apiClient = APIClient()

    var body: some View {
        List {
            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            if isLoading && profiles.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            } else if profiles.isEmpty {
                Section {
                    Text("No profiles found.")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    ForEach(profiles) { profile in
                        ProfileRow(profile: profile)
                    }
                }
            }
        }
        .navigationTitle("Profiles")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await loadProfiles()
        }
        .task {
            await loadProfiles()
        }
    }

    private func loadProfiles() async {
        guard clerk.user != nil else {
            profiles = []
            errorMessage = "Sign in to load profiles."
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let response = try await apiClient.send(GetClientProfilesRequest())
            profiles = response.users
        } catch APIError.missingAuthToken {
            profiles = []
            errorMessage = "Missing auth token."
        } catch APIError.serverError(let statusCode) {
            profiles = []
            errorMessage = "Server returned \(statusCode)."
        } catch {
            profiles = []
            errorMessage = "Failed to load profiles."
        }
    }
}

private struct ProfileRow: View {
    let profile: ClientProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(profile.name)
                    .font(.headline)

                if profile.isPrimary {
                    Text("Primary")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.blue)
                }
            }

            Text(profile.mailAddress)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let peopleType = profile.peopleType, !peopleType.isEmpty {
                Text(peopleType)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        Profiles()
            .environment(Clerk.shared)
    }
}
