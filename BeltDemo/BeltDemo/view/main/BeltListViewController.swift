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
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = self
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
