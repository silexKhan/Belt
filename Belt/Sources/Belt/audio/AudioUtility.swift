//
//  AudioUtility.swift
//
//
//  Created by ahn kyu suk on 9/5/24.
//

/**
 AudioUtility 클래스는 iOS에서 오디오 재생, 볼륨 제어 및 시스템 사운드를 쉽게 처리할 수 있도록 설계된 유틸리티 클래스입니다. 번들에 포함된 오디오 파일을 재생하고, 시스템 사운드 및 진동을 재생하며, 시스템 볼륨을 제어할 수 있습니다. Combine을 활용해 오디오 재생 상태와 볼륨 변경을 실시간으로 구독할 수 있습니다.

 ## 주요 기능:
 - **번들 오디오 파일 재생**: 번들에 포함된 오디오 파일을 재생할 수 있습니다.
 - **시스템 사운드 재생**: iOS에서 제공하는 시스템 사운드를 재생할 수 있습니다.
 - **진동 재생**: 진동을 발생시킬 수 있습니다.
 - **볼륨 제어**: 시스템 볼륨을 변경하고, 실시간으로 볼륨 변화를 감지할 수 있습니다.
 - **Combine 지원**: Combine을 통해 오디오 재생 상태 및 볼륨 변화를 실시간으로 구독할 수 있습니다.

 ## 사용 예시:
 ```swift
 let audioUtility = AudioUtility()

 // 번들 오디오 파일 재생
 audioUtility.playSound(named: "test", withExtension: "mp3")
     .sink(receiveCompletion: { completion in
         if case .failure(let error) = completion {
             print("Error playing sound: \(error)")
         }
     }, receiveValue: { success in
         print("Sound played successfully: \(success)")
     })

 // 시스템 사운드 재생
 audioUtility.playSystemSound(.lockDevice)
 
 // 진동 발생
 audioUtility.playVibration(pattern: .light)
 
 // 현재 시스템 볼륨 가져오기
 let volume = audioUtility.getSystemVolume()
 print("Current system volume: \(volume)")

 // 볼륨 변경 감지 구독
 let cancellableVolume = audioUtility.volumePublisher
     .sink { newVolume in
         print("Volume changed to: \(newVolume)")
     }
 
 // 오디오 재생 상태 구독
 let cancellablePlaying = audioUtility.isPlayingPublisher
     .sink { isPlaying in
         print("Is audio playing? \(isPlaying)")
     }
 
 // MPVolumeView를 제공하여 볼륨 조절 UI 추가, 코드에서 직접 제어가 불가능해서 UI를 제공함
 let volumeView = audioUtility.provideVolumeView(frame: CGRect(x: 20, y: 100, width: 250, height: 50))
 view.addSubview(volumeView)
 ```
 
 이 클래스는 오디오 관련 작업을 간편하게 수행할 수 있도록 구성되어 있으며, Combine을 통해 상태 변경을 실시간으로 처리할 수 있습니다.
 */

import Foundation
import AVFoundation
import Combine
import MediaPlayer
import AudioToolbox
import UIKit

/// 오디오 유틸리티 클래스: 번들 사운드 재생, 시스템 사운드 재생, 볼륨 UI 제공
public class AudioUtility: NSObject {
    
    private var audioPlayer: AVAudioPlayer?
    private let volumeSubject = PassthroughSubject<Float, Never>()
    
    /// 현재 오디오 재생 상태를 외부로 전달하는 퍼블리셔
    public let isPlayingPublisher = CurrentValueSubject<Bool, Never>(false)
    
    /// 볼륨 변경 이벤트를 전달하는 퍼블리셔
    public var volumePublisher: AnyPublisher<Float, Never> {
        return volumeSubject.eraseToAnyPublisher()
    }
    
    override public init() {
        super.init()
        observeVolumeChanges()
    }

    /// 번들에 포함된 오디오 파일 재생
    public func playSound(named fileName: String, withExtension ext: String) -> AnyPublisher<Bool, Error> {
        return Future { promise in
            guard let url = Bundle.main.url(forResource: fileName, withExtension: ext) else {
                promise(.failure(NSError(domain: "File not found", code: -1, userInfo: nil)))
                return
            }
            do {
                self.audioPlayer = try AVAudioPlayer(contentsOf: url)
                self.audioPlayer?.delegate = self
                self.audioPlayer?.prepareToPlay()
                self.audioPlayer?.play()
                self.isPlayingPublisher.send(true)
                promise(.success(true))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 시스템 사운드 재생
    public func playSystemSound(_ sound: SystemSound) {
        AudioServicesPlaySystemSound(sound.rawValue)
    }
    
    /// 진동 재생
    public func playVibration(pattern: Vibrations) {
        AudioServicesPlaySystemSound(pattern.rawValue)
    }
    
    /// 현재 시스템 볼륨 크기를 가져오는 메서드
    public func getSystemVolume() -> Float {
        return AVAudioSession.sharedInstance().outputVolume
    }
    
    /// 시스템 볼륨 변경 감지
    private func observeVolumeChanges() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(true)
        NotificationCenter.default.addObserver(forName: .AVAudioSessionOutputVolumeDidChange, object: nil, queue: .main) { notification in
            let volume = audioSession.outputVolume
            self.volumeSubject.send(volume)
        }
    }

    /// MPVolumeView를 제공하여 시스템 볼륨을 조절할 수 있는 UI를 생성하는 메서드
    public func provideVolumeView(frame: CGRect) -> MPVolumeView {
        let volumeView = MPVolumeView(frame: frame)
        volumeView.showsVolumeSlider = true
        volumeView.showsRouteButton = false  // Route 버튼을 숨길 수도 있습니다
        return volumeView
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioUtility: AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlayingPublisher.send(false)
    }
}
