//
//  File.swift
//  
//
//  Created by ahn kyu suk on 9/4/24.
//

import Combine
import Photos
import UIKit

/**
 AssetUtility 클래스는 iOS에서 사진첩에 접근하고, 자산을 불러오고 관리하는 기능을 제공하는 유틸리티 클래스입니다.
 이 클래스는 비동기적으로 권한을 요청하고, 자산을 불러오거나 필터링하는 기능을 제공합니다.
 
 주요 기능:
 - **사진첩 권한 요청**: 사용자가 사진첩에 접근할 수 있도록 권한을 요청합니다.
 - **자산 불러오기**: 사진첩에서 사진이나 비디오 자산을 불러옵니다.
 - **자산 필터링 및 정렬**: 특정 필터 조건을 적용하거나 자산을 정렬하여 불러올 수 있습니다.
 - **썸네일 생성**: 사진의 썸네일을 생성할 수 있습니다.
 - **자산 삭제**: 불필요한 자산을 삭제할 수 있습니다.
 
 이 유틸리티는 사진첩과 관련된 작업을 간편하게 수행할 수 있도록 설계되었습니다.
 */
public class AssetUtility {
    
    public init() { }
    
    /// 사진첩 접근 권한을 요청하는 메서드
    /// - Returns: 사진첩 접근 권한이 허용되었는지 여부를 비동기적으로 반환하는 `Future`
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
    
    /// 사진첩에서 이미지 자산을 비동기적으로 불러오는 메서드
    /// - Returns: `PHAsset` 배열을 비동기적으로 반환하는 `Future`
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
    
    /// 비동기적으로 사진첩 자산을 로드하는 메서드
    /// - Returns: 권한 요청 후 자산을 불러오는 `Publisher`
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
    
    /// 사진첩에서 자산을 정렬하여 비동기적으로 불러오는 메서드입니다.
    /// - Parameter option: 자산을 정렬할 기준을 정의하는 `AssetSortOption`입니다.
    ///   생성일, 수정일 또는 파일 크기 기준으로 오름차순 또는 내림차순 정렬할 수 있습니다.
    /// - Returns: 정렬된 `PHAsset` 배열을 반환하는 `Future` 객체입니다.
    ///   자산을 불러오는데 성공하면 자산 배열을 전달하고, 실패 시에도 빈 배열을 반환합니다.
    ///
    /// 사용 예시:
    /// ```swift
    /// assetUtility.fetchAssetsSorted(by: .creationDate(ascending: true))
    ///   .sink { assets in
    ///       print("정렬된 자산: \(assets)")
    ///   }
    ///   .store(in: &cancellables)
    /// ```
    ///
    /// 이 메서드는 비동기적으로 사진첩에 접근하여 사용자가 지정한 기준에 따라 자산을 정렬한 후 결과를 반환합니다.
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

    /// 특정 필터 조건에 맞는 자산을 불러오는 메서드
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

    /// 특정 앨범에서 자산을 불러오는 메서드
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

    /// 자산을 삭제하는 메서드
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

    /// 자산을 저장하는 메서드
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

    /// 자산 메타데이터를 가져오는 메서드
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

    /// 자산의 썸네일을 생성하는 메서드
    public func generateThumbnail(for asset: PHAsset, size: CGSize) -> Future<UIImage, Error> {
        return Future { promise in
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { image, _ in
                if let image = image {
                    promise(.success(image))
                } else {
                    promise(.failure(NSError(domain: "com.example.AssetUtility", code: 1, userInfo: [NSLocalizedDescriptionKey: "썸네일을 생성할 수 없습니다."])))
                }
            }
        }
    }

    /// 특정 미디어 유형의 자산 개수를 반환하는 메서드
    public func getAssetCount(for mediaType: MediaType) -> Future<Int, Never> {
        return Future { promise in
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", mediaType.rawValue)
            let assetCount = PHAsset.fetchAssets(with: fetchOptions).count
            promise(.success(assetCount))
        }
    }
}
