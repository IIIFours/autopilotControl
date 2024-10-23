//
//  BLEManager.swift
//  autopilotControl
//
//  Created by Alexander Schlake on 10/23/24.
//


import Foundation
import CoreBluetooth

struct Autopilot: CustomStringConvertible {
    var kp: Float
    var ki: Float
    var kd: Float
    var bearingPositionToDestinationWaypoint: Float
    var destinationLatitude: Float
    var destinationLongitude: Float
    var previousDestinationLatitude: Float
    var previousDestinationLongitude: Float
    var heading: Float
    var xte: Float
    var previousXte: Float
    var previousTime: Float
    var previousBearing: Float
    var integralXTE: Float
    var derivativeXTE: Float
    var timeDelta: Float
    var rudderAngle: Float
    var rudderPosition: Float
    var targetMotorPosition: Float
    var homingComplete: Bool
    
    var description: String {
            return """
            kp: \(kp)
            ki: \(ki)
            kd: \(kd)
            bearingPositionToDestinationWaypoint: \(bearingPositionToDestinationWaypoint)
            destinationLatitude: \(destinationLatitude)
            destinationLongitude: \(destinationLongitude)
            previousDestinationLatitude: \(previousDestinationLatitude)
            previousDestinationLongitude: \(previousDestinationLongitude)
            heading: \(heading)
            xte: \(xte)
            previousXte: \(previousXte)
            previousTime: \(previousTime)
            previousBearing: \(previousBearing)
            integralXTE: \(integralXTE)
            derivativeXTE: \(derivativeXTE)
            timeDelta: \(timeDelta)
            rudderAngle: \(rudderAngle)
            rudderPosition: \(rudderPosition)
            targetMotorPosition: \(targetMotorPosition)
            homingComplete: \(homingComplete)
            """
        }
}

func deserializeAutopilot(data: Data) -> Autopilot {
    var offset = 0
    
    func readFloat() -> Float {
        let floatSize = MemoryLayout<Float>.size
        let value = data.subdata(in: offset..<(offset + floatSize)).withUnsafeBytes { $0.load(as: Float.self) }
        offset += floatSize
        return value
    }
    
    func readBool() -> Bool {
        let boolSize = MemoryLayout<Bool>.size
        let value = data.subdata(in: offset..<(offset + boolSize)).withUnsafeBytes { $0.load(as: Bool.self) }
        offset += boolSize
        return value
    }

    return Autopilot(
        kp: readFloat(),
        ki: readFloat(),
        kd: readFloat(),
        bearingPositionToDestinationWaypoint: readFloat(),
        destinationLatitude: readFloat(),
        destinationLongitude: readFloat(),
        previousDestinationLatitude: readFloat(),
        previousDestinationLongitude: readFloat(),
        heading: readFloat(),
        xte: readFloat(),
        previousXte: readFloat(),
        previousTime: readFloat(),
        previousBearing: readFloat(),
        integralXTE: readFloat(),
        derivativeXTE: readFloat(),
        timeDelta: readFloat(),
        rudderAngle: readFloat(),
        rudderPosition: readFloat(),
        targetMotorPosition: readFloat(),
        homingComplete: readBool()
    )
}

// BLE Manager that handles Bluetooth connections and publishes changes to SwiftUI views
class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager!
    var connectedPeripheral: CBPeripheral?
    
    @Published var isConnected = false
    @Published var autopilot: Autopilot = Autopilot(
        kp: 0.0,
        ki: 0.0,
        kd: 0.0,
        bearingPositionToDestinationWaypoint: 0.0,
        destinationLatitude: 0.0,
        destinationLongitude: 0.0,
        previousDestinationLatitude: 0.0,
        previousDestinationLongitude: 0.0,
        heading: 0.0,
        xte: 0.0,
        previousXte: 0.0,
        previousTime: 0.0,
        previousBearing: 0.0,
        integralXTE: 0.0,
        derivativeXTE: 0.0,
        timeDelta: 0.0,
        rudderAngle: 0.0,
        rudderPosition: 0.0,
        targetMotorPosition: 0.0,
        homingComplete: false
    );
    
    let targetServiceUUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b") // Replace with your service UUID
    let targetCharacteristicUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8") // Replace with your characteristic UUID
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Central Manager Delegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            // Start scanning for peripherals with the target service UUID
            centralManager.scanForPeripherals(withServices: [targetServiceUUID], options: nil)
        } else {
            print("Bluetooth is not available")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Stop scanning and connect to the peripheral
        centralManager.stopScan()
        connectedPeripheral = peripheral
        connectedPeripheral?.delegate = self
        centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "unknown device")")
        isConnected = true
        peripheral.discoverServices([targetServiceUUID])
    }
    
    // MARK: - Peripheral Delegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == targetServiceUUID {
                    peripheral.discoverCharacteristics([targetCharacteristicUUID], for: service)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == targetCharacteristicUUID {
                    peripheral.readValue(for: characteristic)
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let value = characteristic.value {
            DispatchQueue.main.async {
                let autopilot = deserializeAutopilot(data: value);
                self.autopilot = autopilot;
            }
        }
    }
}
