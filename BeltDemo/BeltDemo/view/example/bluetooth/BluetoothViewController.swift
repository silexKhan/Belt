//
//  BluetoothViewController.swift
//  BeltDemo
//
//  Created by ahn kyu suk on 9/11/24.
//

import Foundation
import UIKit
import Combine
import Belt

class BluetoothViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var viewModel = BluetoothViewModel()
    //input
    private var startScanning = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataBinding()
        startScanning.send()
    }
    
    private func dataBinding() {
        let output = viewModel.transfrom(input: createInput())
        output.reload
            .sink(receiveValue: tableView.reloadData)
            .store(in: &cancellables)
    }
    
    private func createInput() -> BluetoothViewModel.Input {
        return BluetoothViewModel.Input(
            startScanning: startScanning.eraseToAnyPublisher()
        )
    }
}

extension BluetoothViewController {
    
}

extension BluetoothViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRowsInSection()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath) as? BluetoothListCell else {
            return UITableViewCell()
        }
        let model = viewModel.model(indexPath: indexPath)
        cell.title.text = model.title
        cell.infomations.text = model.descript
        return cell
    }
    
    
}
