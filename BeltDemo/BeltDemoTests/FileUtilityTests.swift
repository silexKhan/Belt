//
//  FileUtilityTests.swift
//  BeltDemoTests
//
//  Created by ahn kyu suk on 9/4/24.
//

import XCTest
import Combine
import Belt
@testable import BeltDemo

class FileUtilityTests: XCTestCase {

    var fileUtility: FileUtility!
    var cancellables: Set<AnyCancellable>!
    let testDirectory = FileManager.SearchPathDirectory.documentDirectory
    
    override func setUp() {
        super.setUp()
        fileUtility = FileUtility()
        cancellables = []
    }
    
    override func tearDown() {
        super.tearDown()
        cancellables = nil
    }
    
    // MARK: - 파일 존재 여부 확인 테스트
    func testFileExists() {
        let testFileName = "testFileExists.txt"
        let testData = "테스트 데이터"
        
        // 파일 생성
        let writeExpectation = XCTestExpectation(description: "파일 쓰기 성공")
        fileUtility.writeFile(content: testData, at: testDirectory, path: testFileName)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    XCTFail("파일 생성 실패: \(error.localizedDescription)")
                case .finished:
                    writeExpectation.fulfill()
                }
            } receiveValue: { success in
                XCTAssertTrue(success, "파일이 성공적으로 생성되어야 합니다.")
            }
            .store(in: &cancellables)
        
        wait(for: [writeExpectation], timeout: 1.0)
        
        // 파일 존재 여부 확인
        let expectation = XCTestExpectation(description: "파일 존재 여부 확인")
        fileUtility.fileExists(at: testDirectory, path: testFileName)
            .sink { exists in
                XCTAssertTrue(exists, "파일이 존재해야 합니다.")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)

        // 테스트 후 파일 삭제
        let deleteExpectation = XCTestExpectation(description: "파일 삭제 성공")
        fileUtility.deleteFile(at: testDirectory, path: testFileName)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    XCTFail("파일 삭제 실패: \(error.localizedDescription)")
                case .finished:
                    deleteExpectation.fulfill()
                }
            } receiveValue: { success in
                XCTAssertTrue(success, "파일이 성공적으로 삭제되어야 합니다.")
            }
            .store(in: &cancellables)

        wait(for: [deleteExpectation], timeout: 1.0)
    }

    // MARK: - 파일 읽기 테스트
    func testReadFile() {
        let testFileName = "testReadFile.txt"
        let testData = "테스트 데이터"
        
        // 파일 생성
        let writeExpectation = XCTestExpectation(description: "파일 쓰기 성공")
        fileUtility.writeFile(content: testData, at: testDirectory, path: testFileName)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    XCTFail("파일 생성 실패: \(error.localizedDescription)")
                case .finished:
                    writeExpectation.fulfill()
                }
            } receiveValue: { success in
                XCTAssertTrue(success, "파일이 성공적으로 생성되어야 합니다.")
            }
            .store(in: &cancellables)
        
        wait(for: [writeExpectation], timeout: 1.0)
        
        // 파일 읽기
        let expectation = XCTestExpectation(description: "파일 읽기 성공")
        fileUtility.readFile(at: testDirectory, path: testFileName)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    XCTFail("파일 읽기 실패: \(error.localizedDescription)")
                case .finished:
                    expectation.fulfill()
                }
            } receiveValue: { content in
                XCTAssertEqual(content, testData, "읽어온 내용이 일치해야 합니다.")
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)

        // 테스트 후 파일 삭제
        let deleteExpectation = XCTestExpectation(description: "파일 삭제 성공")
        fileUtility.deleteFile(at: testDirectory, path: testFileName)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    XCTFail("파일 삭제 실패: \(error.localizedDescription)")
                case .finished:
                    deleteExpectation.fulfill()
                }
            } receiveValue: { success in
                XCTAssertTrue(success, "파일이 성공적으로 삭제되어야 합니다.")
            }
            .store(in: &cancellables)

        wait(for: [deleteExpectation], timeout: 1.0)
    }

    // MARK: - 파일 쓰기 테스트
    func testWriteFile() {
        let testFileName = "testWriteFile.txt"
        let testData = "새로운 테스트 데이터"
        
        // 파일 쓰기
        let expectation = XCTestExpectation(description: "파일 쓰기 성공")
        fileUtility.writeFile(content: testData, at: testDirectory, path: testFileName)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    XCTFail("파일 쓰기 실패: \(error.localizedDescription)")
                case .finished:
                    expectation.fulfill()
                }
            } receiveValue: { success in
                XCTAssertTrue(success, "파일이 성공적으로 작성되어야 합니다.")
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)

        // 테스트 후 파일 삭제
        let deleteExpectation = XCTestExpectation(description: "파일 삭제 성공")
        fileUtility.deleteFile(at: testDirectory, path: testFileName)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    XCTFail("파일 삭제 실패: \(error.localizedDescription)")
                case .finished:
                    deleteExpectation.fulfill()
                }
            } receiveValue: { success in
                XCTAssertTrue(success, "파일이 성공적으로 삭제되어야 합니다.")
            }
            .store(in: &cancellables)

        wait(for: [deleteExpectation], timeout: 1.0)
    }

    // 나머지 테스트 메서드들도 위와 같이 파일 생성, 테스트 후 삭제 과정을 추가하면 됩니다.
}
