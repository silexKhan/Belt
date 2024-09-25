//
//  AudioViewController.swift
//  BeltDemo
//
//  Created by ahn kyu suk on 9/11/24.
//

import Foundation
import UIKit
import Belt
import Combine

class AudioViewController: UIViewController {
    
    @IBOutlet weak var systemSound: UIButton!
    
    private var viewModel = AudioViewModel()
    
    //input
    private var ready = PassthroughSubject<Void, Never>()
    private var playSystemSound = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configUI()
        eventBinding()
        binding()
    }
    
    private func configUI() {
        title = "Audio"
    }
    
    private func eventBinding() {
        systemSound.tapPublisher
            .sink(receiveValue: systemSoundHandler)
            .store(in: &cancellables)
    }
    
    private func binding() {
        let output = viewModel.transform(input: createInput())
        output.played
            .sink(receiveValue: playedHandler)
            .store(in: &cancellables)
    }
    
    private func createInput() -> AudioViewModel.Input {
        return AudioViewModel.Input(
            ready: ready.eraseToAnyPublisher(),
            playSystemSound: playSystemSound.eraseToAnyPublisher()
        )
    }
}

extension AudioViewController {
    
    private func systemSoundHandler() {
        playSystemSound.send()
    }
    
    private func playedHandler() {
        //update ui
    }
}
