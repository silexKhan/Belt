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
        let played: AnyPublisher<Void, Never>
    }
    
    private var audio = AudioUtility()
    //output
    private var played = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    func transform(input: Input) -> Output {
        input.ready
            .sink(receiveValue: readyHandler)
            .store(in: &cancellables)
        input.playSystemSound
            .sink(receiveValue: playSystemSoundHandler)
            .store(in: &cancellables)
        return Output(
            played: played.eraseToAnyPublisher()
        )
    }
}

extension AudioViewModel {
    
    private func readyHandler() {
        
    }
    
    private func playSystemSoundHandler() {
        audio.playSystemSound(.newMail)
        played.send()
    }
}
