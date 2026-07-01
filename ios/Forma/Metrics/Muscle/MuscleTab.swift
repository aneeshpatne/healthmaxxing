import SwiftUI

struct MuscleTab: View {
    let payload: InsightReportPayload?

    private var sections: [InsightReportMetricSection] {
        ["muscle_mass", "bone_mass_trend", "muscle_mass_trend", "skeletal_muscle_mass_trend"]
            .compactMap { payload?.muscle[$0] }
    }

    var body: some View {
        VStack(spacing: 20) {
            if sections.isEmpty {
                MetricsPlaceholderContent(title: "Muscle")
            } else {
                ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                    MuscleReportCard(section: section)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

private struct MuscleReportCard: View {
    let section: InsightReportMetricSection

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.sleekAccent)
                    .frame(width: 26, height: 26)
                    .background(Color.sleekAccent.opacity(0.1), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                Text(section.displayTitle)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(1.0)

                Spacer()

                if let value = section.numberValue {
                    Text(String(format: "%.1f", value))
                        .font(.subheadline.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(Color.sleekAccent)
                }
            }

            if let title = section.title, title != section.displayTitle {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !section.displayComment.isEmpty {
                Text(section.displayComment)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.appSeparator, lineWidth: 1)
        }
    }
}

#Preview {
    MuscleTab(payload: nil)
}
