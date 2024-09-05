//
//  FileUtility.swift
//
//
//  Created by ahn kyu suk on 9/4/24.
//

import Foundation
import Combine

/**
 FileUtility 클래스는 iOS에서 파일 및 디렉토리를 관리하는 기능을 제공하는 유틸리티 클래스입니다.
 파일 시스템에 접근하여 파일을 읽고, 쓰고, 삭제하는 작업을 간편하게 수행할 수 있습니다.
 
 주요 기능:
 - **파일 읽기/쓰기**: 지정된 경로에서 파일을 읽거나 씁니다.
 - **파일 존재 여부 확인**: 파일이 존재하는지 확인합니다.
 - **파일 삭제**: 지정된 파일을 삭제합니다.
 - **파일 크기 확인**: 파일의 크기를 반환합니다.
 - **디렉토리 생성 및 파일 목록 불러오기**: 디렉토리를 생성하고, 그 안에 있는 파일들의 목록을 불러옵니다.
 - **파일 이동 및 복사**: 파일을 다른 경로로 이동하거나 복사합니다.
 
 이 클래스는 파일 시스템 작업을 쉽게 관리할 수 있도록 도와줍니다.
 */
public class FileUtility {
    
    private let fileManager: FileManager
    
    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    /// 지정된 기본 디렉토리의 경로를 가져오는 공통 메서드
    /// - Parameters:
    ///   - directory: 기본 디렉토리 (`FileManager.SearchPathDirectory`)
    ///   - path: 디렉토리 내부의 세부 경로
    /// - Returns: 디렉토리 경로를 포함한 파일 URL 또는 에러
    private func fileURL(at directory: FileManager.SearchPathDirectory, path: String) -> Result<URL, Error> {
        if let directoryURL = fileManager.urls(for: directory, in: .userDomainMask).first {
            let fileURL = directoryURL.appendingPathComponent(path)
            return .success(fileURL)
        } else {
            let error = NSError(domain: "FileUtility", code: 1, userInfo: [NSLocalizedDescriptionKey: "디렉토리 경로를 찾을 수 없습니다."])
            return .failure(error)
        }
    }
    
    /// 파일이 존재하는지 확인하는 메서드
    /// - Parameters:
    ///   - directory: 파일이 위치한 기본 디렉토리 (`FileManager.SearchPathDirectory`)
    ///   - path: 디렉토리 내부의 세부 경로
    /// - Returns: 파일이 존재하면 `true`, 존재하지 않으면 `false`를 반환하는 `Future`
    public func fileExists(at directory: FileManager.SearchPathDirectory, path: String) -> Future<Bool, Never> {
        return Future { promise in
            switch self.fileURL(at: directory, path: path) {
            case .success(let fileURL):
                let exists = self.fileManager.fileExists(atPath: fileURL.path)
                promise(.success(exists))
            case .failure:
                promise(.success(false))
            }
        }
    }
    
    /// 파일을 읽어 문자열로 반환하는 메서드
    /// - Parameters:
    ///   - directory: 파일이 위치한 기본 디렉토리 (`FileManager.SearchPathDirectory`)
    ///   - path: 디렉토리 내부의 세부 경로
    /// - Returns: 파일의 내용을 비동기적으로 반환하는 `Future`
    public func readFile(at directory: FileManager.SearchPathDirectory, path: String) -> Future<String?, Error> {
        return Future { promise in
            switch self.fileURL(at: directory, path: path) {
            case .success(let fileURL):
                do {
                    let content = try String(contentsOf: fileURL, encoding: .utf8)
                    promise(.success(content))
                } catch {
                    promise(.failure(error))
                }
            case .failure(let error):
                promise(.failure(error))
            }
        }
    }
    
    
    /// 파일을 저장하는 메서드
    /// - Parameters:
    ///   - content: 파일에 쓸 내용
    ///   - directory: 파일을 저장할 기본 디렉토리 (`FileManager.SearchPathDirectory`)
    ///   - path: 디렉토리 내부의 세부 경로
    /// - Returns: 성공 여부를 비동기적으로 반환하는 `Future`
    public func writeFile(content: String, at directory: FileManager.SearchPathDirectory, path: String) -> Future<Bool, Error> {
        return Future { promise in
            switch self.fileURL(at: directory, path: path) {
            case .success(let fileURL):
                do {
                    try content.write(to: fileURL, atomically: true, encoding: .utf8)
                    promise(.success(true))
                } catch {
                    promise(.failure(error))
                }
            case .failure(let error):
                promise(.failure(error))
            }
        }
    }
    
