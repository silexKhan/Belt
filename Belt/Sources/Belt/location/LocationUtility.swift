//
//  LocationUtility.swift
//
//
//  Created by ahn kyu suk on 9/4/24.
//

import Foundation
import Combine
import CoreLocation

/**
 LocationUtility 클래스는 iOS에서 위치 관련 작업을 관리하는 유틸리티 클래스입니다.
 사용자의 위치 정보를 받아오고, 실시간 위치 추적을 할 수 있으며, 권한 요청도 관리합니다.
 
 주요 기능:
 - **위치 권한 요청**: 앱이 위치 정보를 사용할 수 있도록 권한을 요청합니다.
 - **실시간 위치 추적**: 사용자의 실시간 위치를 추적하여 업데이트합니다.
 - **위치 업데이트 조건 설정**: 위치 업데이트의 최소 거리, 정확도 등을 설정할 수 있습니다.
 - **정확한 위치 정보 필터링**: 설정된 조건에 따라 정확도와 최소 거리 등의 조건을 만족하는 위치 정보만 외부로 전송합니다.
 
 이 유틸리티는 GPS 및 위치 기반 기능을 간편하게 구현할 수 있도록 설계되었습니다.
 */
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
    }
    
    /// 위치 설정을 업데이트하는 메서드
    /// - Parameter newConfig: 새로운 위치 설정
    public func updateConfig(_ newConfig: LocationConfig) {
        self.config = newConfig
    }
    
    /// 위치 권한을 요청하는 메서드
    public func requestLocationAuthorization() -> Future<Bool, Never> {
        return Future { promise in
            let status = CLLocationManager.authorizationStatus()
            switch status {
            case .notDetermined:
                self.locationManager.requestWhenInUseAuthorization()
                promise(.success(false))
            case .authorizedWhenInUse, .authorizedAlways:
                promise(.success(true))
            default:
                promise(.success(false))
            }
        }
    }
    
    /// 현재 위치를 요청하는 메서드
    /// - Returns: 현재 위치를 비동기적으로 반환하는 `AnyPublisher`
    public func getCurrentLocation() -> AnyPublisher<CLLocation, Error> {
        locationManager.requestLocation()
        return locationSubject.eraseToAnyPublisher()
    }
    
    /// 실시간 위치 추적을 시작하는 메서드
    public func startTrackingLocation() -> AnyPublisher<CLLocation, Error> {
        locationManager.startUpdatingLocation()
        return locationSubject.eraseToAnyPublisher()
    }
    
    /// 실시간 위치 추적을 중지하는 메서드
    public func stopTrackingLocation() {
        locationManager.stopUpdatingLocation()
    }
}

extension LocationUtility {
    
    /// 위치를 업데이트해야 하는지 검사하는 함수
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

    /// 위치를 업데이트하고 상태를 저장하는 함수
    private func updateLocation(_ newLocation: CLLocation, currentTime: Date) {
        lastKnownLocation = newLocation
        locationSubject.send(newLocation)
        lastUpdateTime = currentTime
    }
}

extension LocationUtility: CLLocationManagerDelegate {
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentTime = Date()
        guard let newLocation = locations.last else { return }
        
        // 위치가 업데이트될 조건이 충족되는지 확인
        if shouldUpdateLocation(newLocation, currentTime: currentTime) {
            updateLocation(newLocation, currentTime: currentTime)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationSubject.send(completion: .failure(error))
    }
}


