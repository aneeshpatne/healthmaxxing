//
//  WorkoutsView.swift
//  Forma
//
//  Created by Aneesh Patne on 19/06/26.
//

import SwiftUI

struct WorkoutsView: View {
    var body: some View {
        ScrollView {
            FormaFeaturePreviewView(
                title: "Workouts",
                message: "Guided strength sessions and training analytics are being shaped for a future update.",
                systemImage: "figure.strengthtraining.traditional",
                tint: .formaTeal
            )
            .padding(.top, FormaSpacing.xl)
            .frame(maxWidth: .infinity)
        }
        .contentMargins(.top, FormaLayout.floatingSettingsClearance, for: .scrollContent)
        .background(FormaBackground())
    }
}
