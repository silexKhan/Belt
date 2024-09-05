//
//  File.swift
//  
//
//  Created by ahn kyu suk on 9/5/24.
//

import Foundation

/**
 UserDefaultsUtility 클래스는 iOS에서 UserDefaults에 데이터를 저장하고 불러오는 기능을 간편하게 사용할 수 있도록 도와주는 유틸리티 클래스입니다.
 간단한 데이터부터 Codable 객체까지 저장 및 불러오는 기능을 제공합니다.
 
 주요 기능:
 - **기본 데이터 저장/불러오기**: String, Bool, Int 등 다양한 기본 데이터를 UserDefaults에 저장하고 불러옵니다.
 - **Codable 데이터 저장/불러오기**: Codable로 선언된 복잡한 데이터 구조도 쉽게 저장하고 불러옵니다.
 - **값 삭제**: 특정 키에 해당하는 데이터를 삭제하거나, 모든 데이터를 삭제할 수 있습니다.
 
 이 클래스는 UserDefaults와 관련된 작업을 간편하게 관리할 수 있도록 설계되었습니다.
 */
public class UserDefaultsUtility {
    
    private let defaults: UserDefaults
    
    /// 기본 생성자
    /// - Parameter defaults: 사용할 `UserDefaults` 객체 (기본값은 `.standard`)
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    /// 값을 UserDefaults에 저장하는 제네릭 메서드 (Codable 이외 타입 처리)
    /// - Parameters:
    ///   - key: 저장할 데이터의 키
    ///   - value: 저장할 값
    public func set<T>(_ key: String, value: T) {
        defaults.set(value, forKey: key)
    }
    
    /// 값을 UserDefaults에 저장하는 메서드 (Codable 전용)
    /// - Parameters:
    ///   - key: 저장할 데이터의 키
    ///   - value: 저장할 Codable 객체
    public func set<T: Codable>(_ key: String, value: T) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(value) {
            defaults.set(encoded, forKey: key)
        }
    }
    
    /// UserDefaults에서 값을 불러오는 제네릭 메서드 (Codable 이외 타입 처리)
    /// - Parameters:
    ///   - key: 불러올 데이터의 키
    ///   - type: 불러올 값의 타입
    /// - Returns: 해당 타입의 값 (없을 경우 nil)
    public func get<T>(_ key: String, type: T.Type) -> T? {
        return defaults.object(forKey: key) as? T
    }
    
    /// UserDefaults에서 Codable 객체를 불러오는 메서드
    /// - Parameters:
    ///   - key: 불러올 데이터의 키
    ///   - type: 불러올 Codable 타입
    /// - Returns: 디코딩된 객체 (없을 경우 nil)
    public func get<T: Codable>(_ key: String, type: T.Type) -> T? {
        guard let savedData = defaults.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(T.self, from: savedData)
    }
    
    /// UserDefaults에서 Bool 값을 저장하는 메서드
    /// - Parameters:
    ///   - key: 저장할 데이터의 키
    ///   - value: 저장할 Bool 값
    public func setBool(_ key: String, value: Bool) {
        defaults.set(value, forKey: key)
    }
    
    /// UserDefaults에서 Bool 값을 불러오는 메서드
    /// - Parameters:
    ///   - key: 불러올 데이터의 키
    /// - Returns: 저장된 Bool 값 (없을 경우 false)
    public func getBool(_ key: String) -> Bool {
        return defaults.bool(forKey: key)
    }
    
    /// UserDefaults에서 Integer 값을 저장하는 메서드
    /// - Parameters:
    ///   - key: 저장할 데이터의 키
    ///   - value: 저장할 Integer 값
    public func setInteger(_ key: String, value: Int) {
        defaults.set(value, forKey: key)
    }
    
    /// UserDefaults에서 Integer 값을 불러오는 메서드
    /// - Parameters:
    ///   - key: 불러올 데이터의 키
    /// - Returns: 저장된 Integer 값 (없을 경우 0)
    public func getInteger(_ key: String) -> Int {
        return defaults.integer(forKey: key)
    }
    
    /// UserDefaults에서 값을 삭제하는 메서드
    /// - Parameter key: 삭제할 데이터의 키
    public func removeValue(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
    
    /// UserDefaults에서 모든 값을 제거하는 메서드 (주의해서 사용)
    public func clearAll() {
        if let bundleID = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: bundleID)
        }
    }
}
