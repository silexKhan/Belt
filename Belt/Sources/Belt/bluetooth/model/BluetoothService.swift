//
//  BluetoothService.swift
//
//
//  Created by ahn kyu suk on 9/5/24.
//

import Foundation
import CoreBluetooth

/// Bluetooth 서비스 및 특성 정보를 저장하는 모델
public struct BluetoothService: Identifiable {
    
    public let id = UUID()
    public let uuid: CBUUID
    public var characteristics: [CBCharacteristic] = []
}
