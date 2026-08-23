//
//  ScaleMeasurementDecoderTests.swift
//  FormaTests
//
//  Created by Codex on 30/06/26.
//

import Foundation
import Testing
@testable import Forma

struct ScaleMeasurementDecoderTests {
    @Test func decodesWeightAndCarriesPreviousValues() {
        let packet = packet(bytes: [0xCF, 0x00, 0x00, 0xB6, 0x1C, 0xFF, 0xFF, 0xFF, 0x00, 0x01])
        let previous = ScaleMeasurement(heartRate: 72, impedanceOhms: 510)

        let measurement = ScaleMeasurementDecoder.decode(Data(packet), previous: previous)

        #expect(measurement?.weightKg == 73.5)
        #expect(measurement?.heartRate == 72)
        #expect(measurement?.impedanceOhms == 510)
        #expect(measurement?.isFinal == false)
    }

    @Test func decodesHeartRateFromFlagsAndMarksFinal() {
        let packet = packet(bytes: [0xCF, 0x62, 0xC0, 0xB6, 0x1C, 0xFF, 0xFF, 0xFF, 0x00, 0x01])

        let measurement = ScaleMeasurementDecoder.decode(Data(packet), previous: ScaleMeasurement())

        #expect(measurement?.heartRate == 98)
        #expect(measurement?.isFinal == true)
    }

    @Test func finalMarkerMarksPreviousMeasurementFinal() {
        let previous = ScaleMeasurement(weightKg: 73.5, heartRate: 98, impedanceOhms: 510)

        let measurement = ScaleMeasurementDecoder.decode(Data([0xF3, 0x00]), previous: previous)

        #expect(measurement?.weightKg == 73.5)
        #expect(measurement?.heartRate == 98)
        #expect(measurement?.impedanceOhms == 510)
        #expect(measurement?.isFinal == true)
    }

    @Test func rejectsInvalidChecksum() {
        let measurement = ScaleMeasurementDecoder.decode(
            Data([0xCF, 0x00, 0x00, 0xB6, 0x1C, 0xFF, 0xFF, 0xFF, 0x00, 0x01, 0x00]),
            previous: ScaleMeasurement()
        )

        #expect(measurement == nil)
    }

    @Test func decodesValidImpedance() {
        let impedance = ScaleMeasurementDecoder.decodeImpedance(encodedValue: 0xE80300, dataType: 0x01)

        #expect(impedance == 500)
    }

    private func packet(bytes: [UInt8]) -> [UInt8] {
        let checksum = bytes.reduce(UInt8(0)) { $0 ^ $1 }
        return bytes + [checksum]
    }
}
