//
//  File.swift
//  
//
//  Created by ahn kyu suk on 9/4/24.
//

import Foundation
import CoreLocation

public struct AssetMetadata {
    
    let fileSize: Int
    let resolution: CGSize
    let creationDate: Date?
    let location: CLLocation?
}
