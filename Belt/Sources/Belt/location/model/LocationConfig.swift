//
//  LocationConfig.swift
//
//
//  Created by ahn kyu suk on 9/4/24.
//

import Foundation
import CoreLocation

/// A configuration struct for managing location tracking settings.
/// This struct allows you to customize how frequently location updates are received and how accurate
/// the location data should be. It includes settings for the minimum distance between location updates,
/// the forced update interval, and the acceptable horizontal accuracy for location data.
///
/// - `minimumDistance`: The minimum distance (in meters) that the device must move before a location update is triggered.
/// - `updateInterval`: The minimum time interval (in seconds) between forced location updates, even if the device has not moved.
/// - `horizontalAccuracy`: The maximum acceptable horizontal accuracy (in meters) for a location to be considered valid.
///
/// # Default Values:
/// - `minimumDistance`: 10 meters
/// - `updateInterval`: 30 seconds
/// - `horizontalAccuracy`: 100 meters
///
/// These values can be adjusted to suit the needs of your application for more frequent updates, greater accuracy, or more efficient battery usage.
public struct LocationConfig {
    // 최소 거리(미터)
    var minimumDistance: CLLocationDistance
    // 강제 위치 업데이트 간격 (초)
    var updateInterval: TimeInterval
    // 위치 정확도 허용 범위 (미터)
    var horizontalAccuracy: CLLocationAccuracy
    
    public init(minimumDistance: CLLocationDistance = 10.0, updateInterval: TimeInterval = 30.0, horizontalAccuracy: CLLocationAccuracy = 100.0) {
        self.minimumDistance = minimumDistance
        self.updateInterval = updateInterval
        self.horizontalAccuracy = horizontalAccuracy
    }
}

