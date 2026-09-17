//
//  ScaleBLEManager.swift
//  Forma
//
//  Created by Codex on 30/06/26.
//

import Combine
import CoreBluetooth
import Foundation

enum ScaleConnectionState: Equatable {
    case idle
    case waitingForBluetooth
    case scanning
    case connecting
    case discoveringServices
    case listening
    case finished
    case failed(String)

    var label: String {
        switch self {
        case .idle:
            return "Ready"
        case .waitingForBluetooth:
            return "Waiting for Bluetooth"
        case .scanning:
            return "Searching for scale"
        case .connecting:
            return "Connecting"
        case .discoveringServices:
            return "Preparing scale"
        case .listening:
            return "Reading measurement"
        case .finished:
            return "Complete"
        case .failed:
            return "Needs attention"
        }
    }
}

final class ScaleBLEManager: NSObject, ObservableObject {
    static let serviceUUID = CBUUID(string: "0000fff0-0000-1000-8000-00805f9b34fb")
    static let notifyCharacteristicUUID = CBUUID(string: "0000fff4-0000-1000-8000-00805f9b34fb")

    @Published private(set) var state: ScaleConnectionState = .idle
    @Published private(set) var latestMeasurement = ScaleMeasurement()

    private var centralManager: CBCentralManager?
    private var scalePeripheral: CBPeripheral?
    private var shouldStartWhenPoweredOn = false
    private var debugReadingTask: Task<Void, Never>?

    var isReading: Bool {
        switch state {
        case .waitingForBluetooth, .scanning, .connecting, .discoveringServices, .listening:
            return true
        case .idle, .finished, .failed:
            return false
        }
    }

    func startReading() {
        latestMeasurement = ScaleMeasurement()
        shouldStartWhenPoweredOn = true

        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: .main)
            state = .waitingForBluetooth
            return
        }

        beginScanIfReady()
    }

    func stopReading() {
        debugReadingTask?.cancel()
        debugReadingTask = nil
        shouldStartWhenPoweredOn = false
        centralManager?.stopScan()

        if let scalePeripheral {
            centralManager?.cancelPeripheralConnection(scalePeripheral)
        }

        scalePeripheral = nil
        state = .idle
    }

    /// Replays a complete reading through the same published state used by the
    /// BLE callbacks. RecordView still owns validation, submission, report
    /// queuing, success feedback, and dismissal.
    @MainActor
    func startDebugReading(weightKg: Float, impedanceOhms: Float, heartRate: Int) {
        debugReadingTask?.cancel()
        latestMeasurement = ScaleMeasurement()
        state = .listening

        debugReadingTask = Task { @MainActor [weak self] in
            guard let self else { return }

            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            self.latestMeasurement.weightKg = weightKg

            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            self.latestMeasurement.impedanceOhms = impedanceOhms

            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            self.latestMeasurement.heartRate = heartRate
            self.latestMeasurement.isFinal = true

            try? await Task.sleep(for: .milliseconds(180))
            guard !Task.isCancelled else { return }
            self.state = .finished
            self.debugReadingTask = nil
        }
    }

    private func beginScanIfReady() {
        guard let centralManager else { return }

        switch centralManager.state {
        case .poweredOn:
            state = .scanning
            centralManager.scanForPeripherals(
                withServices: [Self.serviceUUID],
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
            )
        case .poweredOff:
            state = .failed("Turn on Bluetooth to read from the scale.")
        case .unauthorized:
            state = .failed("Allow Bluetooth access for Forma in Settings.")
        case .unsupported:
            state = .failed("This device does not support Bluetooth LE.")
        case .resetting, .unknown:
            state = .waitingForBluetooth
        @unknown default:
            state = .failed("Bluetooth is unavailable.")
        }
    }

    private func closeConnection(markFinished: Bool) {
        shouldStartWhenPoweredOn = false
        centralManager?.stopScan()

        if let scalePeripheral {
            centralManager?.cancelPeripheralConnection(scalePeripheral)
        }

        scalePeripheral = nil
        state = markFinished ? .finished : .idle
    }
}

extension ScaleBLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard shouldStartWhenPoweredOn else { return }
        beginScanIfReady()
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        central.stopScan()
        scalePeripheral = peripheral
        peripheral.delegate = self
        state = .connecting
        central.connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        state = .discoveringServices
        peripheral.discoverServices([Self.serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        scalePeripheral = nil
        state = .failed(error?.localizedDescription ?? "Could not connect to the scale.")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        scalePeripheral = nil

        if latestMeasurement.isFinal {
            state = .finished
        } else if let error {
            state = .failed(error.localizedDescription)
        } else if isReading {
            state = .failed("The scale disconnected before the measurement completed.")
        }
    }
}

extension ScaleBLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            state = .failed(error.localizedDescription)
            return
        }

        guard let service = peripheral.services?.first(where: { $0.uuid == Self.serviceUUID }) else {
            state = .failed("Scale service was not found.")
            return
        }

        peripheral.discoverCharacteristics([Self.notifyCharacteristicUUID], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            state = .failed(error.localizedDescription)
            return
        }

        guard let characteristic = service.characteristics?.first(where: { $0.uuid == Self.notifyCharacteristicUUID }) else {
            state = .failed("Scale notification characteristic was not found.")
            return
        }

        state = .listening
        peripheral.setNotifyValue(true, for: characteristic)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            state = .failed(error.localizedDescription)
            return
        }

        guard let data = characteristic.value,
              let decoded = ScaleMeasurementDecoder.decode(data, previous: latestMeasurement) else {
            return
        }

        if decoded != latestMeasurement {
            latestMeasurement = decoded
        }

        if decoded.isFinal {
            closeConnection(markFinished: true)
        }
    }
}
