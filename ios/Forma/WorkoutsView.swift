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
            EmptyView()
        }
        .contentMargins(.top, FormaLayout.floatingSettingsClearance, for: .scrollContent)
        .background(FormaBackground())
    }
}
