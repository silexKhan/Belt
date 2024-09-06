//
//  BluetoothUtility.swift
//
//
//  Created by ahn kyu suk on 9/5/24.
//

import Foundation
import CoreBluetooth
import Combine

/// `BluetoothUtility` class provides functionalities for scanning, connecting, and interacting with Bluetooth devices using CoreBluetooth framework.
/// It includes support for managing multiple connections, handling services and characteristics, and publishing real-time updates via Combine.
///
/// ## Key Features:
/// - **Device Scanning**: Starts scanning for nearby Bluetooth devices and publishes the discovered devices list.
/// - **Device Connection**: Supports connecting to multiple devices simultaneously and managing active connections.
/// - **Service Discovery**: Once connected, it discovers and manages the services and characteristics provided by the devices.
/// - **Real-Time Updates**: Provides real-time updates on Bluetooth state, discovered devices, services, and characteristic updates using Combine publishers.
/// - **Error Handling**: Captures and publishes errors that occur during Bluetooth operations through a dedicated error publisher.
///
/// ## Publishers:
/// - `bluetoothStatePublisher`: Publishes the current Bluetooth state (e.g., powered on, powered off).
/// - `devicesPublisher`: Publishes a list of discovered Bluetooth devices.
/// - `servicesPublisher`: Publishes a list of services provided by the connected devices.
/// - `serviceUpdatePublisher`: Publishes updates to the characteristics of discovered services.
/// - `errorPublisher`: Publishes errors encountered during Bluetooth operations.
///
/// ## Example Usage:
/// ```swift
/// let bluetoothUtility = BluetoothUtility()
///
/// // Start scanning for devices
/// bluetoothUtility.startScanning()
///
/// // Subscribe to device updates
/// let deviceCancellable = bluetoothUtility.devicesPublisher
///     .sink { devices in
///         for device in devices {
///             print("Discovered device: \(device.name)")
///         }
///     }
///
/// // Subscribe to service updates
/// let serviceCancellable = bluetoothUtility.servicesPublisher
///     .sink { services in
///         for service in services {
///             print("Discovered service: \(service.uuid)")
///         }
///     }
///
/// // Subscribe to characteristic updates
/// let characteristicCancellable = bluetoothUtility.serviceUpdatePublisher
///     .sink { updatedService in
///         print("Characteristic updated for service: \(updatedService.uuid)")
///     }
///
/// // Connect to a discovered device
/// if let firstDevice = bluetoothUtility.devicesPublisher.value.first {
///     bluetoothUtility.connect(to: firstDevice)
/// }
///
/// // Error handling
/// let errorCancellable = bluetoothUtility.errorPublisher
///     .sink { error in
///         print("Bluetooth Error: \(error.localizedDescription)")
///     }
/// ```
///
/// This class provides an easy-to-use interface for handling Bluetooth operations, allowing you to scan, connect, and interact with Bluetooth devices in a reactive manner using Combine.
public class BluetoothUtility: NSObject {
    
    private var centralManager: CBCentralManager!
    private var connectedPeripherals: Set<CBPeripheral> = []  // Set으로 변경하여 중복 방지
    private var cachedServices = [CBPeripheral: [CBService]]()
    private var bluetoothState = CurrentValueSubject<BluetoothState, Never>(.unknown)
    private var discoveredDevices = CurrentValueSubject<[BluetoothDevice], Never>([])
    private var discoveredServices = CurrentValueSubject<[BluetoothService], Never>([])
    private var updatedService = PassthroughSubject<BluetoothService, Never>()  // 업데이트된 서비스 Publisher
    private var errorSubject = PassthroughSubject<Error, Never>()  // 오류 처리 추가
    private var connectionTimeout: TimeInterval = 10  // 연결 타임아웃 설정
    
    /// Initializes the `BluetoothUtility` class and sets up the Bluetooth central manager.
    /// This manager is responsible for controlling Bluetooth operations, such as scanning and connecting to devices.
    public override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    /// Publisher that provides the current state of Bluetooth (powered on, powered off, etc.).
    /// - Returns: A publisher that emits the current `BluetoothState` (e.g., `.poweredOn`, `.poweredOff`).
    public var bluetoothStatePublisher: AnyPublisher<BluetoothState, Never> {
        return bluetoothState.eraseToAnyPublisher()
    }
    
