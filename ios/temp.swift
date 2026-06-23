import SwiftUI
import Charts
struct Trend: Identifiable { let id = UUID(); let date: String; let value: Double }
struct Dummy: View {
    let data = [Trend(date: "A", value: 1.0)]
    var body: some View {
        Chart(data) { item in
            LineMark(x: .value("Date", item.date), y: .value("Value", item.value))
            if item.date == "A" {
                PointMark(x: .value("Date", item.date), y: .value("Value", item.value))
            }
        }
    }
}
