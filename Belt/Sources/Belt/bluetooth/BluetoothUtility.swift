//
//  BluetoothUtility.swift
//
//
//  Created by ahn kyu suk on 9/5/24.
//

/**
 BluetoothUtility 클래스는 iOS에서 Bluetooth 기기를 탐색, 연결, 서비스 및 특성 데이터를 관리하는 유틸리티 클래스입니다.
 CoreBluetooth 프레임워크를 기반으로 Bluetooth 기기와의 통신을 처리하며, Combine을 통해 실시간 데이터 전송을 제공합니다.
 
 주요 기능:
 - **기기 탐색**: Bluetooth 기기를 검색하고 발견된 기기 목록을 외부로 전송합니다.
 - **기기 연결 및 해제**: 발견된 기기와 연결을 시도하고, 연결 해제 작업을 수행합니다.
 - **서비스 및 특성 탐색**: 연결된 기기에서 제공하는 서비스와 특성을 탐색합니다.
 - **특성 값 업데이트**: 기기의 특성 값이 업데이트될 때 해당 값을 실시간으로 외부로 전송합니다.
 - **Combine 연동**: 기기 목록, 서비스 목록, 특성 값 업데이트 등을 Combine을 통해 실시간으로 외부로 전달하여 반응형 데이터 흐름을 제공합니다.
 
 주요 Publisher:
 - `devicesPublisher`: Bluetooth 기기 목록을 외부로 전달하는 Publisher.
 - `servicesPublisher`: 연결된 기기의 서비스 목록을 전달하는 Publisher.
 - `serviceUpdatePublisher`: 특성 값이 업데이트될 때 해당 서비스 정보를 전달하는 Publisher.
 
 사용 예시:
 ```swift
 import Combine

 let bluetoothUtility = BluetoothUtility()

 // Bluetooth 기기 목록을 실시간으로 구독
 let cancellableDevices = bluetoothUtility.devicesPublisher
     .sink { devices in
         for device in devices {
             print("Device: \(device.name), RSSI: \(device.rssi), Data: \(device.advertisementData)")
         }
     }

 // Bluetooth 서비스 및 특성 목록을 실시간으로 구독
 let cancellableServices = bluetoothUtility.servicesPublisher
     .sink { services in
         for service in services {
             print("Service: \(service.uuid), Characteristics: \(service.characteristics)")
         }
     }

 // 서비스가 업데이트되면 실시간으로 구독
 let cancellableServiceUpdates = bluetoothUtility.serviceUpdatePublisher
     .sink { service in
         print("Service \(service.uuid) was updated with new characteristic values.")
     }

 // Bluetooth 스캔 시작
 bluetoothUtility.startScanning()

 // 특정 기기와 연결
 if let firstDevice = bluetoothUtility.devicesPublisher.value.first {
     bluetoothUtility.connect(to: firstDevice)
 }

 // 특정 기기와 연결 해제
 if let firstDevice = bluetoothUtility.devicesPublisher.value.first {
     bluetoothUtility.disconnect(from: firstDevice)
 }

 // 모든 연결된 기기 해제
 bluetoothUtility.disconnectAll()

 // 구독 취소 (필요 시)
 cancellableDevices.cancel()
 cancellableServices.cancel()
 cancellableServiceUpdates.cancel()
 ```
 
 이 클래스는 Bluetooth 기기와의 연결 및 통신을 간편하게 처리할 수 있도록 설계되었습니다.
 */

import Foundation
import CoreBluetooth
import Combine

public class BluetoothUtility: NSObject {
    
    private var centralManager: CBCentralManager!
    private var connectedPeripherals: [CBPeripheral] = []  // 여러 기기를 저장
    private var discoveredDevices = CurrentValueSubject<[BluetoothDevice], Never>([])
    private var discoveredServices = CurrentValueSubject<[BluetoothService], Never>([])
    private var updatedService = PassthroughSubject<BluetoothService, Never>()  // 업데이트된 서비스 Publisher
    
    public override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    /// Bluetooth 기기 목록을 외부로 전송하는 Publisher
    public var devicesPublisher: AnyPublisher<[BluetoothDevice], Never> {
        return discoveredDevices.eraseToAnyPublisher()
    }
    
