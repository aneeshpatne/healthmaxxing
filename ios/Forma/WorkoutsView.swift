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
        .safeAreaPadding(.top, headerHeight)
        .background(Color.appBackground.ignoresSafeArea())
    }
}
