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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-FormaUITestShell") {
                SwiftUIView()
            } else if clerk.user != nil {
                PrimaryProfileGate()
                    .transition(.opacity)
            } else {
                ClerkSignInView()
                    .transition(.opacity)
            }
            #else
            if clerk.user != nil {
                PrimaryProfileGate()
                    .transition(.opacity)
            } else {
                ClerkSignInView()
                    .transition(.opacity)
            }
            #endif
        }
        .animation(reduceMotion ? nil : FormaMotion.enter, value: clerk.user != nil)
        .formaLaunchReveal()
    }
}
#Preview {
    ContentView()
        .environment(Clerk.shared)
        .environmentObject(FormaSoundPlayer())
}