    /// Bluetooth 서비스 및 특성 목록을 외부로 전송하는 Publisher
    public var servicesPublisher: AnyPublisher<[BluetoothService], Never> {
        return discoveredServices.eraseToAnyPublisher()
    }
    
    /// 업데이트된 서비스 정보를 외부로 전송하는 Publisher
    public var serviceUpdatePublisher: AnyPublisher<BluetoothService, Never> {
        return updatedService.eraseToAnyPublisher()
    }
    
    /// Bluetooth 기기를 검색하는 메서드
    public func startScanning() {
        guard centralManager.state == .poweredOn else {
            print("Bluetooth is not powered on")
            return
        }
        discoveredDevices.send([])  // 기존 목록 초기화
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    /// 특정 기기와 연결하는 메서드 (여러 기기 동시 연결 지원)
    public func connect(to device: BluetoothDevice) {
        guard let peripheral = discoveredDevices.value.first(where: { $0.id == device.id })?.peripheral else {
            print("Peripheral not found for device: \(device.name)")
            return
        }
        if !connectedPeripherals.contains(where: { $0.identifier == device.id }) {
            connectedPeripherals.append(peripheral)
            peripheral.delegate = self
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    /// 특정 기기와 연결 해제하는 메서드
    public func disconnect(from device: BluetoothDevice) {
        guard let peripheral = connectedPeripherals.first(where: { $0.identifier == device.id }) else {
            print("Peripheral not found for disconnection")
            return
        }
        centralManager.cancelPeripheralConnection(peripheral)
        connectedPeripherals.removeAll(where: { $0.identifier == device.id })
    }
    
    /// 모든 연결된 기기 해제
    public func disconnectAll() {
        for peripheral in connectedPeripherals {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        connectedPeripherals.removeAll()
    }
}

extension BluetoothUtility: CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Bluetooth 상태 업데이트 처리
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let device = BluetoothDevice(peripheral: peripheral, rssi: RSSI, advertisementData: advertisementData)
        
        if !discoveredDevices.value.contains(where: { $0.id == device.id }) {
            var currentDevices = discoveredDevices.value
            currentDevices.append(device)
            discoveredDevices.send(currentDevices)  // 변경된 목록을 Publisher로 전송
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to peripheral: \(peripheral.name ?? "Unknown")")
        // 연결 후 서비스 검색 시작
        peripheral.discoverServices(nil) // 모든 서비스 검색
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from peripheral: \(peripheral.name ?? "Unknown")")
        connectedPeripherals.removeAll(where: { $0.identifier == peripheral.identifier })
    }
}

extension BluetoothUtility: CBPeripheralDelegate {
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        var serviceInfos: [BluetoothService] = []
        
        for service in services {
            print("Discovered service: \(service.uuid)")
            serviceInfos.append(BluetoothService(uuid: service.uuid))
            peripheral.discoverCharacteristics(nil, for: service)
        }
        discoveredServices.send(serviceInfos)  // 서비스 정보를 업데이트
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        var currentService = discoveredServices.value.first(where: { $0.uuid == service.uuid })
        for characteristic in characteristics {
            print("Discovered characteristic: \(characteristic.uuid)")
            currentService?.characteristics.append(characteristic)
            
            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
            }
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
        
        // 업데이트된 서비스 모델을 다시 저장하고 외부로 보냄
        if let updatedServiceIndex = discoveredServices.value.firstIndex(where: { $0.uuid == service.uuid }) {
            discoveredServices.value[updatedServiceIndex] = currentService!
            updatedService.send(currentService!)  // 업데이트된 서비스 외부로 전송
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let value = characteristic.value else { return }
        print("Updated value for characteristic: \(characteristic.uuid), value: \(value)")
        
        // 특성 값 업데이트된 서비스 찾기
        if var updatedService = discoveredServices.value.first(where: { $0.characteristics.contains(where: { $0.uuid == characteristic.uuid }) }) {
            // 업데이트된 값을 characteristic에 반영 (필요할 경우)
            updatedService.characteristics = updatedService.characteristics.map { char in
                char.uuid == characteristic.uuid ? characteristic : char
            }
            self.updatedService.send(updatedService)  // 업데이트된 서비스 전체 모델 전송
        }
    }
}
