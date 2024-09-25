//
//  PermissionUtility.swift
//
//
//  Created by ahn kyu suk on 9/5/24.
//

//
//  PermissionUtility.swift
//
//  Created by ahn kyu suk on 9/5/24.
//

//
//  PermissionUtility.swift
//
//  Created by ahn kyu suk on 9/5/24.
//

import Foundation
import Combine
import AVFoundation
import Photos
import CoreLocation
import UserNotifications
import CoreBluetooth

/// A utility class for managing permissions for various system features such as camera, photo library, microphone, location, notifications, and Bluetooth.
/// It uses the `Combine` framework to handle asynchronous permission requests and returns the results via `Future`.
///
/// This class handles permission requests for the following:
/// - Camera
/// - Photo Library
/// - Microphone
/// - Location (When In Use, Always)
/// - Notifications
/// - Bluetooth
///
/// # Example Usage:
///
/// ```swift
/// let permissionUtility = PermissionUtility()
///
/// // Request camera permission
/// permissionUtility.requestPermission(for: .camera)
///     .sink { granted in
///         if granted {
///             print("Camera permission granted.")
///         } else {
///             print("Camera permission denied.")
///         }
///     }
///     .store(in: &cancellables)
///
/// // Request Bluetooth permission
/// permissionUtility.requestPermission(for: .bluetooth)
///     .sink { granted in
///         if granted {
///             print("Bluetooth permission granted.")
///         } else {
///             print("Bluetooth permission denied.")
///         }
///     }
///     .store(in: &cancellables)
/// ```
public class PermissionUtility: NSObject {
    
    // MARK: - Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // Location Manager
    private var locationManager: CLLocationManager?
    private var locationPermissionCompletion: ((Bool) -> Void)?
    
    // Bluetooth Manager
    private var centralManager: CBCentralManager?
    private var bluetoothStateSubject: PassthroughSubject<CBManagerState, Never>?
    
    public override init() {
        super.init()
        // Managers are initialized when requesting permissions
    }
    
    /// Requests permission for a specified system feature (e.g., camera, photo library, microphone, location, notifications, bluetooth).
    /// - Parameter permissionType: The type of permission to request, defined in the `PermissionType` enum.
    /// - Returns: A `Future` that emits `true` if the permission is granted, and `false` if not.
    public func requestPermission(for permissionType: PermissionType) -> Future<Bool, Never> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.success(false))
                return
            }
            
            switch permissionType {
            case .camera:
                self.requestCameraPermission { granted in
                    promise(.success(granted))
                }
            case .photoLibrary:
                self.requestPhotoLibraryPermission { granted in
                    promise(.success(granted))
                }
            case .microphone:
                self.requestMicrophonePermission { granted in
                    promise(.success(granted))
                }
            case .locationWhenInUse:
                self.requestLocationPermission(always: false) { granted in
                    promise(.success(granted))
                }
            case .locationAlways:
                self.requestLocationPermission(always: true) { granted in
                    promise(.success(granted))
                }
            case .notifications:
                self.requestNotificationPermission { granted in
                    promise(.success(granted))
                }
            case .bluetooth:
                self.requestBluetoothPermission()
                    .sink(receiveValue: { granted in
                        promise(.success(granted))
                    })
                    .store(in: &self.cancellables)
            }
        }
    }
    
    // MARK: - Private Permission Request Methods
    
    private func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        @unknown default:
            completion(false)
        }
    }
    
    private func requestPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized, .limited:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            }
        @unknown default:
            completion(false)
        }
    }
    
    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            completion(true)
        case .denied:
            completion(false)
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        @unknown default:
            completion(false)
        }
    }
    
    private func requestLocationPermission(always: Bool, completion: @escaping (Bool) -> Void) {
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .authorizedAlways:
            completion(always)
        case .authorizedWhenInUse:
            completion(!always)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            // Initialize locationManager
            self.locationManager = CLLocationManager()
            self.locationManager?.delegate = self
            if always {
                self.locationManager?.requestAlwaysAuthorization()
            } else {
                self.locationManager?.requestWhenInUseAuthorization()
            }
            // Store the completion to be called in delegate method
            self.locationPermissionCompletion = completion
        @unknown default:
            completion(false)
        }
    }
    
    private func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized:
                DispatchQueue.main.async {
                    completion(true)
                }
            case .denied:
                DispatchQueue.main.async {
                    completion(false)
                }
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    DispatchQueue.main.async {
                        completion(granted)
                    }
                }
            @unknown default:
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Bluetooth Permission Request
    
    private func requestBluetoothPermission() -> AnyPublisher<Bool, Never> {
        // Initialize bluetoothStateSubject and centralManager
        self.bluetoothStateSubject = PassthroughSubject<CBManagerState, Never>()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        
        return bluetoothStateSubject!
            .receive(on: DispatchQueue.main)
            .map { state -> Bool in
                switch state {
                case .poweredOn:
                    return true
                case .unauthorized, .poweredOff, .resetting, .unsupported, .unknown:
                    return false
                @unknown default:
                    return false
                }
            }
            .first()
            .handleEvents(receiveOutput: { _ in
                // Clean up
                self.bluetoothStateSubject = nil
                self.centralManager = nil
            })
            .eraseToAnyPublisher()
    }
}

// MARK: - CLLocationManagerDelegate

extension PermissionUtility: CLLocationManagerDelegate {
    
    /// Delegate method that is called when the location authorization status changes.
    /// - Parameters:
    ///   - manager: The `CLLocationManager` instance managing the location services.
    ///   - status: The new authorization status for location access.
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard let completion = locationPermissionCompletion else { return }
        
        switch status {
        case .authorizedAlways:
            completion(true)
        case .authorizedWhenInUse:
            completion(false)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            // Still not determined, do nothing
            break
        @unknown default:
            completion(false)
        }
        
        // Clean up
        locationPermissionCompletion = nil
        locationManager = nil
    }
}

// MARK: - CBCentralManagerDelegate

extension PermissionUtility: CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Send the updated state to the subject
        bluetoothStateSubject?.send(central.state)
    }
}
