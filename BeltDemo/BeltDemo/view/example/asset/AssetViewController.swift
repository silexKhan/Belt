//
//  AssetViewController.swift
//  BeltDemo
//
//  Created by ahn kyu suk on 9/10/24.
//

import Foundation
import Combine
import UIKit

class AssetViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    //const
    private let spacing: CGFloat = 2
    
    private var viewModel = AssetViewModel()
    
    private var ready = PassthroughSubject<Void, Never>()
    
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configUI()
        binding()
        ready.send()
    }
    
    private func configUI() {
        title = "Asset"
    }
    
    private func binding() {
        let output = viewModel.transform(input: createInput())
        output.reload
            .receive(on: RunLoop.main)
            .sink(receiveValue: collectionView.reloadData)
            .store(in: &cancellables)
        output.alert
            .sink(receiveValue: showAlert)
            .store(in: &cancellables)
    }
    
    private func createInput() -> AssetViewModel.Input {
        return AssetViewModel.Input(
            ready: ready.eraseToAnyPublisher()
        )
    }
}

extension AssetViewController {
    
}

extension AssetViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfItemsInSection()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "default", for: indexPath) as? AssetViewCell else {
            return UICollectionViewCell()
        }
        
        // ViewModel을 통해 썸네일 비동기 로딩
        viewModel.thumbnail(for: indexPath, size: cell.frame.size)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] image in
                // 로딩된 이미지가 현재 indexPath와 동일한지 확인
                if let currentIndexPath = self?.collectionView.indexPath(for: cell), currentIndexPath == indexPath {
                    cell.thumbnail.image = image
                }
            })
            .store(in: &cell.cancellables)  // 셀의 cancellable 관리
        
        return cell
    }
}

extension AssetViewController: UICollectionViewDelegateFlowLayout {
    
    // 셀 크기 지정 (1:1 비율로, 한 줄에 3개의 셀이 나오도록 설정)
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfCellsInRow: CGFloat = 3
        let totalSpacing = (numberOfCellsInRow - 1) * spacing // 셀 사이의 총 간격
        // collectionView의 전체 폭에서 셀 사이의 간격을 뺀 후 셀의 크기를 계산
        let width = (collectionView.bounds.width - totalSpacing) / numberOfCellsInRow
        
        return CGSize(width: width, height: width) // 1:1 비율 (정사각형 셀)
    }
    
    // 셀 사이의 간격 설정 (위아래 간격)
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return spacing
    }
    
    // 셀 사이의 간격 설정 (좌우 간격)
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return spacing
    }
}

extension AssetViewController {
    
    private func showAlert(title: String?, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}
