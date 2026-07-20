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
            FormaStatusView(
                title: "Workouts",
                message: "Guided strength sessions and training analytics are on the way.",
                systemImage: "figure.strengthtraining.traditional",
                tint: .formaTeal
            )
            .padding(.top, 120)
        }
        .contentMargins(.top, FormaLayout.floatingSettingsClearance, for: .scrollContent)
        .background(FormaBackground())
    }
}
