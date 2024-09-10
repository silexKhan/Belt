//
//  LocationUtility.swift
//
//
//  Created by ahn kyu suk on 9/4/24.
//

import Foundation
import CoreLocation
import Combine

/// A utility class for managing location updates and requests using `CLLocationManager`.
/// The class allows requesting one-time location updates as well as continuous tracking of the device's location.
/// It utilizes the `Combine` framework to handle asynchronous location updates and authorization requests,
/// providing a reactive way to manage location data in your app.
///
/// The `LocationUtility` class supports real-time tracking, location authorization requests,
/// and configuration updates such as setting accuracy or minimum distance for updates.
/// Location updates are processed only when they meet certain accuracy and distance conditions,
/// which can be customized through the `LocationConfig` object.
///
/// # Features:
/// - Request one-time location updates
/// - Start and stop continuous location tracking
/// - Request location authorization
/// - Handle location update errors gracefully
///
/// # Usage Example:
///
/// ```swift
/// let locationUtility = LocationUtility()
///
/// // Request location authorization
/// locationUtility.requestLocationAuthorization()
///     .sink { isAuthorized in
///         if isAuthorized {
///             print("Location authorization granted.")
///         } else {
///             print("Location authorization not granted.")
///         }
///     }
///     .store(in: &cancellables)
///
/// // Get current location
/// locationUtility.getCurrentLocation()
///     .sink(receiveCompletion: { completion in
///         switch completion {
///         case .finished:
///             print("Location retrieval finished.")
///         case .failure(let error):
///             print("Error retrieving location: \(error)")
///         }
///     }, receiveValue: { location in
///         print("Current location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
///     })
///     .store(in: &cancellables)
///
/// // Start tracking location
/// locationUtility.startTrackingLocation()
///     .sink(receiveCompletion: { completion in
///         if case .failure(let error) = completion {
///             print("Error tracking location: \(error)")
///         }
///     }, receiveValue: { location in
///         print("Updated location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
///     })
///     .store(in: &cancellables)
///
/// // Stop tracking location
/// locationUtility.stopTrackingLocation()
/// ```
///
/// This example demonstrates how to use `LocationUtility` to request location permissions,
/// retrieve the current location, and start/stop real-time location tracking.
public class LocationUtility: NSObject {
    
    private let locationManager: CLLocationManager
    private var locationSubject = PassthroughSubject<CLLocation, Error>()
    private var lastKnownLocation: CLLocation?
    private var lastUpdateTime: Date = Date()
    
    // 설정 값은 언제든지 업데이트 가능
    private var config: LocationConfig
    
    public init(config: LocationConfig = LocationConfig()) {
        self.locationManager = CLLocationManager()
        self.config = config
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = config.minimumDistance
    }
    
    /// Updates the location configuration with new settings.
    /// - Parameter newConfig: A `LocationConfig` object that contains new settings for location accuracy, update interval, and minimum distance.
    public func updateConfig(_ newConfig: LocationConfig) {
        self.config = newConfig
        self.locationManager.distanceFilter = config.minimumDistance
    }
    
    /// Requests location authorization from the user.
    /// - Returns: A `Future` that emits `true` if location authorization has already been granted, or `false` if authorization is pending or denied.
    public func requestLocationAuthorization() -> Future<Bool, Never> {
        return Future { promise in
            let status = CLLocationManager.authorizationStatus()
            switch status {
            case .notDetermined:
                self.locationManager.requestWhenInUseAuthorization()
                self.locationManager.requestAlwaysAuthorization()
                promise(.success(false)) // 권한 요청 중
            case .authorizedWhenInUse, .authorizedAlways:
                promise(.success(true))
            default:
                promise(.success(false))
            }
        }
    }
    
    /// Requests the current location from the device.
    /// - Returns: An `AnyPublisher` that emits the current location (`CLLocation`) or an error if location retrieval fails.
    public func getCurrentLocation() -> AnyPublisher<CLLocation, Error> {
        locationManager.requestLocation()
        return locationSubject.eraseToAnyPublisher()
    }
    
    /// Starts real-time location tracking.
    /// - Returns: An `AnyPublisher` that emits continuous location updates (`CLLocation`) or an error if tracking fails.
    public func startTrackingLocation() -> AnyPublisher<CLLocation, Error> {
        locationManager.startUpdatingLocation()
        return locationSubject.eraseToAnyPublisher()
    }
    
    /// Stops real-time location tracking and ends the location stream.
    public func stopTrackingLocation() {
        locationManager.stopUpdatingLocation()
        locationSubject.send(completion: .finished) // 위치 추적 중단 시 완료 신호 전달
    }
}

extension LocationUtility {
    
    /// Checks if the location should be updated based on accuracy and timing conditions.
    /// - Parameters:
    ///   - newLocation: The new location data to evaluate.
    ///   - currentTime: The current timestamp to evaluate the update interval.
    /// - Returns: A `Bool` indicating whether the location should be updated.
    private func shouldUpdateLocation(_ newLocation: CLLocation, currentTime: Date) -> Bool {
        // 위치의 정확도가 설정된 범위 내에 있어야 함
        guard newLocation.horizontalAccuracy >= 0 && newLocation.horizontalAccuracy <= config.horizontalAccuracy else {
            return false
        }
        
        // 강제 업데이트 시간 검사
        if currentTime.timeIntervalSince(lastUpdateTime) > config.updateInterval {
            return true
        }
        
        // 마지막 위치와 비교해 최소 거리 이상 차이나는지 확인
        if let lastLocation = lastKnownLocation {
            let distance = newLocation.distance(from: lastLocation)
            return distance >= config.minimumDistance
        }
        
        // 첫 번째 위치일 경우 업데이트 허용
        return true
    }

    /// Updates the location data and sends the updated location through the subject.
    /// - Parameters:
    ///   - newLocation: The new location data to store.
    ///   - currentTime: The current timestamp for last update time reference.
    private func updateLocation(_ newLocation: CLLocation, currentTime: Date) {
        lastKnownLocation = newLocation
        locationSubject.send(newLocation)
        lastUpdateTime = currentTime
    }
}

extension LocationUtility: CLLocationManagerDelegate {
    
    /// Called when `CLLocationManager` provides new location updates.
    /// - Parameters:
    ///   - manager: The `CLLocationManager` providing the updates.
    ///   - locations: An array of `CLLocation` objects representing the updated locations.
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentTime = Date()
        guard let newLocation = locations.last else { return }
        
        // 위치가 업데이트될 조건이 충족되는지 확인
        if shouldUpdateLocation(newLocation, currentTime: currentTime) {
            updateLocation(newLocation, currentTime: currentTime)
        }
    }
    
    /// Called when `CLLocationManager` encounters an error while retrieving locations.
    /// - Parameters:
    ///   - manager: The `CLLocationManager` reporting the error.
    ///   - error: The error that occurred during location retrieval.
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationSubject.send(completion: .failure(error))
        stopTrackingLocation()  // 위치 업데이트 실패 시 추적 중지
    }
    
    /// Called when `CLLocationManager` changes the location authorization status.
    /// - Parameters:
    ///   - manager: The `CLLocationManager` managing the location services.
    ///   - status: The updated `CLAuthorizationStatus` for location access.
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationSubject.send(completion: .finished)
        case .denied, .restricted:
            locationSubject.send(completion: .failure(NSError(domain: "LocationUtility", code: 1, userInfo: [NSLocalizedDescriptionKey: "Location access denied."])))
        default:
            break
        }
    }
}



