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


public class PermissionUtility: NSObject {
    
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    public override init() {
        super.init()
    }
    
    /// 주어진 권한 타입에 맞는 권한 요청을 처리하는 메서드
    /// - Parameter permissionType: 요청할 권한 타입
    /// - Returns: 권한이 부여되었는지 여부를 비동기적으로 반환하는 `Future`
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

extension PermissionUtility {
    
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
                self.locationManager.requestAlwaysAuthorization()
            } else {
                self.locationManager.requestWhenInUseAuthorization()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                let newStatus = CLLocationManager.authorizationStatus()
                completion(newStatus == (always ? .authorizedAlways : .authorizedWhenInUse))
            }
        @unknown default:
            completion(false)
        }
    }
    
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
