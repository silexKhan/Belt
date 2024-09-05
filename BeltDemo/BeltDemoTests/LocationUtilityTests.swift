//
//  LocationUtilityTests.swift
//  BeltDemoTests
//
//  Created by ahn kyu suk on 9/4/24.
//

import XCTest
import Combine
import CoreLocation
import Belt
@testable import BeltDemo

class LocationUtilityTests: XCTestCase {
    
    var locationUtility: LocationUtility!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        locationUtility = LocationUtility()
        cancellables = []
    }
    
    override func tearDown() {
        locationUtility = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - 위치 권한 요청 테스트
    func testRequestLocationAuthorization() {
        let expectation = XCTestExpectation(description: "위치 권한 요청")
        
        locationUtility.requestLocationAuthorization()
            .sink { isGranted in
                XCTAssertTrue(isGranted, "위치 권한이 부여되어야 합니다.")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - 현재 위치 가져오기 테스트
    func testGetCurrentLocation() {
        let expectation = XCTestExpectation(description: "현재 위치 가져오기")
        
        locationUtility.getCurrentLocation()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    XCTFail("위치 가져오기 실패: \(error.localizedDescription)")
                case .finished:
                    break
                }
            }, receiveValue: { location in
                XCTAssertNotNil(location, "위치를 성공적으로 받아야 합니다.")
                expectation.fulfill()
            })
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - 실시간 위치 추적 테스트
    func testStartTrackingLocation() {
        let expectation = XCTestExpectation(description: "실시간 위치 추적")
        
        locationUtility.startTrackingLocation()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    XCTFail("위치 추적 실패: \(error.localizedDescription)")
                case .finished:
                    break
                }
            }, receiveValue: { location in
                XCTAssertNotNil(location, "실시간 위치 정보를 받아야 합니다.")
                expectation.fulfill()
            })
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
        
        locationUtility.stopTrackingLocation()
    }
}
