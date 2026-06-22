import SwiftUI

struct InsightsTab: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // MARK: - Weekly Summary Card
                VStack(alignment: .leading, spacing: 18) {
                    // Header
                    HStack(spacing: 8) {
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 24, height: 24)
                            .background(Color.accentColor.opacity(0.1), in: Circle())

                        Text("Weekly Summary")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.8)

                        Spacer()

                        Text("Jun 16 – 22")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.fill.tertiary, in: Capsule())
                    }

                    // Insight text
                    Text("Foundation is strong — body fat trending down while lean mass holds steady.")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()
                        .background(.secondary.opacity(0.1))

                    // Premium simplified insight row
                    HStack(spacing: 14) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.orange)
                            .frame(width: 38, height: 38)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(.orange.opacity(0.12))
                            )

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Body Fat")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)

                            Text("Down 0.4% this week")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Apple Health style trend badge
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.right")
                                .font(.system(size: 11, weight: .bold))
                            Text("-0.4%")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.green.opacity(0.1), in: Capsule())
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.appSecondaryBackground)
                        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 4)
                )
                .padding(.horizontal, 16)

                // MARK: - Strong Base Card
                VStack(alignment: .leading, spacing: 18) {
                    // Header
                    HStack(spacing: 8) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.green)
                            .frame(width: 24, height: 24)
                            .background(.green.opacity(0.12), in: Circle())

                        Text("Strong Base")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.8)

                        Spacer()
                    }

                    // Headline
                    Text("54.6 kg of lean mass gives you a strong foundation")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    // Body
                    Text("At 172 cm, your current muscle base supports a strong, athletic look as you continue leaning out.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()
                        .background(.secondary.opacity(0.1))

                    // Insight row
                    HStack(spacing: 14) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.green)
                            .frame(width: 38, height: 38)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(.green.opacity(0.12))
                            )

                        Text("Keep protein intake steady and stay consistent with strength training to maintain this muscle.")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.appSecondaryBackground)
                        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 4)
                )
                .padding(.horizontal, 16)
            }
        }
    }
}

#Preview {
    InsightsTab()
        .padding(.vertical, 20)
        .background(Color.appBackground)
}
