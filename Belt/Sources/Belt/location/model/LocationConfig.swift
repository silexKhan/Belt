//
//  LocationConfig.swift
//
//
//  Created by ahn kyu suk on 9/4/24.
//

import Foundation
import CoreLocation

/// 위치 추적 설정을 위한 Config 구조체
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

