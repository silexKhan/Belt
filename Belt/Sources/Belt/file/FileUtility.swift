//
//  FileUtility.swift
//
//
//  Created by ahn kyu suk on 9/4/24.
//

import Foundation
import Combine

/// A utility class for performing common file operations such as reading, writing, deleting,
/// moving, and listing files and directories. It provides asynchronous support using the `Combine` framework,
/// allowing for file management tasks to be performed in a non-blocking way.
///
/// The class uses `FileManager` for interacting with the file system and handles various file-related operations
/// such as checking file existence, retrieving file sizes, and creating directories. It also provides
/// detailed error handling for each operation.
///
/// # Usage Example:
///
/// ```swift
/// let fileUtility = FileUtility()
///
/// // Write a file
/// let content = "Hello, world!"
/// fileUtility.writeFile(content: content, at: .documentDirectory, path: "example.txt")
///     .sink(receiveCompletion: { completion in
///         switch completion {
///         case .finished:
///             print("File written successfully.")
///         case .failure(let error):
///             print("Failed to write file: \(error)")
///         }
///     }, receiveValue: { success in
///         print("Operation success: \(success)")
///     })
///     .store(in: &cancellables)
///
/// // Read a file
/// fileUtility.readFile(at: .documentDirectory, path: "example.txt")
///     .sink(receiveCompletion: { completion in
///         switch completion {
///         case .finished:
///             print("File read successfully.")
///         case .failure(let error):
///             print("Failed to read file: \(error)")
///         }
///     }, receiveValue: { content in
///         if let content = content {
///             print("File content: \(content)")
///         }
///     })
///     .store(in: &cancellables)
///
/// // Check if file exists
/// fileUtility.fileExists(at: .documentDirectory, path: "example.txt")
///     .sink(receiveCompletion: { _ in }, receiveValue: { exists in
///         print("File exists: \(exists)")
///     })
///     .store(in: &cancellables)
///
/// // Delete a file
/// fileUtility.deleteFile(at: .documentDirectory, path: "example.txt")
///     .sink(receiveCompletion: { completion in
///         switch completion {
///         case .finished:
///             print("File deleted successfully.")
///         case .failure(let error):
///             print("Failed to delete file: \(error)")
///         }
///     }, receiveValue: { success in
///         print("Operation success: \(success)")
///     })
///     .store(in: &cancellables)
/// ```
///
/// The class allows seamless chaining of asynchronous file operations and handles errors that occur during
/// these operations. It also provides utility methods for file manipulation, making it easier to manage files in
/// the app’s sandboxed environment.
import Foundation
import Combine

public class FileUtility {
    
