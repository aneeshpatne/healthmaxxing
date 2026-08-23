//
//  ScaleMeasurement.swift
//  Forma
//
//  Created by Codex on 30/06/26.
//

import Foundation

struct ScaleMeasurement: Equatable {
    var weightKg: Float?
    var heartRate: Int?
    var impedanceOhms: Float?
    var isFinal = false
}

enum ScaleMeasurementDecoder {
    static let minImpedanceOhms: Float = 200
    static let maxImpedanceOhms: Float = 1200

    static func decode(_ data: Data, previous: ScaleMeasurement) -> ScaleMeasurement? {
        let bytes = [UInt8](data)

        if bytes.count == 2, bytes[0] == 0xF3, bytes[1] == 0x00 {
            var finalMeasurement = previous
            finalMeasurement.isFinal = true
            return finalMeasurement
        }

        guard bytes.count == 11 else { return nil }

        let packetType = bytes[0]
        guard packetType == 0xCF || packetType == 0xCE else { return nil }
        guard isValidChecksum(bytes) else { return nil }

        let flags = bytes[2]
        let dataType = bytes[9]
        let rawWeight = Int(bytes[3]) | (Int(bytes[4]) << 8)
        let weightKg = rawWeight > 0 ? Float(rawWeight) / 100 : previous.weightKg
        let decodedHeartRate = decodeHeartRate(bytes: bytes, flags: flags, dataType: dataType)
        let encodedImpedance = Int(bytes[5]) | (Int(bytes[6]) << 8) | (Int(bytes[7]) << 16)
        let decodedImpedance = decodeImpedance(encodedValue: encodedImpedance, dataType: dataType)

        return ScaleMeasurement(
            weightKg: weightKg,
            heartRate: decodedHeartRate ?? previous.heartRate,
            impedanceOhms: decodedImpedance ?? previous.impedanceOhms,
            isFinal: decodedHeartRate != nil
        )
    }

    static func decodeImpedance(encodedValue: Int, dataType: UInt8) -> Float? {
        guard encodedValue != 0xFFFFFF else { return nil }

        let b0 = encodedValue & 0xFF
        let n = (encodedValue >> 12) & 0x0F
        let baseHigh = (encodedValue >> 8) & 0x0F
        let baseLow = (encodedValue >> 16) & 0xFF
        let base = (baseHigh << 8) | baseLow
        let x2 = base - (b0 * 4 + n)
        let rawOhms = x2 < 1 ? (x2 + 1) / 2 : x2 / 2

        guard rawOhms > 0 else { return nil }

        var ohms = Float(rawOhms)
        if dataType == 0xA0, ohms > maxImpedanceOhms {
            ohms /= 10
        }

        return minImpedanceOhms...maxImpedanceOhms ~= ohms ? ohms : nil
    }

    private static func decodeHeartRate(bytes: [UInt8], flags: UInt8, dataType: UInt8) -> Int? {
        if flags & 0xC0 == 0xC0 {
            return Int(bytes[1])
        } else if dataType == 0x03 {
            return Int(bytes[3])
        } else if dataType == 0x04 {
            return Int(bytes[8])
        } else {
            return nil
        }
    }

    private static func isValidChecksum(_ bytes: [UInt8]) -> Bool {
        let payloadXor = bytes.prefix(10).reduce(UInt8(0)) { $0 ^ $1 }
        return payloadXor == bytes[10]
    }
}
