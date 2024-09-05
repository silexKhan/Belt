//
//  File.swift
//  
//
//  Created by ahn kyu suk on 9/4/24.
//

import Foundation

public enum AssetFilterOption {
    case dateRange(start: Date, end: Date)
    case resolution(minWidth: Int, minHeight: Int)
    case mediaType(MediaType)
}
