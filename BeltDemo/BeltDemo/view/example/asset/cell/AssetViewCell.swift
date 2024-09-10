//
//  AssetViewCell.swift
//  BeltDemo
//
//  Created by ahn kyu suk on 9/10/24.
//

import Foundation
import UIKit
import Combine

class AssetViewCell: UICollectionViewCell {
    
    @IBOutlet weak var thumbnail: UIImageView!
    var cancellables = Set<AnyCancellable>()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnail.image = nil // 셀 재사용 시 이미지 초기화
        cancellables.removeAll() // 이전의 비동기 작업 취소
    }
}
