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
        P: \(kp)
        I: \(ki)
        D: \(kd)
        Bearing: \(bearingPositionToDestinationWaypoint)
        Destination Latitude: \(destinationLatitude)
        Destination Longitude: \(destinationLongitude)
        Previous Destination Latitude: \(previousDestinationLatitude)
        Previous Destination Longitude: \(previousDestinationLongitude)
        Heading: \(heading)
        Cross-track Error: \(xte)
        Previous Cross-track Error: \(previousXte)
        Previous Time: \(previousTime)
        Previous Bearing: \(previousBearing)
        Integral Cross-track Error: \(integralXTE)
        Derivative Cross-track Error: \(derivativeXTE)
        Time Delta: \(timeDelta)
        Rudder Angle: \(rudderAngle)
        Rudder Position: \(rudderPosition)
        Target Motor Position: \(targetMotorPosition)
        Homing Complete: \(homingComplete)
        """
    }
    
    var kpDescription: String { "Proportional Gain (Kp): \(kp)" }
    var kiDescription: String { "Integral Gain (Ki): \(ki)" }
    var kdDescription: String { "Derivative Gain (Kd): \(kd)" }
    var bearingDescription: String { "Bearing to Destination Waypoint: \(bearingPositionToDestinationWaypoint)" }
    var destinationLatitudeDescription: String { "Destination Latitude: \(destinationLatitude)" }
    var destinationLongitudeDescription: String { "Destination Longitude: \(destinationLongitude)" }
    var previousDestinationLatitudeDescription: String { "Previous Destination Latitude: \(previousDestinationLatitude)" }
    var previousDestinationLongitudeDescription: String { "Previous Destination Longitude: \(previousDestinationLongitude)" }
    var headingDescription: String { "Current Heading: \(heading)" }
    var xteDescription: String { "Cross-Track Error (XTE): \(xte)" }
    var previousXteDescription: String { "Previous Cross-Track Error (Previous XTE): \(previousXte)" }
    var previousTimeDescription: String { "Previous Time: \(previousTime)" }
    var previousBearingDescription: String { "Previous Bearing: \(previousBearing)" }
    var integralXTEDescription: String { "Integral of Cross-Track Error: \(integralXTE)" }
    var derivativeXTEDescription: String { "Derivative of Cross-Track Error: \(derivativeXTE)" }
    var timeDeltaDescription: String { "Time Delta: \(timeDelta)" }
    var rudderAngleDescription: String { "Rudder Angle (Degrees): \(rudderAngle)" }
    var rudderPositionDescription: String { "Rudder Position: \(rudderPosition)" }
    var targetMotorPositionDescription: String { "Target Motor Position: \(targetMotorPosition)" }
    var homingCompleteDescription: String { "Homing Complete: \(homingComplete ? "Yes" : "No")" }
    
    func allDescriptions() -> [String] {
            return [
                kpDescription,
                kiDescription,
                kdDescription,
                bearingDescription,
                destinationLatitudeDescription,
                destinationLongitudeDescription,
                previousDestinationLatitudeDescription,
                previousDestinationLongitudeDescription,
                headingDescription,
                xteDescription,
                previousXteDescription,
                previousTimeDescription,
                previousBearingDescription,
                integralXTEDescription,
                derivativeXTEDescription,
                timeDeltaDescription,
                rudderAngleDescription,
                rudderPositionDescription,
                targetMotorPositionDescription,
                homingCompleteDescription
            ]
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

extension Autopilot {
    func toData() -> Data {
        var copy = self
        return withUnsafeBytes(of: &copy) { Data($0) }
    }
}

extension Float {
    // Rounds the float to the specified number of decimal places
    func rounded(toPlaces places: Int) -> Float {
        let divisor = pow(10.0, Float(places))
        return (self * divisor).rounded() / divisor
    }
}

// BLE Manager that handles Bluetooth connections and publishes changes to SwiftUI views
class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager!
    var connectedPeripheral: CBPeripheral?
    var targetCharacteristic: CBCharacteristic?
    
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
                    targetCharacteristic = characteristic
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
    
    func writeToCharacteristic(autopilot: Autopilot) {
        if let peripheral = connectedPeripheral, let characteristic = targetCharacteristic {
            let data = autopilot.toData()  // Serialize the Autopilot struct to Data
            peripheral.writeValue(data, for: characteristic, type: .withResponse)  // Write the data to the characteristic
        }
    }
    
    func sendUpdatedPIDValues(kpInput: Float, kiInput: Float, kdInput: Float) {
        autopilot.kp = kpInput.rounded(toPlaces: 1);
        autopilot.ki = kiInput.rounded(toPlaces: 1);
        autopilot.kd = kdInput.rounded(toPlaces: 1);
        writeToCharacteristic(autopilot: autopilot);
    }
}
