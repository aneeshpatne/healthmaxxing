//
//  SwiftUIView.swift
//  Forma
//
//  Created by Aneesh Patne on 19/06/26.
//

import SwiftUI

struct SwiftUIView: View {
    var body: some View {
        VStack {
            FormaHeader()

            TabView {
                MetricsView().tabItem {
                    Image(systemName: "chart.xyaxis.line")
                    Text("Metrics")
                }
                
                WorkoutsView().tabItem {
                    Image(systemName: "figure.strengthtraining.traditional")
                    Text("Workouts")
                }

                RecordView().tabItem {
                    Image(systemName: "record.circle")
                    Text("Record")
                }

                VitalsView().tabItem {
                    Image(systemName: "heart.text.square")
                    Text("Vitals")
                }
            }
        }
    }
}

#Preview {
    SwiftUIView()
}
