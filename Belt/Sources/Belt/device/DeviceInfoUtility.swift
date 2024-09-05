//
//  File.swift
//  
//
//  Created by ahn kyu suk on 9/5/24.
//

/// `DeviceInfoUtility`는 iOS 디바이스와 관련된 다양한 정보를 제공하는 유틸리티 클래스입니다.
/// 이 유틸리티를 사용하여 기기 이름, 모델, 운영체제 버전, 배터리 상태, 화면 해상도, 메모리 상태, 저장 공간 등의 정보를 쉽게 조회할 수 있습니다.
///
/// ### 주요 기능:
/// - 기기 이름, 모델, 운영체제 버전 확인
/// - 배터리 상태 및 레벨 확인
/// - 디바이스 화면 해상도 조회
/// - 사용 가능한 메모리 및 저장 공간 확인
///
/// ### 사용 예시:
/// ```swift
/// let deviceInfo = DeviceInfoUtility()
///
/// // 기기 이름 확인
/// print("Device Name: \(deviceInfo.getDeviceName())")
///
/// // 운영체제 버전 확인
/// print("OS Version: \(deviceInfo.getOSVersion())")
///
/// // 배터리 레벨 확인
/// print("Battery Level: \(deviceInfo.getBatteryLevel())")
///
/// // 화면 해상도 확인
/// print("Screen Resolution: \(deviceInfo.getScreenResolution())")
///
/// // 메모리 상태 확인
/// print("Available Memory: \(deviceInfo.getAvailableMemory()) MB")
///
/// // 저장 공간 정보 확인
/// if let storageInfo = deviceInfo.getStorageInfo() {
///     print("Available Storage: \(storageInfo.available) MB, Total Storage: \(storageInfo.total) MB")
/// }
/// ```

import Foundation
import UIKit

public class DeviceInfoUtility {
    
    /// 현재 기기의 이름을 반환합니다.
    /// - Returns: 기기의 이름 (예: "John's iPhone")
    public func getDeviceName() -> String {
        return UIDevice.current.name
    }
    
    /// 현재 기기의 모델을 반환합니다.
    /// - Returns: 기기의 모델명 (예: "iPhone", "iPad")
    public func getDeviceModel() -> String {
        return UIDevice.current.model
    }
    
    /// 현재 운영체제의 버전을 반환합니다.
    /// - Returns: iOS 운영체제 버전 (예: "14.2")
    public func getOSVersion() -> String {
        return UIDevice.current.systemVersion
    }
    
    /// 배터리 레벨을 반환합니다.
    /// - Returns: 배터리 레벨 (0.0 ~ 1.0)
    public func getBatteryLevel() -> Float {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryLevel
    }
    
    /// 배터리 상태를 반환합니다.
    /// - Returns: 배터리 상태 (`UIDevice.BatteryState`)
    public func getBatteryState() -> UIDevice.BatteryState {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryState
    }
    
    /// 화면 해상도 정보를 반환합니다.
    /// - Returns: 화면 해상도 정보 (`CGSize`)
    public func getScreenResolution() -> CGSize {
        let screenSize = UIScreen.main.bounds.size
        let scale = UIScreen.main.scale
        return CGSize(width: screenSize.width * scale, height: screenSize.height * scale)
    }
    
    /// 사용 가능한 메모리 정보를 반환합니다.
    /// - Returns: 사용 가능한 메모리 크기 (MB 단위)
    public func getAvailableMemory() -> Double {
        let memoryInfo = ProcessInfo.processInfo.physicalMemory
        return Double(memoryInfo) / 1024.0 / 1024.0
    }
    
    /// 디바이스의 저장 공간 정보를 반환합니다.
    /// - Returns: 저장 공간 정보 (사용 가능한 공간, 총 공간) (단위: MB)
    public func getStorageInfo() -> (available: Double, total: Double)? {
        do {
            let fileURL = URL(fileURLWithPath: NSHomeDirectory() as String)
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey])
            if let available = values.volumeAvailableCapacityForImportantUsageKey, let total = values.volumeTotalCapacityKey {
                return (Double(available) / 1024.0 / 1024.0, Double(total) / 1024.0 / 1024.0)
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
}
