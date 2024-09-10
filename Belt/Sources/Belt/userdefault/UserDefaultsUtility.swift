//
//  UserDefaultsUtility.swift
//  
//
//  Created by ahn kyu suk on 9/5/24.
//

import Foundation

/// A utility class for managing `UserDefaults` operations. This class provides methods for saving and retrieving values,
/// including basic data types and `Codable` objects. It also supports clearing all stored values and removing specific keys.
///
/// This utility simplifies common operations with `UserDefaults` and allows for safe type handling using generics and `Codable`.
///
/// # Features:
/// - Store and retrieve basic types (Bool, Int, etc.)
/// - Store and retrieve `Codable` objects
/// - Remove specific keys or clear all data
/// - Safe error handling for encoding/decoding `Codable` objects
///
/// # Example Usage:
///
/// ```swift
/// let userDefaultsUtility = UserDefaultsUtility()
///
/// // Storing a basic value
/// userDefaultsUtility.set("username", value: "JohnDoe")
///
/// // Retrieving a basic value
/// if let username: String = userDefaultsUtility.get("username", type: String.self) {
///     print("Username: \(username)")
/// }
///
/// // Storing a Codable object
/// struct User: Codable {
///     let name: String
///     let age: Int
/// }
///
/// let user = User(name: "John", age: 30)
/// try? userDefaultsUtility.set("user", value: user)
///
/// // Retrieving a Codable object
/// if let storedUser: User = try? userDefaultsUtility.get("user", type: User.self) {
///     print("User name: \(storedUser.name), age: \(storedUser.age)")
/// }
///
/// // Removing a specific key
/// userDefaultsUtility.removeValue(forKey: "username")
///
/// // Clearing all stored data
/// userDefaultsUtility.clearAll()
/// ```
///
/// This example demonstrates how to store and retrieve basic values as well as `Codable` objects using the `UserDefaultsUtility` class.
public class UserDefaultsUtility {
    
    private let defaults: UserDefaults
    
    /// Default initializer
    /// - Parameter defaults: The `UserDefaults` instance to use (default is `.standard`).
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    /// Generic method to store a value in `UserDefaults` (for non-Codable types).
    /// - Parameters:
    ///   - key: The key under which to store the value.
    ///   - value: The value to store.
    public func set<T>(_ key: String, value: T) {
        defaults.set(value, forKey: key)
    }
    
    /// Stores a Codable object in `UserDefaults`.
    /// - Parameters:
    ///   - key: The key under which to store the data.
    ///   - value: The Codable object to store.
    ///   - throws: An error if encoding the object fails.
    public func set<T: Codable>(_ key: String, value: T) throws {
        let encoder = JSONEncoder()
        do {
            let encoded = try encoder.encode(value)
            defaults.set(encoded, forKey: key)
        } catch {
            throw error
        }
    }
    
    /// Generic method to retrieve a value from `UserDefaults` (for non-Codable types).
    /// - Parameters:
    ///   - key: The key associated with the stored value.
    ///   - type: The type of the value to retrieve.
    /// - Returns: The value if it exists, or `nil` if the key does not exist or the type doesn't match.
    public func get<T>(_ key: String, type: T.Type) -> T? {
        return defaults.object(forKey: key) as? T
    }
    
    /// Retrieves a Codable object from `UserDefaults`.
    /// - Parameters:
    ///   - key: The key associated with the stored data.
    ///   - type: The Codable type to retrieve.
    /// - Returns: The decoded object if it exists, or `nil` if the key does not exist.
    ///   - throws: An error if decoding the object fails.
    public func get<T: Codable>(_ key: String, type: T.Type) throws -> T? {
        guard let savedData = defaults.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(T.self, from: savedData)
        } catch {
            throw error
        }
    }
    
    /// Stores a boolean value in `UserDefaults`.
    /// - Parameters:
    ///   - key: The key under which to store the value.
    ///   - value: The boolean value to store.
    public func setBool(_ key: String, value: Bool) {
        defaults.set(value, forKey: key)
    }
    
    /// Retrieves a boolean value from `UserDefaults`.
    /// - Parameter key: The key associated with the stored boolean value.
    /// - Returns: The stored boolean value, or `false` if the key does not exist.
    public func getBool(_ key: String) -> Bool {
        return defaults.bool(forKey: key)
    }
    
    /// Stores an integer value in `UserDefaults`.
    /// - Parameters:
    ///   - key: The key under which to store the value.
    ///   - value: The integer value to store.
    public func setInteger(_ key: String, value: Int) {
        defaults.set(value, forKey: key)
    }
    
    /// Retrieves an integer value from `UserDefaults`.
    /// - Parameter key: The key associated with the stored integer value.
    /// - Returns: The stored integer value, or `0` if the key does not exist.
    public func getInteger(_ key: String) -> Int {
        return defaults.integer(forKey: key)
    }
    
    /// Removes a value from `UserDefaults`.
    /// - Parameter key: The key associated with the value to remove.
    public func removeValue(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
    
    /// Clears all data in `UserDefaults` (use with caution).
    public func clearAll() {
        if let bundleID = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: bundleID)
        }
    }
}
