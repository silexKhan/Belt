//
//  File.swift
//  
//
//  Created by ahn kyu suk on 9/5/24.
//

/// A utility class for retrieving various information about the current iOS device.
/// This class provides methods to access details such as device name, model, operating system version,
/// battery information, screen resolution, available memory, and storage capacity.
///
/// The class utilizes `UIDevice`, `UIScreen`, and `ProcessInfo` to gather relevant information.
/// For storage details, it uses the file system to check available and total capacity.
///
/// # Usage Example:
///
/// ```swift
/// let deviceInfo = DeviceInfoUtility()
///
/// // Get device name
/// let deviceName = deviceInfo.getDeviceName()
/// print("Device Name: \(deviceName)")
///
/// // Get device model
/// let deviceModel = deviceInfo.getDeviceModel()
/// print("Device Model: \(deviceModel)")
///
/// // Get OS version
/// let osVersion = deviceInfo.getOSVersion()
/// print("OS Version: \(osVersion)")
///
/// // Get battery level
/// let batteryLevel = deviceInfo.getBatteryLevel()
/// print("Battery Level: \(batteryLevel * 100)%")
///
/// // Get screen resolution
/// let screenResolution = deviceInfo.getScreenResolution()
/// print("Screen Resolution: \(screenResolution.width) x \(screenResolution.height)")
///
/// // Get available memory
/// let availableMemory = deviceInfo.getAvailableMemory()
/// print("Available Memory: \(availableMemory) MB")
///
/// // Get storage information
/// if let storageInfo = deviceInfo.getStorageInfo() {
///     print("Available Storage: \(storageInfo.available) MB")
///     print("Total Storage: \(storageInfo.total) MB")
/// } else {
///     print("Failed to retrieve storage information")
/// }
/// ```
import Foundation
import UIKit

public class DeviceInfoUtility {
    
    /// Returns the current device's name.
    /// - Returns: The name of the device (e.g., "John's iPhone").
    public func getDeviceName() -> String {
        return UIDevice.current.name
    }
    
    /// Returns the current device's model.
    /// - Returns: The model of the device (e.g., "iPhone", "iPad").
    public func getDeviceModel() -> String {
        return UIDevice.current.model
    }
    
    /// Returns the current operating system version.
    /// - Returns: The iOS version (e.g., "14.2").
    public func getOSVersion() -> String {
        return UIDevice.current.systemVersion
    }
    
    /// Returns the current battery level of the device.
    /// - Returns: The battery level (0.0 to 1.0).
    public func getBatteryLevel() -> Float {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        UIDevice.current.isBatteryMonitoringEnabled = false  // Disable battery monitoring after use
        return level
    }
    
    /// Returns the current battery state of the device.
    /// - Returns: The battery state (`UIDevice.BatteryState`).
    public func getBatteryState() -> UIDevice.BatteryState {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let state = UIDevice.current.batteryState
        UIDevice.current.isBatteryMonitoringEnabled = false  // Disable battery monitoring after use
        return state
    }
    
    /// Returns the screen resolution of the device in pixels.
    /// - Returns: The screen resolution as a `CGSize` object.
    public func getScreenResolution() -> CGSize {
        let screenSize = UIScreen.main.bounds.size
        let scale = UIScreen.main.scale
        return CGSize(width: screenSize.width * scale, height: screenSize.height * scale)
    }
    
    /// Returns the total physical memory of the device.
    /// - Returns: The total physical memory of the device in megabytes (MB).
    public func getAvailableMemory() -> Double {
        let memoryInfo = ProcessInfo.processInfo.physicalMemory
        return Double(memoryInfo) / 1024.0 / 1024.0
    }
    
    /// Returns information about the device's storage capacity.
    /// - Returns: A tuple containing the available and total storage space in megabytes (MB), or `nil` if an error occurs.
    public func getStorageInfo() -> (available: Double, total: Double)? {
        do {
            let fileURL = URL(fileURLWithPath: NSHomeDirectory() as String)
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey])
            if let available = values.volumeAvailableCapacityForImportantUsage, let total = values.volumeTotalCapacity {
                return (Double(available) / 1024.0 / 1024.0, Double(total) / 1024.0 / 1024.0)
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
}
