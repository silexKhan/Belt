//
//  AudioViewModel.swift
//  BeltDemo
//
//  Created by ahn kyu suk on 9/11/24.
//

import Foundation
import Belt
import Combine

class AudioViewModel {
    
    struct Input {
        let ready: AnyPublisher<Void, Never>
        let playSystemSound: AnyPublisher<Void, Never>
    }
    
    struct Output {
        
    }
    
    private var audio = AudioUtility()
    
    private var cancellables = Set<AnyCancellable>()
    
    func transform(input: Input) -> Output {
        input.ready
            .sink(receiveValue: readyHandler)
            .store(in: &cancellables)
        input.playSystemSound
            .sink(receiveValue: playSystemSoundHandler)
            .store(in: &cancellables)
        return Output(
        )
    }
}

extension AudioViewModel {
    
    private func readyHandler() {
        
    }
    
    private func playSystemSoundHandler() {
        audio.playSystemSound(.newMail)
    }
}
