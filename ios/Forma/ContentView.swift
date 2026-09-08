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
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-FormaUITestShell") {
                SwiftUIView()
            } else if clerk.user != nil {
                PrimaryProfileGate()
            } else {
                ClerkSignInView()
            }
            #else
            if clerk.user != nil {
                PrimaryProfileGate()
            } else {
                ClerkSignInView()
            }
            #endif
        }
        .formaLaunchReveal()
    }
}
#Preview {
    ContentView()
        .environment(Clerk.shared)
        .environmentObject(FormaSoundPlayer())
}
