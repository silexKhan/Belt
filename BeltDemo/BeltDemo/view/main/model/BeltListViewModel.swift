//
//  BeltListViewModel.swift
//  BeltDemo
//
//  Created by ahn kyu suk on 9/10/24.
//

import Foundation
import Combine
import UIKit

class BeltListViewModel {
    
    struct Input {
        let ready: AnyPublisher<Void, Never>
        let select: AnyPublisher<IndexPath, Never>
    }
    
    struct Output {
        let reload: AnyPublisher<Void, Never>
        let present: AnyPublisher<UIViewController?, Never>
    }
    //output
    private var reload = PassthroughSubject<Void, Never>()
    private var present = PassthroughSubject<UIViewController?, Never>()
    
    //member
    private var cancellables: Set<AnyCancellable> = []
    
    func transform(input: Input) -> Output {
        input.ready
            .sink(receiveValue: readyHandler)
            .store(in: &cancellables)
        input.select
            .sink(receiveValue: selectHandler)
            .store(in: &cancellables)
        return Output(
            reload: reload.eraseToAnyPublisher(),
            present: present.eraseToAnyPublisher()
        )
    }
    
}

extension BeltListViewModel {
    
    private func readyHandler() {
        reload.send()
    }
    
    /// 목록 선택 처리
    /// - Parameter indexPath: 선택된 List의 indexPath
    private func selectHandler(indexPath: IndexPath) {
        let utility = type(indexPath: indexPath)
        present.send(utility.viewController)
    }
}

extension BeltListViewModel {
    
    func numberOfRowsInSection() -> Int {
        return BeltUtility.allCases.count
    }
    
    func title(indexPath: IndexPath) -> String {
        return type(indexPath: indexPath).identifier
    }
    
    private func type(indexPath: IndexPath) -> BeltUtility {
        return BeltUtility.allCases[indexPath.row]
    }
    
}


