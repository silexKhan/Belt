//
//  BluetoothViewModel.swift
//  BeltDemo
//
//  Created by ahn kyu suk on 9/25/24.
//

import Foundation
import Combine
import Belt


class BluetoothViewModel {
    
    struct Input {
        let startScanning: AnyPublisher<Void, Never>
    }
    
    struct Output {
        let reload: AnyPublisher<Void, Never>
    }
    //manager
    private var permissionUtility = PermissionUtility()
    private var bluetoothUtility = BluetoothUtility()
    //members
    private var devices: [BluetoothDevice] = []
    //output
    private var reload = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    func transfrom(input: Input) -> Output {
        input.startScanning
            .sink(receiveValue: startScanning)
            .store(in: &cancellables)
        return Output(
            reload: reload.eraseToAnyPublisher()
        )
    }
}

extension BluetoothViewModel {
    
    private func startScanning() {
        
        permissionUtility.requestPermission(for: .bluetooth)
            .sink { [weak self] sucess in
                print("sucess : ", sucess)
                guard sucess == true else { return }
                self?.bluetoothUtility.startScanning()
            }
            .store(in: &cancellables)
        bluetoothUtility.bluetoothStatePublisher
            .sink { bluetoothState in
                print("bluetoothState : ", bluetoothState)
            }.store(in: &cancellables)
        bluetoothUtility.devicesPublisher
            .sink { [weak self] devices in
                self?.devices = devices
                self?.reload.send()
            }.store(in: &cancellables)
        bluetoothUtility.errorPublisher
            .sink { error in
                print("error : ", error.localizedDescription)
            }.store(in: &cancellables)
    }
}

extension BluetoothViewModel {
    
    func numberOfRowsInSection() -> Int {
        return devices.count
    }
    
    func model(indexPath: IndexPath) -> BluetoothListModel {
        var model = BluetoothListModel()
        let device = devices[indexPath.row]
        model.title = "\(device.name) (\(device.id))"
        model.descript = "\(device.rssi) \(device.advertisementData)"
        return model
    }
}
