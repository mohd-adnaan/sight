//
//  BluetoothController.swift
//  CybGuidance
//
//  Created by Nicolas Albert on 13.06.2024.
//

import Foundation
import CoreBluetooth
import UIKit

protocol BluetoothManagerDelegate: AnyObject {
    func bluetoothManager(_ manager: BluetoothManager, didUpdateConnectionStatus isConnected: Bool)
    func bluetoothManager(_ manager: BluetoothManager, didUpdateValue value: Data)
    func bluetoothManager(_ manager: BluetoothManager, didDisconnectPeripheral peripheral: CBPeripheral)
    func bluetoothManager(_ manager: BluetoothManager, didEncounterError error: Error)
}


class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    weak var delegate: BluetoothManagerDelegate?
    
    private var centralManager: CBCentralManager!
    private var targetPeripheral: CBPeripheral?
    private var characteristic: CBCharacteristic?
    
    private let targetPeripheralUUID = UUID(uuidString: "15717075-344D-656D-A058-6DE856041F04")
    private let serviceUUID = CBUUID(string: "4FAFC201-1FB5-459E-8FCC-C5C9C331914B")
    private let characteristicUUID = CBUUID(string: "BEB5483E-36E1-4688-B7F5-EA07361B26A8")
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Methods
    
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            delegate?.bluetoothManager(self, didEncounterError: NSError(domain: "BluetoothManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Bluetooth is not powered on."]))
            return
        }
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func stopScanning() {
        centralManager.stopScan()
    }
    
    func writeValue(value: String) {
        guard let characteristic = characteristic, let data = value.data(using: .utf8) else {
            delegate?.bluetoothManager(self, didEncounterError: NSError(domain: "BluetoothManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Characteristic not available or invalid data"]))
            return
        }
        targetPeripheral?.writeValue(data, for: characteristic, type: .withResponse)
    }
    
    // MARK: - CBCentralManagerDelegate Methods
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Bluetooth is powered on.")
        } else {
            delegate?.bluetoothManager(self, didEncounterError: NSError(domain: "BluetoothManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Bluetooth is not available."]))
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered peripheral: \(peripheral.name ?? "Unknown") with UUID: \(peripheral.identifier.uuidString)")
        
        if peripheral.identifier == targetPeripheralUUID {
            targetPeripheral = peripheral
            targetPeripheral?.delegate = self
            centralManager.stopScan()
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to peripheral: \(peripheral.name ?? "Unknown")")
        delegate?.bluetoothManager(self, didUpdateConnectionStatus: true)
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        delegate?.bluetoothManager(self, didUpdateConnectionStatus: false)
        delegate?.bluetoothManager(self, didEncounterError: error ?? NSError(domain: "BluetoothManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to connect to peripheral."]))
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from peripheral: \(peripheral.name ?? "Unknown")")
        delegate?.bluetoothManager(self, didUpdateConnectionStatus: false)
        delegate?.bluetoothManager(self, didDisconnectPeripheral: peripheral)
    }
    
    // MARK: - CBPeripheralDelegate Methods
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            delegate?.bluetoothManager(self, didEncounterError: error)
            return
        }
        
        if let services = peripheral.services {
            for service in services {
                print("Discovered service: \(service.uuid)")
                if service.uuid == serviceUUID {
                    peripheral.discoverCharacteristics([characteristicUUID], for: service)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            delegate?.bluetoothManager(self, didEncounterError: error)
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                print("Discovered characteristic: \(characteristic.uuid)")
                if characteristic.uuid == characteristicUUID {
                    self.characteristic = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            delegate?.bluetoothManager(self, didEncounterError: error)
            return
        }
        
        if let value = characteristic.value {
            delegate?.bluetoothManager(self, didUpdateValue: value)
        }
    }
}