    /// 파일을 삭제하는 메서드
    /// - Parameters:
    ///   - directory: 파일이 위치한 기본 디렉토리 (`FileManager.SearchPathDirectory`)
    ///   - path: 디렉토리 내부의 세부 경로
    /// - Returns: 성공 여부를 비동기적으로 반환하는 `Future`
    public func deleteFile(at directory: FileManager.SearchPathDirectory, path: String) -> Future<Bool, Error> {
        return Future { promise in
            switch self.fileURL(at: directory, path: path) {
            case .success(let fileURL):
                do {
                    try self.fileManager.removeItem(at: fileURL)
                    promise(.success(true))
                } catch {
                    promise(.failure(error))
                }
            case .failure(let error):
                promise(.failure(error))
            }
        }
    }
    
    /// 주어진 파일의 크기를 가져오는 메서드
    /// - Parameters:
    ///   - directory: 파일이 위치한 기본 디렉토리 (`FileManager.SearchPathDirectory`)
    ///   - path: 파일 경로
    /// - Returns: 파일 크기를 비동기적으로 반환하는 `Future`
    public func fileSize(at directory: FileManager.SearchPathDirectory, path: String) -> Future<Int64, Error> {
        return Future { promise in
            switch self.fileURL(at: directory, path: path) {
            case .success(let fileURL):
                do {
                    let fileAttributes = try self.fileManager.attributesOfItem(atPath: fileURL.path)
                    if let fileSize = fileAttributes[.size] as? Int64 {
                        promise(.success(fileSize))
                    } else {
                        promise(.failure(NSError(domain: "FileUtility", code: 1, userInfo: [NSLocalizedDescriptionKey: "파일 크기를 가져올 수 없습니다."])))
                    }
                } catch {
                    promise(.failure(error))
                }
            case .failure(let error):
                promise(.failure(error))
            }
        }
    }
    
    /// 주어진 경로에 디렉토리를 생성하는 메서드
    /// - Parameters:
    ///   - directory: 기본 디렉토리 (`FileManager.SearchPathDirectory`)
    ///   - path: 생성할 디렉토리의 세부 경로
    /// - Returns: 성공 여부를 비동기적으로 반환하는 `Future`
    public func createDirectory(at directory: FileManager.SearchPathDirectory, path: String) -> Future<Bool, Error> {
        return Future { promise in
            switch self.fileURL(at: directory, path: path) {
            case .success(let directoryURL):
                do {
                    try self.fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
                    promise(.success(true))
                } catch {
                    promise(.failure(error))
                }
            case .failure(let error):
                promise(.failure(error))
            }
        }
    }
    
    /// 디렉토리에서 파일 목록을 가져오는 메서드
    /// - Parameters:
    ///   - directory: 파일 목록을 가져올 기본 디렉토리 (`FileManager.SearchPathDirectory`)
    /// - Returns: 파일 URL 배열을 비동기적으로 반환하는 `Future`
    public func listFiles(in directory: FileManager.SearchPathDirectory) -> Future<[URL], Error> {
        return Future { promise in
            switch self.fileURL(at: directory, path: "") {
            case .success(let directoryURL):
                do {
                    let fileURLs = try self.fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: [])
                    promise(.success(fileURLs))
                } catch {
                    promise(.failure(error))
                }
            case .failure(let error):
                promise(.failure(error))
            }
        }
    }
    
    /// 파일을 이동하는 메서드
    /// - Parameters:
    ///   - fromDirectory: 원본 파일이 위치한 디렉토리 (`FileManager.SearchPathDirectory`)
    ///   - fromPath: 원본 파일 경로
    ///   - toDirectory: 이동할 위치의 디렉토리 (`FileManager.SearchPathDirectory`)
    ///   - toPath: 이동할 파일 경로
    /// - Returns: 성공 여부를 비동기적으로 반환하는 `Future`
    public func moveFile(from fromDirectory: FileManager.SearchPathDirectory, fromPath: String, to toDirectory: FileManager.SearchPathDirectory, toPath: String) -> Future<Bool, Error> {
        return Future { promise in
            switch (self.fileURL(at: fromDirectory, path: fromPath), self.fileURL(at: toDirectory, path: toPath)) {
            case (.success(let sourceURL), .success(let destinationURL)):
                do {
                    try self.fileManager.moveItem(at: sourceURL, to: destinationURL)
                    promise(.success(true))
                } catch {
                    promise(.failure(error))
                }
            case (.failure(let sourceError), _):
                promise(.failure(sourceError))
            case (_, .failure(let destinationError)):
                promise(.failure(destinationError))
            }
        }
    }
    
}
