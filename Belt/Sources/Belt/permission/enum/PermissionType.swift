//
//  PermissionType.swift
//
//
//  Created by ahn kyu suk on 9/5/24.
//

import Foundation
import AVFoundation
import Photos
import CoreLocation
import UserNotifications

/*
 1. 카메라 (Camera)
 - key: `NSCameraUsageDescription`
 - descript: "앱이 카메라를 사용하는 이유를 설명하는 사용자 메시지"

 2. 사진첩 (Photo Library)
 - key: `NSPhotoLibraryUsageDescription`
 - descript: "앱이 사진첩에 접근하는 이유를 설명하는 사용자 메시지"

 3. 마이크 (Microphone)
 - key: `NSMicrophoneUsageDescription`
 - descript: "앱이 마이크를 사용하는 이유를 설명하는 사용자 메시지"

 4. 위치 정보 (Location Services)
 - key:
    - `NSLocationWhenInUseUsageDescription`: "앱 사용 중 위치 정보를 요청하는 이유를 설명하는 사용자 메시지"
    - `NSLocationAlwaysUsageDescription`: "백그라운드에서도 위치 정보를 사용하는 이유를 설명하는 사용자 메시지"

 5. 푸시 알림 (Push Notifications)
 - key: `NSUserNotificationUsageDescription`
 - descript: "앱이 푸시 알림을 사용하는 이유를 설명하는 사용자 메시지"
*/

/// 앱에서 요청할 수 있는 권한 목록을 정의하는 Enum
public enum PermissionType {
    
    case camera
    case photoLibrary
    case microphone
    case locationWhenInUse
    case locationAlways
    case notifications
    
}