    private let fileManager: FileManager
    
    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    /// Returns the URL for the given directory and path.
    /// - Parameters:
    ///   - directory: The base directory (`FileManager.SearchPathDirectory`).
    ///   - path: The relative path within the directory.
    /// - Returns: A result containing the file URL or an error.
    private func fileURL(at directory: FileManager.SearchPathDirectory, path: String) -> Result<URL, Error> {
        if let directoryURL = fileManager.urls(for: directory, in: .userDomainMask).first {
            let fileURL = directoryURL.appendingPathComponent(path)
            return .success(fileURL)
        } else {
            let error = NSError(domain: "FileUtility", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to find directory path."])
            return .failure(error)
        }
    }
    
    /// Checks if the file exists at the given path.
    /// - Parameters:
    ///   - directory: The base directory (`FileManager.SearchPathDirectory`).
    ///   - path: The relative path within the directory.
    /// - Returns: A `Future` that returns `true` if the file exists, or `false` otherwise.
    public func fileExists(at directory: FileManager.SearchPathDirectory, path: String) -> Future<Bool, Error> {
        return Future { promise in
            switch self.fileURL(at: directory, path: path) {
            case .success(let fileURL):
                let exists = self.fileManager.fileExists(atPath: fileURL.path)
                promise(.success(exists))
            case .failure(let error):
                promise(.failure(error))
            }
        }
    }
    
    /// Reads the contents of the file at the given path as a string.
    /// - Parameters:
    ///   - directory: The base directory (`FileManager.SearchPathDirectory`).
    ///   - path: The relative path within the directory.
    /// - Returns: A `Future` that returns the file's contents as a string.
    public func readFile(at directory: FileManager.SearchPathDirectory, path: String) -> Future<String?, Error> {
        return Future { promise in
            switch self.fileURL(at: directory, path: path) {
            case .success(let fileURL):
                do {
                    let content = try String(contentsOf: fileURL, encoding: .utf8)
                    promise(.success(content))
                } catch {
                    promise(.failure(error))
                }
            case .failure(let error):
                promise(.failure(error))
            }
        }
    }
    
    /// Writes content to a file at the given path.
    /// - Parameters:
    ///   - content: The content to write to the file.
    ///   - directory: The base directory (`FileManager.SearchPathDirectory`).
    ///   - path: The relative path within the directory.
    /// - Returns: A `Future` that returns `true` if the write operation was successful.
    public func writeFile(content: String, at directory: FileManager.SearchPathDirectory, path: String) -> Future<Bool, Error> {
        return Future { promise in
            switch self.fileURL(at: directory, path: path) {
            case .success(let fileURL):
                do {
                    try content.write(to: fileURL, atomically: true, encoding: .utf8)
                    promise(.success(true))
                } catch {
                    promise(.failure(error))
                }
            case .failure(let error):
                promise(.failure(error))
            }
        }
    }
    
    /// Deletes the file at the given path.
    /// - Parameters:
    ///   - directory: The base directory (`FileManager.SearchPathDirectory`).
    ///   - path: The relative path within the directory.
    /// - Returns: A `Future` that returns `true` if the file was successfully deleted.
    public func deleteFile(at directory: FileManager.SearchPathDirectory, path: String) -> Future<Bool, Error> {
        return Future { promise in
            switch self.fileURL(at: directory, path: path) {
            case .success(let fileURL):
                do {
                    try self.fileManager.removeItem(at: fileURL)
                    promise(.success(true))
                } catch {
                    promise(.failure(error))
                }
            case .failure(let error):
                promise(.failure(error))
            }
        }
    }
    
    /// Returns the size of the file at the given path.
    /// - Parameters:
    ///   - directory: The base directory (`FileManager.SearchPathDirectory`).
    ///   - path: The file path.
    /// - Returns: A `Future` that returns the size of the file in bytes.
    public func fileSize(at directory: FileManager.SearchPathDirectory, path: String) -> Future<Int64, Error> {
        return Future { promise in
            switch self.fileURL(at: directory, path: path) {
            case .success(let fileURL):
                do {
                    let fileAttributes = try self.fileManager.attributesOfItem(atPath: fileURL.path)
                    if let fileSize = fileAttributes[.size] as? Int64 {
                        promise(.success(fileSize))
                    } else {
                        promise(.failure(NSError(domain: "FileUtility", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to retrieve file size."])))
                    }
                } catch {
                    promise(.failure(error))
                }
            case .failure(let error):
                promise(.failure(error))
            }
        }
    }
    
    /// Creates a directory at the given path.
    /// - Parameters:
    ///   - directory: The base directory (`FileManager.SearchPathDirectory`).
    ///   - path: The relative path of the directory to create.
    /// - Returns: A `Future` that returns `true` if the directory was successfully created.
    public func createDirectory(at directory: FileManager.SearchPathDirectory, path: String) -> Future<Bool, Error> {
        return Future { promise in
            switch self.fileURL(at: directory, path: path) {
            case .success(let directoryURL):
                do {
                    try self.fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
                    promise(.success(true))
                } catch {
                    promise(.failure(error))
                }
            case .failure(let error):
                promise(.failure(error))
            }
        }
    }
    
    /// Lists the files in the specified directory.
    /// - Parameters:
    ///   - directory: The base directory (`FileManager.SearchPathDirectory`).
    /// - Returns: A `Future` that returns an array of file URLs in the directory.
    public func listFiles(in directory: FileManager.SearchPathDirectory) -> Future<[URL], Error> {
        return Future { promise in
            switch self.fileURL(at: directory, path: "") {
            case .success(let directoryURL):
                do {
                    let fileURLs = try self.fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: [])
                    promise(.success(fileURLs))
                } catch {
                    promise(.failure(error))
                }
            case .failure(let error):
                promise(.failure(error))
            }
        }
    }
    
    /// Moves a file from one path to another.
    /// - Parameters:
    ///   - fromDirectory: The directory of the source file.
    ///   - fromPath: The source file path.
    ///   - toDirectory: The directory of the destination file.
    ///   - toPath: The destination file path.
    /// - Returns: A `Future` that returns `true` if the file was successfully moved.
    public func moveFile(from fromDirectory: FileManager.SearchPathDirectory, fromPath: String, to toDirectory: FileManager.SearchPathDirectory, toPath: String) -> Future<Bool, Error> {
        return Future { promise in
            switch (self.fileURL(at: fromDirectory, path: fromPath), self.fileURL(at: toDirectory, path: toPath)) {
            case (.success(let sourceURL), .success(let destinationURL)):
                do {
                    try self.fileManager.moveItem(at: sourceURL, to: destinationURL)
                    promise(.success(true))
                } catch {
                    promise(.failure(error))
                }
            case (.failure(let sourceError), _):
                promise(.failure(sourceError))
            case (_, .failure(let destinationError)):
                promise(.failure(destinationError))
            }
        }
    }
}
