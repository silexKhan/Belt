//
//  BeltUtility.swift
//  BeltDemo
//
//  Created by ahn kyu suk on 9/10/24.
//

import Foundation
import UIKit

enum BeltUtility: CaseIterable {
    
    case animation
    case asset
    case audio
    case bluetooth
    case clipboard
    case coreData
    case device
    case file
    case keychain
    case location
    case network
    case notification
    case permission
    case reachability
    case userdefault
    
    var identifier: String {
        switch self {
        case .animation:        return "Animation"
        case .asset:            return "Asset"
        case .audio:            return "Audio"
        case .bluetooth:        return "Bluetooth"
        case .clipboard:        return "Clipboard"
        case .coreData:         return "CoreData"
        case .device:           return "Device"
        case .file:             return "File"
        case .keychain:         return "Keychain"
        case .location:         return "Location"
        case .network:          return "Network"
        case .notification:     return "Notification"
        case .permission:       return "Permission"
        case .reachability:     return "Reachability"
        case .userdefault:      return "UserDefault"
        }
    }
    
    var viewController: UIViewController? {
        return initialViewController()
    }
    
    private func initialViewController() -> UIViewController? {
        guard !identifier.isEmpty else {
            print("Storyboard name is empty for \(self).")
            return nil
        }
        let storyboard = UIStoryboard(name: identifier, bundle: .main)
        return storyboard.instantiateInitialViewController()
    }
}