    /// Publisher that provides updates on discovered Bluetooth devices.
    /// - Returns: A publisher that emits the list of discovered `BluetoothDevice` objects.
    public var devicesPublisher: AnyPublisher<[BluetoothDevice], Never> {
        return discoveredDevices.eraseToAnyPublisher()
    }
    
    /// Publisher that provides updates on discovered services and characteristics of connected devices.
    /// - Returns: A publisher that emits the list of `BluetoothService` objects for connected devices.
    public var servicesPublisher: AnyPublisher<[BluetoothService], Never> {
        return discoveredServices.eraseToAnyPublisher()
    }
    
    /// Publisher that sends updates when a characteristic value of a service is updated.
    /// - Returns: A publisher that emits `BluetoothService` objects whenever a characteristic value is updated.
    public var serviceUpdatePublisher: AnyPublisher<BluetoothService, Never> {
        return updatedService.eraseToAnyPublisher()
    }
    
    /// Publisher that handles errors during Bluetooth operations.
    /// - Returns: A publisher that emits any `Error` encountered during Bluetooth operations.
    public var errorPublisher: AnyPublisher<Error, Never> {
        return errorSubject.eraseToAnyPublisher()
    }
    
    /// Starts scanning for nearby Bluetooth devices using the central manager.
    /// The discovered devices are published via `devicesPublisher`.
    /// - Note: This method clears the existing list of discovered devices and begins a new scan.
    public func startScanning() {
        guard centralManager.state == .poweredOn else {
            print("Bluetooth is not powered on")
            bluetoothState.send(.poweredOff)
            return
        }
        discoveredDevices.send([])  // Reset the device list before scanning
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    /// Connects to a specific Bluetooth device using its `BluetoothDevice` model.
    /// Supports multiple simultaneous connections to Bluetooth devices.
    /// - Parameter device: The `BluetoothDevice` object representing the device to connect to.
    public func connect(to device: BluetoothDevice) {
        guard let peripheral = discoveredDevices.value.first(where: { $0.id == device.id })?.peripheral else {
            print("Peripheral not found for device: \(device.name)")
            errorSubject.send(NSError(domain: "Peripheral Not Found", code: -1, userInfo: nil))
            return
        }
        
        if !connectedPeripherals.contains(where: { $0.identifier == device.id }) {
            connectedPeripherals.insert(peripheral)
            peripheral.delegate = self
            centralManager.connect(peripheral, options: nil)
            
            // Connection timeout handler
            DispatchQueue.main.asyncAfter(deadline: .now() + connectionTimeout) {
                if !self.connectedPeripherals.contains(peripheral) {
                    self.centralManager.cancelPeripheralConnection(peripheral)
                    self.errorSubject.send(NSError(domain: "Connection Timeout", code: -2, userInfo: nil))
                }
            }
        }
    }
    
    /// Disconnects a specific Bluetooth device.
    /// - Parameter device: The `BluetoothDevice` object representing the device to disconnect from.
    public func disconnect(from device: BluetoothDevice) {
        guard let peripheral = connectedPeripherals.first(where: { $0.identifier == device.id }) else {
            print("Peripheral not found for disconnection")
            return
        }
        centralManager.cancelPeripheralConnection(peripheral)
        connectedPeripherals = connectedPeripherals.filter { $0.identifier != device.id }
    }
    
    /// Disconnects all currently connected Bluetooth devices.
    /// This method ensures that all active connections are terminated.
    public func disconnectAll() {
        for peripheral in connectedPeripherals {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        connectedPeripherals.removeAll()
    }
}

extension BluetoothUtility: CBCentralManagerDelegate {
    
    /// Handles Bluetooth state changes and updates the central manager state.
    /// - Parameter central: The `CBCentralManager` responsible for handling Bluetooth operations.
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            bluetoothState.send(.poweredOn)
        case .poweredOff:
            bluetoothState.send(.poweredOff)
        case .unsupported:
            bluetoothState.send(.unsupported)
        case .unauthorized:
            bluetoothState.send(.unauthorized)
        case .resetting:
            bluetoothState.send(.resetting)
        case .unknown:
            bluetoothState.send(.unknown)
        @unknown default:
            bluetoothState.send(.unknown)
        }
    }
    
