//
//  VitalsView.swift
//  Forma
//
//  Created by Aneesh Patne on 19/06/26.
//

import SwiftUI

struct VitalsView: View {
    var body: some View {
        ScrollView {
            FormaStatusView(
                title: "Vitals",
                message: "Heart-rate history, recovery, and Apple Health trends are on the way.",
                systemImage: "heart.text.square",
                tint: .formaCoral
            )
            .padding(.top, 120)
        }
        .contentMargins(.top, FormaLayout.floatingSettingsClearance, for: .scrollContent)
        .background(FormaBackground())
    }
}
