//
//  ClipboardUtility.swift
//
//
//  Created by ahn kyu suk on 9/5/24.
//

/// `ClipboardUtility`는 iOS의 클립보드를 관리하는 유틸리티 클래스입니다.
/// 텍스트, 이미지, URL, UIColor, Codable 객체 등을 클립보드에 복사하거나 클립보드로부터 가져오는 작업을 제공합니다.
/// 제네릭을 사용하여 타입에 따라 적절한 데이터를 클립보드에 저장하고 가져올 수 있습니다.
///
/// - 텍스트, 이미지, URL, UIColor 등과 같은 일반 데이터 타입을 복사 및 가져오기
/// - `Codable` 객체를 JSON 형식으로 클립보드에 저장 및 복사 가능
/// - 클립보드를 초기화하는 기능도 제공
///
/// ### 주요 기능:
/// - `copy<T>(_:)`: 제네릭을 사용해 클립보드에 데이터를 복사합니다. `ClipboardCopyable` 및 `Codable` 타입 모두 지원.
/// - `get<T>(_:)`: 제네릭을 사용해 클립보드에서 데이터를 가져옵니다.
/// - 텍스트, 이미지, URL, UIColor, Data 등 일반적인 타입과 `Codable` 객체도 지원.
///
/// ### 사용 예시:
/// ```swift
/// let clipboardUtility = ClipboardUtility()
///
/// // 텍스트 복사 및 가져오기
/// clipboardUtility.copy("Hello, Clipboard!")
/// if let text: String = clipboardUtility.get(String.self) {
///     print("클립보드에 저장된 텍스트: \(text)")
/// }
///
/// // 이미지 복사 및 가져오기
/// if let image = UIImage(named: "exampleImage") {
///     clipboardUtility.copy(image)
///     if let clipboardImage: UIImage = clipboardUtility.get(UIImage.self) {
///         print("클립보드에 저장된 이미지: \(clipboardImage)")
///     }
/// }
///
/// // Codable 객체 복사 및 가져오기
/// struct MyCodableModel: Codable {
///     let id: Int
///     let name: String
/// }
///
/// let model = MyCodableModel(id: 1, name: "Test")
/// clipboardUtility.copy(model)
/// if let retrievedModel: MyCodableModel = clipboardUtility.get(MyCodableModel.self) {
///     print("복사된 Codable 모델: \(retrievedModel)")
/// }
/// ```
///
/// ### 제한 사항:
/// 클립보드에 너무 큰 데이터를 복사하면 성능이 저하될 수 있습니다. 데이터 크기에 주의하여 사용하세요.

import Foundation
import UIKit


public class ClipboardUtility {
    
    public init() {}

    /// 클립보드에 데이터를 복사하는 제네릭 함수 (텍스트, 이미지, URL, UIColor 등)
    /// Codable 타입이면 JSON으로 인코딩하여 복사합니다.
    /// - Parameter value: 복사할 값 (텍스트, 이미지, URL, UIColor 등 또는 Codable 객체)
    public func copy<T>(_ value: T) {
        if let value = value as? ClipboardCopyable {
            copyClipboardCopyable(value)
        } else if let value = value as? Codable {
            copyCodable(value)
        } else {
            print("지원되지 않는 데이터 타입입니다.")
        }
    }
    
    /// ClipboardCopyable 타입 데이터를 클립보드에서 가져오는 함수
    /// - Parameter type: 가져올 ClipboardCopyable 타입
    /// - Returns: 클립보드에 저장된 값
    public func get<T: ClipboardCopyable>(_ type: T.Type) -> T? {
        return getClipboardCopyable(type) as? T
    }

    /// Codable 타입 데이터를 클립보드에서 가져오는 함수
    /// - Parameter type: 가져올 Codable 타입
    /// - Returns: 클립보드에 저장된 Codable 객체
    public func get<T: Codable>(_ type: T.Type) -> T? {
        return getCodable(type)
    }
    
    /// ClipboardCopyable 타입을 클립보드에 복사하는 함수
    /// - Parameter value: 복사할 ClipboardCopyable 타입
    private func copyClipboardCopyable(_ value: ClipboardCopyable) {
        let pasteboard = UIPasteboard.general
        
        switch value {
        case let string as String:
            pasteboard.string = string
        case let image as UIImage:
            pasteboard.image = image
        case let url as URL:
            pasteboard.url = url
        case let color as UIColor:
            pasteboard.color = color
        case let data as Data:
            pasteboard.setData(data, forPasteboardType: "public.data")
        default:
            print("지원되지 않는 데이터 타입입니다.")
        }
    }
    
    /// Codable 객체를 클립보드에 복사하는 함수
    /// - Parameter value: 복사할 Codable 객체
    private func copyCodable<T: Codable>(_ value: T) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(value)
            UIPasteboard.general.setData(data, forPasteboardType: "public.json")
        } catch {
            print("Codable 객체 복사 실패: \(error.localizedDescription)")
        }
    }
    
    /// ClipboardCopyable 타입을 클립보드에서 가져오는 함수
    /// - Returns: 클립보드에 저장된 ClipboardCopyable 타입 데이터
    private func getClipboardCopyable(_ type: ClipboardCopyable.Type) -> ClipboardCopyable? {
        let pasteboard = UIPasteboard.general
        
        switch type {
        case is String.Type:
            return pasteboard.string
        case is UIImage.Type:
            return pasteboard.image
        case is URL.Type:
            return pasteboard.url
        case is UIColor.Type:
            return pasteboard.color
        case is Data.Type:
            return pasteboard.data(forPasteboardType: "public.data")
        default:
            return nil
        }
    }
    
    /// 클립보드에서 Codable 객체를 가져오는 함수
    /// - Returns: 클립보드에 저장된 Codable 객체
    private func getCodable<T: Codable>(_ type: T.Type) -> T? {
        guard let data = UIPasteboard.general.data(forPasteboardType: "public.json") else { return nil }
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(type, from: data)
        } catch {
            print("Codable 객체 가져오기 실패: \(error.localizedDescription)")
            return nil
        }
    }
}
