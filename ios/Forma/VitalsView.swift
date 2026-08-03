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
            FormaFeaturePreviewView(
                title: "Vitals",
                message: "Heart-rate history, recovery, and Apple Health trends are being prepared for a future update.",
                systemImage: "heart.text.square",
                tint: .formaInfo
            )
            .padding(.top, FormaSpacing.xl)
            .frame(maxWidth: .infinity)
        }
        .contentMargins(.top, FormaLayout.floatingSettingsClearance, for: .scrollContent)
        .background(FormaBackground())
    }
}
