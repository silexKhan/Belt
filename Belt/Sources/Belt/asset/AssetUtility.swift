//
//  AssetUtility.swift
//
//
//  Created by ahn kyu suk on 9/4/24.
//

import Combine
import Photos
import UIKit

/// AssetUtility is a utility class that provides methods to interact with the photo library.
/// It allows requesting access to the photo library, fetching and manipulating assets, generating thumbnails, and handling asset metadata.
///
/// Example usage:
///
/// ```swift
/// let assetUtility = AssetUtility()
///
/// // Request access to the photo library and load assets if granted
/// assetUtility.loadAssets()
///     .sink { assets in
///         print("Fetched \(assets.count) assets")
///     }
///     .store(in: &cancellables)
///
/// // Fetch assets sorted by creation date
/// assetUtility.fetchAssetsSorted(by: .creationDate(ascending: true))
///     .sink { sortedAssets in
///         print("Fetched and sorted \(sortedAssets.count) assets")
///     }
///     .store(in: &cancellables)
///
/// // Generate a thumbnail for an asset
/// assetUtility.generateThumbnail(for: asset, size: CGSize(width: 100, height: 100))
///     .sink { result in
///         switch result {
///         case .success(let thumbnail):
///             print("Thumbnail generated successfully")
///         case .failure(let error):
///             print("Failed to generate thumbnail: \(error.localizedDescription)")
///         }
///     }
///     .store(in: &cancellables)
///
/// // Save an image to the photo library
/// assetUtility.saveAsset(image: someUIImage)
///     .sink { result in
///         switch result {
///         case .success(let isSuccess):
///             print(isSuccess ? "Image saved successfully" : "Failed to save image")
///         case .failure(let error):
///             print("Error saving image: \(error.localizedDescription)")
///         }
///     }
///     .store(in: &cancellables)
///
/// // Fetch metadata for an asset
/// assetUtility.fetchAssetMetadata(for: asset)
///     .sink { metadata in
///         print("Metadata - File size: \(metadata.fileSize), Resolution: \(metadata.resolution)")
///     }
///     .store(in: &cancellables)
///
/// // Delete assets from the photo library
/// assetUtility.deleteAssets([asset1, asset2])
///     .sink { result in
///         switch result {
///         case .success(let isSuccess):
///             print(isSuccess ? "Assets deleted successfully" : "Failed to delete assets")
///         case .failure(let error):
///             print("Error deleting assets: \(error.localizedDescription)")
///         }
///     }
///     .store(in: &cancellables)
/// ```
///
/// This utility simplifies interaction with the photo library by wrapping operations in Combine's Future/Publisher-based structure, allowing for asynchronous handling of assets and permissions.
public class AssetUtility {
    
    public init() { }
    
    /// Requests access to the photo library.
    /// - Returns: A `Future` that returns `true` if access is granted, otherwise `false`.
    public func requestPhotoLibraryAccess() -> Future<Bool, Never> {
        return Future { promise in
            PHPhotoLibrary.requestAuthorization { status in
                switch status {
                case .authorized:
                    promise(.success(true))
                default:
                    promise(.success(false))
                }
            }
        }
    }
    
    /// Asynchronously fetches image assets from the photo library.
    /// - Returns: A `Future` that returns an array of `PHAsset` objects.
    public func fetchAssets() -> Future<[PHAsset], Never> {
        return Future { promise in
            let fetchOptions = PHFetchOptions()
            let fetchedAssets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            var assets: [PHAsset] = []
            fetchedAssets.enumerateObjects { (asset, _, _) in
                assets.append(asset)
            }
            promise(.success(assets))
        }
    }
    
