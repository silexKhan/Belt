//
//  PermissionUtility.swift
//
//
//  Created by ahn kyu suk on 9/5/24.
//

import Foundation
import Combine
import AVFoundation
import Photos
import CoreLocation
import UserNotifications

/// A utility class for managing permissions for various system features such as camera, photo library, microphone, location, and notifications.
/// It uses the `Combine` framework to handle asynchronous permission requests and returns the results via `Future`.
///
/// This class handles permission requests for the following:
/// - Camera
/// - Photo Library
/// - Microphone
/// - Location (When In Use, Always)
/// - Notifications
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
/// // Request location permission (Always)
/// permissionUtility.requestPermission(for: .locationAlways)
///     .sink { granted in
///         if granted {
///             print("Location (Always) permission granted.")
///         } else {
///             print("Location (Always) permission denied.")
///         }
///     }
///     .store(in: &cancellables)
/// ```
///
/// This example demonstrates how to request various system permissions using `PermissionUtility` and handle the result reactively.
public class PermissionUtility: NSObject {
    
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    public override init() {
        super.init()
        locationManager.delegate = self
    }
    
    /// Requests permission for a specified system feature (e.g., camera, photo library, microphone, location, notifications).
    /// - Parameter permissionType: The type of permission to request, defined in the `PermissionType` enum.
    /// - Returns: A `Future` that emits `true` if the permission is granted, and `false` if not.
    public func requestPermission(for permissionType: PermissionType) -> Future<Bool, Never> {
        return Future { promise in
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
            }
        }
    }
}

extension PermissionUtility: CLLocationManagerDelegate {
    
    /// Requests camera access permission from the user.
    /// - Parameter completion: A closure that is called with `true` if the permission is granted, or `false` if denied.
    private func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(granted)
            }
        @unknown default:
            completion(false)
        }
    }
    /// Requests access to the photo library from the user.
    /// - Parameter completion: A closure that is called with `true` if access is granted, or `false` if denied.
    private func requestPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized, .limited:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                completion(newStatus == .authorized || newStatus == .limited)
            }
        @unknown default:
            completion(false)
        }
    }
    /// Requests microphone access permission from the user.
    /// - Parameter completion: A closure that is called with `true` if the permission is granted, or `false` if denied.
    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            completion(true)
        case .denied:
            completion(false)
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                completion(granted)
            }
        @unknown default:
            completion(false)
        }
    }
    /// Requests location permission (either "when in use" or "always") from the user.
    /// - Parameters:
    ///   - always: A boolean indicating whether "always" location access is requested. If `false`, "when in use" access is requested.
    ///   - completion: A closure that is called with `true` if the permission is granted, or `false` if denied.
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
            if always {
                locationManager.requestAlwaysAuthorization()
            } else {
                locationManager.requestWhenInUseAuthorization()
            }
        @unknown default:
            completion(false)
        }
    }
    
    /// Delegate method that is called when the location authorization status changes.
    /// - Parameters:
    ///   - manager: The `CLLocationManager` instance managing the location services.
    ///   - status: The new authorization status for location access.
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            // Handle location permission granted
        } else if status == .denied {
            // Handle location permission denied
        }
    }
    
    /// Requests notification permission from the user.
    /// - Parameter completion: A closure that is called with `true` if the permission is granted, or `false` if denied.
    private func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized:
                completion(true)
            case .denied:
                completion(false)
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    completion(granted)
                }
            @unknown default:
                completion(false)
            }
        }
    }
}
