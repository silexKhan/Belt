//
//  File.swift
//  
//
//  Created by ahn kyu suk on 9/5/24.
//

import Foundation
import UIKit
/// 클립보드에 복사할 수 있는 데이터 타입을 제한하는 프로토콜
public protocol ClipboardCopyable {}

extension String: ClipboardCopyable {}
extension UIImage: ClipboardCopyable {}
extension URL: ClipboardCopyable {}
extension UIColor: ClipboardCopyable {}
extension Data: ClipboardCopyable {}
