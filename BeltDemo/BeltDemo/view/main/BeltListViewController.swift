//
//  BeltListViewController.swift
//  BeltDemo
//
//  Created by ahn kyu suk on 9/10/24.
//

import Foundation
import UIKit
import Combine

class BeltListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var viewModel = BeltListViewModel()
    
    //input
    private var ready = PassthroughSubject<Void, Never>()
    private var select = PassthroughSubject<IndexPath, Never>()
    
    private var cancellables: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configUI()
        binding()
        ready.send()
    }
    
    private func configUI() {
        title = "Belt"
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        setNavigationEffect()
    }
    
    private func setNavigationEffect() {
        let appearance = UINavigationBarAppearance()

        // 투명한 배경 및 블러 효과 설정
        appearance.configureWithTransparentBackground()

        // 블러 효과를 적용
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        appearance.backgroundEffect = blurEffect

        // 타이틀 텍스트 색상 (다크 모드 대응)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]

        // 뒤로가기 버튼 아이콘 및 텍스트 색상 설정
        navigationController?.navigationBar.tintColor = UIColor.label

        // 네비게이션 바에 appearance 설정 적용
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance // Compact height에서 적용 (옵션)

        // 네비게이션 바 배경색을 투명하게 설정
        navigationController?.navigationBar.isTranslucent = true
    }
    
    private func binding() {
        let output = viewModel.transform(input: createInput())
        output.reload
            .receive(on: RunLoop.main)
            .sink(receiveValue: tableView.reloadData)
            .store(in: &cancellables)
        output.present
            .sink(receiveValue: presentExample)
            .store(in: &cancellables)
    }
    
    private func createInput() -> BeltListViewModel.Input {
        return BeltListViewModel.Input(
            ready: ready.eraseToAnyPublisher(), 
            select: select.eraseToAnyPublisher()
        )
    }
}


extension BeltListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRowsInSection()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath) as? BeltListCell else {
            return UITableViewCell()
        }
        cell.name.text = viewModel.title(indexPath: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        select.send(indexPath)
    }
}

extension BeltListViewController {
    
    private func presentExample(viewController: UIViewController?) {
        guard let viewController = viewController else { return }
        navigationController?.pushViewController(viewController, animated: true)
    }
}

extension BeltListViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return self.navigationController?.viewControllers.count ?? 0 > 1
    }
}
