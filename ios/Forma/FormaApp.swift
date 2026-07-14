//
//  FormaApp.swift
//  Forma
//
//  Created by Aneesh Patne on 19/06/26.
//

import SwiftUI
import ClerkKit

@main
struct FormaApp: App {
    init() {
        Clerk.configure(publishableKey: ClerkConfig.publishableKey)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(.sleekAccent)
                .preferredColorScheme(.dark)
                .environment(Clerk.shared)
        }
    }
}
