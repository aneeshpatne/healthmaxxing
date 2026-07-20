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
                PrimaryProfileGate()
                    .transition(.opacity)
            } else {
                ClerkSignInView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: clerk.user != nil)
        .formaLaunchReveal()
    }
}
#Preview {
    ContentView()
        .environment(Clerk.shared)
}
