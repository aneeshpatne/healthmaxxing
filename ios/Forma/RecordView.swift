//
//  RecordView.swift
//  Forma
//
//  Created by Aneesh Patne on 19/06/26.
//

import SwiftUI

struct RecordView: View {
    @StateObject private var scaleManager = ScaleBLEManager()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Record")
                    .font(.largeTitle.weight(.bold))

                ScaleStatusCard(
                    state: scaleManager.state,
                    measurement: scaleManager.latestMeasurement,
                    isReading: scaleManager.isReading,
                    startAction: scaleManager.startReading,
                    stopAction: scaleManager.stopReading
                )

                LatestMeasurementGrid(measurement: scaleManager.latestMeasurement)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .safeAreaPadding(.top, headerHeight)
        .background(Color.appBackground)
    }
}

private struct ScaleStatusCard: View {
    let state: ScaleConnectionState
    let measurement: ScaleMeasurement
    let isReading: Bool
    let startAction: () -> Void
    let stopAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: iconName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.sleekAccent)
                    .frame(width: 34, height: 34)
                    .background(Color.appSubtleFill, in: Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text("BLE Scale")
                        .font(.headline)

                    Text(statusText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            Button(action: isReading ? stopAction : startAction) {
                Label(isReading ? "Stop Reading" : "Read From Scale", systemImage: isReading ? "stop.fill" : "dot.radiowaves.left.and.right")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.sleekAccent)
            .controlSize(.large)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.appSeparator, lineWidth: 1)
        }
    }

    private var iconName: String {
        switch state {
        case .finished:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        case .waitingForBluetooth, .scanning, .connecting, .discoveringServices, .listening:
            return "antenna.radiowaves.left.and.right"
        case .idle:
            return "scalemass"
        }
    }

    private var statusText: String {
        switch state {
        case .failed(let message):
            return message
        case .finished where measurement.weightKg == nil:
            return "Reading complete. No weight was decoded."
        default:
            return state.label
        }
    }
}

private struct LatestMeasurementGrid: View {
    let measurement: ScaleMeasurement

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            MeasurementTile(
                title: "Weight",
                value: measurement.weightKg.map { String(format: "%.2f", $0) } ?? "--",
                unit: "kg",
                systemImage: "scalemass"
            )

            MeasurementTile(
                title: "Heart Rate",
                value: measurement.heartRate.map(String.init) ?? "--",
                unit: "bpm",
                systemImage: "heart.fill"
            )

            MeasurementTile(
                title: "Impedance",
                value: measurement.impedanceOhms.map { String(format: "%.0f", $0) } ?? "--",
                unit: "ohms",
                systemImage: "waveform.path.ecg"
            )
        }
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 150), spacing: 12)]
    }
}

private struct MeasurementTile: View {
    let title: String
    let value: String
    let unit: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.sleekAccent)
            }

            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(value)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(unit)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
        .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.appSeparator, lineWidth: 1)
        }
    }
}
