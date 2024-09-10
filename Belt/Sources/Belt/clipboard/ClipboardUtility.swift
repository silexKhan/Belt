//
//  ClipboardUtility.swift
//
//
//  Created by ahn kyu suk on 9/5/24.
//

import Foundation
import UIKit

/// A utility class for handling clipboard operations, such as copying and retrieving various types of data
/// (e.g., text, images, URLs, UIColor, Codable objects) to and from the clipboard.
///
/// This utility supports two types of operations:
/// - Copying and retrieving `ClipboardCopyable` types (e.g., String, UIImage, URL, UIColor, Data)
/// - Copying and retrieving `Codable` types, which are encoded as JSON before being stored in the clipboard
///
/// ## Features:
/// - Generic function for copying data to the clipboard.
/// - Support for copying common types like String, UIImage, URL, UIColor, and Data.
/// - Support for encoding `Codable` objects as JSON for clipboard operations.
/// - Automatically retrieves data based on the specified type (either `ClipboardCopyable` or `Codable`).
///
/// ## Usage Example:
///
/// ```swift
/// let clipboardUtility = ClipboardUtility()
///
/// // Copying basic types
/// clipboardUtility.copy("Hello World")
/// clipboardUtility.copy(UIImage(named: "exampleImage"))
/// clipboardUtility.copy(URL(string: "https://www.example.com"))
/// clipboardUtility.copy(UIColor.red)
///
/// // Retrieving basic types
/// if let copiedText: String = clipboardUtility.get(String.self) {
///     print("Copied Text: \(copiedText)")
/// }
///
/// if let copiedImage: UIImage = clipboardUtility.get(UIImage.self) {
///     print("Copied Image: \(copiedImage)")
/// }
///
/// // Copying a Codable object
/// struct Person: Codable {
///     let name: String
///     let age: Int
/// }
/// let person = Person(name: "John", age: 30)
/// clipboardUtility.copy(person)
///
/// // Retrieving a Codable object
/// if let copiedPerson: Person = clipboardUtility.get(Person.self) {
///     print("Copied Person: \(copiedPerson)")
/// }
/// ```
///
/// ## Methods:
/// - `copy<T>(_ value: T)`: Copies the given value to the clipboard. Supports both `ClipboardCopyable` and `Codable` types.
/// - `get<T: ClipboardCopyable>(_ type: T.Type) -> T?`: Retrieves a `ClipboardCopyable` type from the clipboard.
/// - `get<T: Codable>(_ type: T.Type) -> T?`: Retrieves a `Codable` object from the clipboard by decoding it from JSON.
/// 
public class ClipboardUtility {

    public init() {}

    /// Generic function to copy data to the clipboard (text, image, URL, UIColor, etc.)
    /// If the data type is Codable, it will be encoded to JSON and then copied.
    /// - Parameter value: The value to copy (text, image, URL, UIColor, etc., or a Codable object)
    public func copy<T>(_ value: T) {
        if let value = value as? ClipboardCopyable {
            copyClipboardCopyable(value)
        } else if let value = value as? Codable {
            copyCodable(value)
        } else {
            print("Unsupported data type.")
        }
    }

    /// Function to retrieve ClipboardCopyable types from the clipboard
    /// - Parameter type: The ClipboardCopyable type to retrieve
    /// - Returns: The stored value in the clipboard, if available
    public func get<T: ClipboardCopyable>(_ type: T.Type) -> T? {
        return getClipboardCopyable(type) as? T
    }

    /// Function to retrieve Codable types from the clipboard
    /// - Parameter type: The Codable type to retrieve
    /// - Returns: The stored Codable object in the clipboard, if available
    public func get<T: Codable>(_ type: T.Type) -> T? {
        return getCodable(type)
    }

    /// Copies ClipboardCopyable types to the clipboard
    /// - Parameter value: The ClipboardCopyable type to copy
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
            copyColor(color)
        case let data as Data:
            pasteboard.setData(data, forPasteboardType: "public.data")
        default:
            print("Unsupported data type.")
        }
    }

    /// Copies Codable objects to the clipboard
    /// - Parameter value: The Codable object to copy
    private func copyCodable<T: Codable>(_ value: T) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(value)
            UIPasteboard.general.setData(data, forPasteboardType: "public.json")
        } catch {
            print("Failed to copy Codable object: \(error.localizedDescription)")
        }
    }

    /// Retrieves ClipboardCopyable types from the clipboard
    /// - Parameter type: The ClipboardCopyable type to retrieve
    /// - Returns: The stored ClipboardCopyable type in the clipboard
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
            return getColor()
        case is Data.Type:
            return pasteboard.data(forPasteboardType: "public.data")
        default:
            return nil
        }
    }

    /// Retrieves Codable objects from the clipboard
    /// - Parameter type: The Codable type to retrieve
    /// - Returns: The stored Codable object from the clipboard
    private func getCodable<T: Codable>(_ type: T.Type) -> T? {
        guard let data = UIPasteboard.general.data(forPasteboardType: "public.json") else { return nil }
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(type, from: data)
        } catch {
            print("Failed to retrieve Codable object: \(error.localizedDescription)")
            return nil
        }
    }

    /// Copies UIColor to the clipboard
    /// - Parameter color: The UIColor to copy
    private func copyColor(_ color: UIColor) {
        let pasteboard = UIPasteboard.general
        let colorData = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
        pasteboard.setData(colorData ?? Data(), forPasteboardType: "public.color")
    }

    /// Retrieves UIColor from the clipboard
    /// - Returns: The stored UIColor from the clipboard
    private func getColor() -> UIColor? {
        let pasteboard = UIPasteboard.general
        if let colorData = pasteboard.data(forPasteboardType: "public.color") {
            return try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? UIColor
        }
        return nil
    }
}


