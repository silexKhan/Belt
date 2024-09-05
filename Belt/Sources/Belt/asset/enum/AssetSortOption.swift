//
//  File.swift
//  
//
//  Created by ahn kyu suk on 9/4/24.
//

import Foundation

/// `AssetSortOption` 열거형은 사진첩 자산을 정렬하는 데 사용할 수 있는 옵션들을 정의합니다.
/// 이 옵션을 사용하여 자산을 생성일, 수정일 또는 파일 크기 기준으로 정렬할 수 있습니다.
public enum AssetSortOption {
    
    /// 자산을 생성일 기준으로 정렬합니다.
    /// - Parameter ascending: `true`이면 오름차순으로 정렬하고, `false`이면 내림차순으로 정렬합니다.
    case creationDate(ascending: Bool)
    
    /// 자산을 수정일 기준으로 정렬합니다.
    /// - Parameter ascending: `true`이면 오름차순으로 정렬하고, `false`이면 내림차순으로 정렬합니다.
    case modificationDate(ascending: Bool)
    
    /// 자산을 파일 크기 기준으로 정렬합니다.
    /// - Parameter ascending: `true`이면 오름차순으로 정렬하고, `false`이면 내림차순으로 정렬합니다.
    case fileSize(ascending: Bool)
}
