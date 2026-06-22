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
            Text("Vitals")
        }
        .safeAreaPadding(.top, headerHeight)
        .background(Color.appBackground)
    }
}