    /// Loads photo assets after requesting permissions.
    /// - Returns: A `Publisher` that returns an array of `PHAsset` objects if access is granted, otherwise an empty array.
    public func loadAssets() -> AnyPublisher<[PHAsset], Never> {
        return requestPhotoLibraryAccess()
            .flatMap { isGranted -> AnyPublisher<[PHAsset], Never> in
                if isGranted {
                    return self.fetchAssets().eraseToAnyPublisher()
                } else {
                    return Just([]).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
    
    /// Asynchronously fetches sorted assets from the photo library based on the given sorting option.
    /// - Parameter option: The sorting criteria defined by `AssetSortOption`.
    /// - Returns: A `Future` that returns an array of sorted `PHAsset` objects.
    public func fetchAssetsSorted(by option: AssetSortOption) -> Future<[PHAsset], Never> {
        return Future { promise in
            let fetchOptions = PHFetchOptions()
            switch option {
            case .creationDate(let ascending):
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: ascending)]
            case .modificationDate(let ascending):
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: ascending)]
            case .fileSize(let ascending):
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "fileSize", ascending: ascending)]
            }
            let fetchedAssets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            var assets: [PHAsset] = []
            fetchedAssets.enumerateObjects { (asset, _, _) in
                assets.append(asset)
            }
            promise(.success(assets))
        }
    }

    /// Asynchronously fetches assets filtered by a given criteria.
    /// - Parameter option: The filter criteria defined by `AssetFilterOption`.
    /// - Returns: A `Future` that returns an array of filtered `PHAsset` objects.
    public func fetchAssetsFiltered(by option: AssetFilterOption) -> Future<[PHAsset], Never> {
        return Future { promise in
            let fetchOptions = PHFetchOptions()
            switch option {
            case .dateRange(let start, let end):
                fetchOptions.predicate = NSPredicate(format: "creationDate >= %@ AND creationDate <= %@", start as NSDate, end as NSDate)
            case .resolution(let minWidth, let minHeight):
                fetchOptions.predicate = NSPredicate(format: "pixelWidth >= %d AND pixelHeight >= %d", minWidth, minHeight)
            case .mediaType(let type):
                switch type {
                case .image:
                    fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
                case .video:
                    fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
                case .both:
                    break // Fetch all media types
                }
            }
            let fetchedAssets = PHAsset.fetchAssets(with: fetchOptions)
            var assets: [PHAsset] = []
            fetchedAssets.enumerateObjects { (asset, _, _) in
                assets.append(asset)
            }
            promise(.success(assets))
        }
    }

    /// Fetches assets from a specific album in the photo library.
    /// - Parameter album: The name of the album to fetch assets from.
    /// - Returns: A `Future` that returns an array of `PHAsset` objects in the album, or an empty array if the album is not found.
    public func fetchAssets(fromAlbum album: String) -> Future<[PHAsset], Never> {
        return Future { promise in
            let fetchOptions = PHFetchOptions()
            let fetchedAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
            fetchedAlbums.enumerateObjects { (collection, _, _) in
                if collection.localizedTitle == album {
                    let assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
                    var assetList: [PHAsset] = []
                    assets.enumerateObjects { (asset, _, _) in
                        assetList.append(asset)
                    }
                    promise(.success(assetList))
                }
            }
            promise(.success([])) // If no album found
        }
    }

    /// Deletes the given assets from the photo library.
    /// - Parameter assets: The array of `PHAsset` objects to be deleted.
    /// - Returns: A `Future` that returns `true` if deletion succeeds, otherwise an error.
    public func deleteAssets(_ assets: [PHAsset]) -> Future<Bool, Error> {
        return Future { promise in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(assets as NSArray)
            }, completionHandler: { success, error in
                if success {
                    promise(.success(true))
                } else if let error = error {
                    promise(.failure(error))
                }
            })
        }
    }

    /// Saves a given image to the photo library.
    /// - Parameter image: The `UIImage` object to save.
    /// - Returns: A `Future` that returns `true` if the image is successfully saved, otherwise an error.
    public func saveAsset(image: UIImage) -> Future<Bool, Error> {
        return Future { promise in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }, completionHandler: { success, error in
                if success {
                    promise(.success(true))
                } else if let error = error {
                    promise(.failure(error))
                }
            })
        }
    }
    
    /// Fetches metadata for a given asset.
    /// - Parameter asset: The `PHAsset` object for which metadata is being fetched.
    /// - Returns: A `Future` that returns an `AssetMetadata` object containing metadata information.
    public func fetchAssetMetadata(for asset: PHAsset) -> Future<AssetMetadata, Never> {
        return Future { promise in
            let metadata = AssetMetadata(
                fileSize: asset.pixelWidth * asset.pixelHeight,
                resolution: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
                creationDate: asset.creationDate,
                location: asset.location
            )
            promise(.success(metadata))
        }
    }

    /// Generates a thumbnail for a given asset.
    /// - Parameter asset: The `PHAsset` object to generate a thumbnail for.
    /// - Parameter size: The size of the desired thumbnail.
    /// - Returns: A `Future` that returns a `UIImage` object representing the thumbnail.
    public func generateThumbnail(for asset: PHAsset, size: CGSize) -> Future<UIImage, Error> {
        return Future { promise in
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { image, _ in
                if let image = image {
                    promise(.success(image))
                } else {
                    promise(.failure(NSError(domain: "com.example.AssetUtility", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to generate a thumbnail."])))
                }
            }
        }
    }

    /// Fetches the number of assets in the photo library for a given media type.
    /// - Parameter mediaType: The media type to filter by (e.g., image, video).
    /// - Returns: A `Future` that returns the count of assets of the specified type.
    public func getAssetCount(for mediaType: MediaType) -> Future<Int, Never> {
        return Future { promise in
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", mediaType.rawValue)
            let assetCount = PHAsset.fetchAssets(with: fetchOptions).count
            promise(.success(assetCount))
        }
    }
}
