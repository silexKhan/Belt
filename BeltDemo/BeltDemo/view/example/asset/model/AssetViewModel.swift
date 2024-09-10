//
//  AssetViewModel.swift
//  BeltDemo
//
//  Created by ahn kyu suk on 9/10/24.
//

import Foundation
import Combine
import Belt
import Photos
import UIKit

class AssetViewModel {
    
    struct Input {
        let ready: AnyPublisher<Void, Never>
    }
    
    struct Output {
        let reload: AnyPublisher<Void, Never>
        let alert: AnyPublisher<(String?, String?), Never>
    }
    //output
    private var reload = PassthroughSubject<Void, Never>()
    private var alert = PassthroughSubject<(String?, String?), Never>()
    //members
    private var phAssets = CurrentValueSubject<[PHAsset], Never>([])
    private var cancellables = Set<AnyCancellable>()
    
    //belt
    private var assetUtility = AssetUtility()
    
    func transform(input: Input) -> Output {
        input.ready
            .sink(receiveValue: readyHandler)
            .store(in: &cancellables)
        return Output(
            reload: reload.eraseToAnyPublisher(),
            alert: alert.eraseToAnyPublisher()
        )
    }
    
}

extension AssetViewModel {
    
    private func readyHandler() {
        assetUtility.requestPhotoLibraryAccess()
            .sink { [weak self] granted in
                guard granted else {
                    self?.alert.send(("Album Access Denied", "You do not have permission to access the photo album. Please update your access permissions in settings."))
                    return
                }
                self?.featchAsset()
            }
            .store(in: &cancellables)
    }
    
    private func featchAsset() {
        assetUtility.fetchAssets()
            .sink { [weak self] assets in
                self?.phAssets.send(assets)
                self?.reload.send()
            }
            .store(in: &cancellables)
    }
}

extension AssetViewModel {
    
    func numberOfItemsInSection() -> Int {
        return phAssets.value.count
    }
    
    func thumbnail(for indexPath: IndexPath, size: CGSize) -> AnyPublisher<UIImage?, Never> {
        let asset = phAssets.value[indexPath.row]
        return assetUtility.generateThumbnail(for: asset, size: size)
            .map { $0 as UIImage? } // UIImage를 UIImage?로 변환
            .replaceError(with: nil) // 에러가 발생하면 nil을 반환
            .eraseToAnyPublisher() // AnyPublisher로 변환
    }
    
}
