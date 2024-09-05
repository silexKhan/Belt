//
//  AssetUtilityTests.swift
//  BeltDemoTests
//
//  Created by ahn kyu suk on 9/4/24.
//

import XCTest
import Combine
import Photos
import Belt
@testable import BeltDemo

class AssetUtilityTests: XCTestCase {
    var assetUtility: AssetUtility!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        assetUtility = AssetUtility()
        cancellables = []
    }

    override func tearDown() {
        assetUtility = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - 권한 테스트
    func testRequestPhotoLibraryAccess_Authorized() {
        let expectation = XCTestExpectation(description: "권한이 승인되었는지 테스트")

        assetUtility.requestPhotoLibraryAccess()
            .sink { isGranted in
                XCTAssertTrue(isGranted, "사진첩 접근 권한이 승인되어야 합니다.")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - 자산 불러오기 테스트
    func testFetchAssets_ReturnsAssets() {
        let expectation = XCTestExpectation(description: "사진첩 자산 불러오기 테스트")

        assetUtility.fetchAssets()
            .sink { assets in
                XCTAssertGreaterThan(assets.count, 0, "자산이 하나 이상 있어야 합니다.")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - 필터링 테스트
    func testFetchAssetsFiltered_ByDateRange() {
        let expectation = XCTestExpectation(description: "사진첩 자산 필터링 테스트")

        let startDate = Calendar.current.date(byAdding: .day, value: -3000, to: Date())!
        let endDate = Date()
        let filterOption = AssetFilterOption.dateRange(start: startDate, end: endDate)

        assetUtility.fetchAssetsFiltered(by: filterOption)
            .sink { assets in
                XCTAssertGreaterThan(assets.count, 0, "필터된 자산이 하나 이상 있어야 합니다.")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - 정렬 테스트
    func testFetchAssetsSorted_ByCreationDate() {
        let expectation = XCTestExpectation(description: "사진첩 자산 정렬 테스트")

        assetUtility.fetchAssetsSorted(by: .creationDate(ascending: true))
            .sink { assets in
                XCTAssertGreaterThan(assets.count, 0, "정렬된 자산이 하나 이상 있어야 합니다.")
                XCTAssertTrue(assets.first!.creationDate! < assets.last!.creationDate!, "정렬된 자산이 올바르게 정렬되어야 합니다.")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - 자산 삭제 테스트
    func testDeleteAssets() {
        let expectation = XCTestExpectation(description: "자산 삭제 테스트")

        assetUtility.fetchAssets()
            .flatMap { assets -> Future<Bool, any Error> in
                return self.assetUtility.deleteAssets(Array(assets.prefix(1))) // 첫 번째 자산 삭제
            }
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("자산 삭제 중 에러 발생: \(error.localizedDescription)")
                }
            }, receiveValue: { success in
                XCTAssertTrue(success, "자산이 성공적으로 삭제되어야 합니다.")
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - 썸네일 생성 테스트
    func testGenerateThumbnail() {
        let expectation = XCTestExpectation(description: "썸네일 생성 테스트")

        assetUtility.fetchAssets()
            .flatMap { assets -> Future<UIImage, any Error> in
                return self.assetUtility.generateThumbnail(for: assets.first!, size: CGSize(width: 100, height: 100))
            }
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("썸네일 생성 중 에러 발생: \(error.localizedDescription)")
                }
            }, receiveValue: { image in
                XCTAssertNotNil(image, "썸네일이 생성되어야 합니다.")
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 5.0)
    }
}