    /// Discovers Bluetooth devices and publishes the found devices via `devicesPublisher`.
    /// - Parameters:
    ///   - central: The `CBCentralManager` responsible for scanning.
    ///   - peripheral: The `CBPeripheral` representing the discovered device.
    ///   - advertisementData: Advertisement data from the peripheral.
    ///   - RSSI: Signal strength indicator for the discovered device.
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let device = BluetoothDevice(peripheral: peripheral, rssi: RSSI, advertisementData: advertisementData)
        if !discoveredDevices.value.contains(where: { $0.id == device.id }) {
            var currentDevices = discoveredDevices.value
            currentDevices.append(device)
            discoveredDevices.send(currentDevices)
        }
    }
    
    /// Handles successful connection to a Bluetooth peripheral and starts service discovery.
    /// - Parameter peripheral: The `CBPeripheral` that was successfully connected.
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.readRSSI()
        if let services = cachedServices[peripheral] {
            discoveredServices.send(services.map { BluetoothService(uuid: $0.uuid) })
        } else {
            peripheral.discoverServices(nil)
        }
    }
    
    /// Handles the RSSI value (signal strength) of a connected peripheral.
    /// - Parameters:
    ///   - peripheral: The `CBPeripheral` whose RSSI value was read.
    ///   - RSSI: The signal strength of the connected peripheral.
    ///   - error: Any error that occurred while reading the RSSI.
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        guard error == nil else {
            errorSubject.send(error!)
            return
        }
        print("Updated RSSI for peripheral: \(peripheral.name ?? "Unknown"), RSSI: \(RSSI)")
    }
    
    /// Handles disconnection from a Bluetooth peripheral.
    /// If an error occurs during disconnection, the error is published via `errorPublisher`.
    /// - Parameters:
    ///   - peripheral: The `CBPeripheral` that was disconnected.
    ///   - error: The error, if any, that occurred during disconnection.
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from peripheral: \(peripheral.name ?? "Unknown")")
        // Use filter to create a new set excluding the disconnected peripheral
        connectedPeripherals = connectedPeripherals.filter { $0.identifier != peripheral.identifier }
        if let error = error {
            errorSubject.send(error)
        }
    }
}

extension BluetoothUtility: CBPeripheralDelegate {
    
    /// Called when the peripheral discovers services. The discovered services are published via `servicesPublisher`.
    /// - Parameters:
    ///   - peripheral: The `CBPeripheral` that provided the services.
    ///   - error: The error, if any, encountered while discovering services.
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        cachedServices[peripheral] = services
        var serviceInfos: [BluetoothService] = []
        
        for service in services {
            serviceInfos.append(BluetoothService(uuid: service.uuid))
            peripheral.discoverCharacteristics(nil, for: service)
        }
        discoveredServices.send(serviceInfos)
    }
    
    /// Called when the peripheral discovers characteristics for a service. The updated service is published via `serviceUpdatePublisher`.
    /// - Parameters:
    ///   - peripheral: The `CBPeripheral` whose characteristics were discovered.
    ///   - service: The `CBService` associated with the characteristics.
    ///   - error: The error, if any, encountered while discovering characteristics.
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        var currentService = discoveredServices.value.first(where: { $0.uuid == service.uuid })
        for characteristic in characteristics {
            currentService?.characteristics.append(characteristic)
            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
            }
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
        
        if let updatedServiceIndex = discoveredServices.value.firstIndex(where: { $0.uuid == service.uuid }) {
            discoveredServices.value[updatedServiceIndex] = currentService!
            updatedService.send(currentService!)
        }
    }
    
    /// Handles updates to the value of a characteristic for a connected Bluetooth peripheral.
    /// The updated characteristic values are published via `serviceUpdatePublisher`.
    /// - Parameters:
    ///   - peripheral: The `CBPeripheral` whose characteristic value was updated.
    ///   - characteristic: The `CBCharacteristic` that was updated.
    ///   - error: The error, if any, encountered while updating the characteristic.
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error updating characteristic: \(error.localizedDescription)")
            errorSubject.send(error)
            return
        }
        guard let value = characteristic.value else { return }
        print("Updated value for characteristic: \(characteristic.uuid), value: \(value)")
        
        if var updatedService = discoveredServices.value.first(where: { $0.characteristics.contains(where: { $0.uuid == characteristic.uuid }) }) {
            updatedService.characteristics = updatedService.characteristics.map { char in
                char.uuid == characteristic.uuid ? characteristic : char
            }
            self.updatedService.send(updatedService)
        }
    }
}
