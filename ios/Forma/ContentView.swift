//
//  ContentView.swift
//  Forma
//
//  Created by Aneesh Patne on 19/06/26.
//

import SwiftUI
import ClerkKit

struct ContentView: View {
    @Environment(Clerk.self) private var clerk

    var body: some View {
        Group {
            if clerk.user != nil {
                SwiftUIView()
                    .task(id: clerk.user?.id) {
                        await syncAuthenticatedAccount()
                    }
            } else {
                ClerkSignInView()
            }
        }
    }

    private func syncAuthenticatedAccount() async {
        guard let session = clerk.session else { return }

        do {
            guard let token = try await session.getToken() else { return }
            try await FormaBackendClient.authenticate(clerkToken: token)
        } catch {
            print("Failed to sync Forma account: \(error)")
        }
    }
}
#Preview {
    ContentView()
        .environment(Clerk.shared)
}
