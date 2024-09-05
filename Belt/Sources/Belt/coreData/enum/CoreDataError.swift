//
//  CoreDataError.swift
//
//
//  Created by ahn kyu suk on 9/5/24.
//

import Foundation

/// CoreData 관련 에러를 정의하는 커스텀 에러 타입
public enum CoreDataError: Error {
    case saveError(Error)
    case fetchError(Error)
    case deleteError(Error)
    case batchUpdateError(Error)
    case entityNotFound
    case invalidData

    /// 각 에러에 대한 설명을 반환
    public var localizedDescription: String {
        switch self {
        case .saveError(let error):
            return "Save Error: \(error.localizedDescription)"
        case .fetchError(let error):
            return "Fetch Error: \(error.localizedDescription)"
        case .deleteError(let error):
            return "Delete Error: \(error.localizedDescription)"
        case .batchUpdateError(let error):
            return "Batch Update Error: \(error.localizedDescription)"
        case .entityNotFound:
            return "Entity not found."
        case .invalidData:
            return "Invalid data format."
        }
    }
}
