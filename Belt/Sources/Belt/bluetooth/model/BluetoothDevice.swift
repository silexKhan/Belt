//
//  BluetoothDevice.swift
//
//
//  Created by ahn kyu suk on 9/5/24.
//

import Foundation
import CoreBluetooth

/// Bluetooth 기기 정보를 저장하는 모델
public struct BluetoothDevice: Identifiable {
    
    public let id: UUID
    public let name: String
    public let rssi: Int
    public let advertisementData: [String: Any]
    public let peripheral: CBPeripheral
    
    public init(peripheral: CBPeripheral, rssi: NSNumber, advertisementData: [String: Any]) {
        self.id = peripheral.identifier
        self.name = peripheral.name ?? "Unknown"
        self.rssi = rssi.intValue
        self.advertisementData = advertisementData
        self.peripheral = peripheral
    }
}
