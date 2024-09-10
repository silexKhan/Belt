//
//  PermissionType.swift
//
//
//  Created by ahn kyu suk on 9/5/24.
//

import Foundation

/// 1. Camera
/// - key: `NSCameraUsageDescription`
/// - description: "User-facing message explaining why the app requires access to the camera."
/// 2. Photo Library
/// - key: `NSPhotoLibraryUsageDescription`
/// - description: "User-facing message explaining why the app requires access to the photo library."
/// 3. Microphone
/// - key: `NSMicrophoneUsageDescription`
/// - description: "User-facing message explaining why the app requires access to the microphone."
/// 4. Location Services
/// - keys:
///   - `NSLocationWhenInUseUsageDescription`: "User-facing message explaining why the app requires access to location services while the app is in use."
///   - `NSLocationAlwaysUsageDescription`: "User-facing message explaining why the app requires access to location services in the background."
/// 5. Push Notifications
/// - key: `NSUserNotificationUsageDescription`
/// - description: "User-facing message explaining why the app requires push notifications access."
/// Enum defining the list of permissions the app may request.
public enum PermissionType {
    case camera
    case photoLibrary
    case microphone
    case locationWhenInUse
    case locationAlways
    case notifications
}
