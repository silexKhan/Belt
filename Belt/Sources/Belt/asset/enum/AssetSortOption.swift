//
//  AssetSortOption.swift
//  
//
//  Created by ahn kyu suk on 9/4/24.
//

import Foundation

/// The `AssetSortOption` enum defines the options that can be used to sort assets in the photo library.
/// With this option, you can sort assets by creation date, modification date, or file size.
public enum AssetSortOption {
    
    /// Sort assets by creation date.
    /// - Parameter ascending: If `true`, sorts in ascending order; if `false`, sorts in descending order.
    case creationDate(ascending: Bool)
    
    /// Sort assets by modification date.
    /// - Parameter ascending: If `true`, sorts in ascending order; if `false`, sorts in descending order.
    case modificationDate(ascending: Bool)
    
    /// Sort assets by file size.
    /// - Parameter ascending: If `true`, sorts in ascending order; if `false`, sorts in descending order.
    case fileSize(ascending: Bool)
}
