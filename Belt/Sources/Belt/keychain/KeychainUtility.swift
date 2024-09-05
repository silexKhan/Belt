//
//  KeychainUtility.swift
//
//
//  Created by ahn kyu suk on 9/5/24.
//

import Foundation
import Security

/**
 KeychainUtility 클래스는 iOS에서 민감한 데이터를 안전하게 저장하고 불러오는 기능을 제공하는 유틸리티 클래스입니다.
 Keychain은 주로 암호, 토큰, API 키 등과 같은 중요한 정보를 저장하는 데 사용되며, 보안 수준이 높습니다.
 
 주요 기능:
 - **데이터 저장**: String, Bool, Int, Codable과 같은 다양한 데이터 타입을 Keychain에 안전하게 저장할 수 있습니다.
 - **데이터 불러오기**: 저장된 데이터를 안전하게 불러오며, 타입에 따라 적절한 방식으로 변환합니다.
 - **데이터 삭제**: 특정 키에 해당하는 데이터를 삭제하거나, Keychain에 저장된 모든 데이터를 삭제할 수 있습니다.
 
 주요 메서드:
 - `save(key:value:)`: 주어진 키로 데이터를 저장합니다.
 - `load(key:as:)`: 주어진 키로 데이터를 불러오며, 요청된 타입으로 변환합니다.
 - `delete(key:)`: 주어진 키에 해당하는 데이터를 Keychain에서 삭제합니다.
 - `clear()`: Keychain에 저장된 모든 데이터를 삭제합니다.
 
 이 유틸리티 클래스는 보안이 중요한 앱에서 사용되며, 사용자의 민감한 정보를 안전하게 관리할 수 있는 기능을 제공합니다.
 */
public class KeychainUtility {
    
    /// 값을 Keychain에 저장하는 메서드 (String, Bool, Int 등 지원)
    /// - Parameters:
    ///   - key: 저장할 데이터의 키
    ///   - value: 저장할 값
    public static func save<T>(_ key: String, value: T) {
        var data: Data?
        
        if let stringValue = value as? String {
            data = stringValue.data(using: .utf8)
        } else if let boolValue = value as? Bool {
            data = Data([boolValue ? 1 : 0])
        } else if let intValue = value as? Int {
            data = withUnsafeBytes(of: intValue) { Data($0) }
        } else if let codableValue = value as? Codable {
            let encoder = JSONEncoder()
            data = try? encoder.encode(codableValue)
        }
        
        guard let dataToSave = data else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: dataToSave
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    /// Keychain에서 값을 불러오는 메서드
    /// - Parameter key: 불러올 데이터의 키
    /// - Returns: 불러온 값 (String, Bool, Int 등)
    public static func load<T>(_ key: String, as type: T.Type) -> T? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess, let data = dataTypeRef as? Data else { return nil }
        
        if type == String.self {
            return String(data: data, encoding: .utf8) as? T
        } else if type == Bool.self {
            return (data.first == 1) as? T
        } else if type == Int.self {
            return data.withUnsafeBytes { $0.load(as: Int.self) } as? T
        } else if type is Codable.Type {
            let decoder = JSONDecoder()
            return try? decoder.decode(type as! Codable.Type, from: data) as? T
        }
        
        return nil
    }
    
    /// Keychain에서 값을 삭제하는 메서드
    /// - Parameter key: 삭제할 데이터의 키
    /// - Returns: 삭제 성공 여부
    @discardableResult
    public static func delete(_ key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    /// Keychain에서 모든 데이터를 삭제하는 메서드 (주의해서 사용)
    /// - Returns: 삭제 성공 여부
    @discardableResult
    public static func clear() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
}
