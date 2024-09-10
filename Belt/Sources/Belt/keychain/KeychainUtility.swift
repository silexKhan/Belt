//
//  KeychainUtility.swift
//
//
//  Created by ahn kyu suk on 9/5/24.
//

import Foundation
import Security
import Combine

/// A utility class for managing key-value storage in the iOS Keychain.
/// This class provides methods to save, load, delete, and clear data from the Keychain, supporting
/// various data types such as `String`, `Bool`, `Int`, and `Codable` types. The class uses the `Combine`
/// framework to handle Keychain operations asynchronously, returning `Future` for each operation.
///
/// The class ensures proper error handling, converting Keychain status codes into descriptive error messages,
/// and includes safeguards for common issues like data encoding/decoding and system endianness when working with `Int` values.
///
/// # Features:
/// - Save and retrieve multiple types of data (`String`, `Bool`, `Int`, and `Codable`) in the Keychain.
/// - Delete individual entries from the Keychain.
/// - Clear all Keychain entries (use with caution).
/// - Provides detailed error handling for all Keychain operations.
/// - Uses `Combine` for asynchronous operations with `Future`.
///
/// # Usage Example:
///
/// ```swift
/// let keychainUtility = KeychainUtility()
///
/// // Saving a String value to the Keychain
/// keychainUtility.save("userToken", value: "abcdef12345")
///     .sink(receiveCompletion: { completion in
///         switch completion {
///         case .finished:
///             print("Save successful")
///         case .failure(let error):
///             print("Error saving to Keychain: \(error)")
///         }
///     }, receiveValue: { success in
///         print("Operation success: \(success)")
///     })
///     .store(in: &cancellables)
///
/// // Loading a String value from the Keychain
/// keychainUtility.load("userToken", as: String.self)
///     .sink(receiveCompletion: { completion in
///         switch completion {
///         case .finished:
///             print("Load complete")
///         case .failure(let error):
///             print("Error loading from Keychain: \(error)")
///         }
///     }, receiveValue: { value in
///         if let token = value {
///             print("Loaded token: \(token)")
///         }
///     })
///     .store(in: &cancellables)
///
/// // Deleting a value from the Keychain
/// keychainUtility.delete("userToken")
///     .sink(receiveCompletion: { completion in
///         switch completion {
///         case .finished:
///             print("Deletion complete")
///         case .failure(let error):
///             print("Error deleting from Keychain: \(error)")
///         }
///     }, receiveValue: { success in
///         print("Deletion success: \(success)")
///     })
///     .store(in: &cancellables)
///
/// // Clearing all values from the Keychain
/// keychainUtility.clear()
///     .sink(receiveCompletion: { completion in
///         switch completion {
///         case .finished:
///             print("Clear complete")
///         case .failure(let error):
///             print("Error clearing Keychain: \(error)")
///         }
///     }, receiveValue: { success in
///         print("Clear success: \(success)")
///     })
///     .store(in: &cancellables)
/// ```
///
/// This example demonstrates saving, loading, deleting, and clearing Keychain values using
/// the `KeychainUtility` class. The operations return `Future` values that allow for asynchronous
/// execution and error handling via the `Combine` framework.
public class KeychainUtility {
    
    /// Saves a value to the Keychain (supports String, Bool, Int, and Codable types).
    /// - Parameters:
    ///   - key: The key under which the data will be saved.
    ///   - value: The value to save (String, Bool, Int, Codable).
    /// - Returns: A `Future` that returns `true` if the save operation was successful.
    public static func save<T>(_ key: String, value: T) -> Future<Bool, Error> {
        return Future { promise in
            var data: Data?
            
            if let stringValue = value as? String {
                data = stringValue.data(using: .utf8)
            } else if let boolValue = value as? Bool {
                data = Data([boolValue ? 1 : 0])
            } else if let intValue = value as? Int {
                data = withUnsafeBytes(of: intValue.bigEndian) { Data($0) }
            } else if let codableValue = value as? Codable {
                let encoder = JSONEncoder()
                do {
                    data = try encoder.encode(codableValue)
                } catch {
                    promise(.failure(error))
                    return
                }
            }
            
            guard let dataToSave = data else {
                promise(.failure(NSError(domain: "KeychainUtility", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid data format"])))
                return
            }
            
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecValueData as String: dataToSave
            ]
            
            SecItemDelete(query as CFDictionary)  // Overwrite existing item if exists
            let status = SecItemAdd(query as CFDictionary, nil)
            
            if status == errSecSuccess {
                promise(.success(true))
            } else {
                let error = NSError(domain: "KeychainUtility", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Error saving to Keychain: \(status)"])
                promise(.failure(error))
            }
        }
    }
    
    /// Loads a value from the Keychain.
    /// - Parameters:
    ///   - key: The key associated with the data to retrieve.
    ///   - type: The expected type of the value to retrieve (String, Bool, Int, Codable).
    /// - Returns: A `Future` that returns the retrieved value, if it exists and is successfully decoded, or an error.
    public static func load<T>(_ key: String, as type: T.Type) -> Future<T?, Error> {
        return Future { promise in
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecReturnData as String: NSNumber(value: true),
                kSecMatchLimit as String: kSecMatchLimitOne
            ]
            
            var dataTypeRef: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
            
            guard status == errSecSuccess, let data = dataTypeRef as? Data else {
                let error = NSError(domain: "KeychainUtility", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Error loading from Keychain: \(status)"])
                promise(.failure(error))
                return
            }
            
            if type == String.self {
                let result = String(data: data, encoding: .utf8) as? T
                promise(.success(result))
            } else if type == Bool.self {
                let result = (data.first == 1) as? T
                promise(.success(result))
            } else if type == Int.self {
                let result = data.withUnsafeBytes { $0.load(as: Int.self).bigEndian } as? T
                promise(.success(result))
            } else if let codableType = type as? Codable.Type {
                let decoder = JSONDecoder()
                do {
                    let decoded = try decoder.decode(codableType, from: data)
                    promise(.success(decoded as? T))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
    
    /// Deletes a value from the Keychain.
    /// - Parameter key: The key associated with the data to delete.
    /// - Returns: A `Future` that returns `true` if the deletion was successful.
    public static func delete(_ key: String) -> Future<Bool, Error> {
        return Future { promise in
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key
            ]
            
            let status = SecItemDelete(query as CFDictionary)
            if status == errSecSuccess {
                promise(.success(true))
            } else {
                let error = NSError(domain: "KeychainUtility", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Error deleting from Keychain: \(status)"])
                promise(.failure(error))
            }
        }
    }
    
    /// Clears all data from the Keychain. Use with caution!
    /// - Returns: A `Future` that returns `true` if the clear operation was successful.
    public static func clear() -> Future<Bool, Error> {
        return Future { promise in
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword
            ]
            
            let status = SecItemDelete(query as CFDictionary)
            if status == errSecSuccess {
                promise(.success(true))
            } else {
                let error = NSError(domain: "KeychainUtility", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Error clearing Keychain: \(status)"])
                promise(.failure(error))
            }
        }
    }
}
