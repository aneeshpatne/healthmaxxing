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
        if clerk.user != nil {
            PrimaryProfileGate()
        } else {
            ClerkSignInView()
        }
    }
}
#Preview {
    ContentView()
        .environment(Clerk.shared)
}
