//
//  AudioUtility.swift
//
//
//  Created by ahn kyu suk on 9/5/24.
//

import Foundation
import AVFoundation
import Combine
import MediaPlayer
import AudioToolbox
import UIKit

/// The `AudioUtility` class is designed to simplify audio playback, volume control, and vibration handling in iOS apps.
/// It provides features to play sounds from the app's bundle, trigger system sounds and vibrations, control the system volume,
/// and subscribe to real-time audio playback and volume changes using Combine.
///
/// ## Features:
/// - **Play bundled audio files**: Easily play audio files included in the app's bundle.
/// - **Play system sounds**: Trigger system sounds like device lock or notification sounds.
/// - **Play vibration patterns**: Trigger vibration patterns using system vibrations.
/// - **Monitor system volume**: Get the current system volume and observe real-time volume changes.
/// - **Combine support**: Use Combine to subscribe to audio playback status and volume changes.
///
/// ## Example Usage:
/// ```swift
/// let audioUtility = AudioUtility()
///
/// // Play a sound from the app's bundle
/// audioUtility.playSound(named: "sound", withExtension: "mp3")
///     .sink(receiveCompletion: { completion in
///         if case .failure(let error) = completion {
///             print("Error playing sound: \(error)")
///         }
///     }, receiveValue: { success in
///         print("Sound played successfully: \(success)")
///     })
///
/// // Play a system sound
/// audioUtility.playSystemSound(.lockDevice)
///
/// // Trigger a vibration pattern
/// audioUtility.playVibration(pattern: .light)
///
/// // Subscribe to volume changes
/// let cancellableVolume = audioUtility.volumePublisher
///     .sink { newVolume in
///         print("Volume changed to: \(newVolume)")
///     }
///
/// // Provide a volume control UI
/// let volumeView = audioUtility.provideVolumeView(frame: CGRect(x: 20, y: 100, width: 250, height: 50))
/// view.addSubview(volumeView)
/// ```
public class AudioUtility: NSObject {
    
    private var audioPlayer: AVAudioPlayer?
    private let volumeSubject = PassthroughSubject<Float, Never>()
    
    /// 현재 오디오 재생 상태를 외부로 전달하는 퍼블리셔
    public let isPlayingPublisher = CurrentValueSubject<Bool, Never>(false)
    
    /// 볼륨 변경 이벤트를 전달하는 퍼블리셔
    public var volumePublisher: AnyPublisher<Float, Never> {
        return volumeSubject.eraseToAnyPublisher()
    }
    
    //combine
    private var cancellables: Set<AnyCancellable> = []
    
    override public init() {
        super.init()
        observeVolumeChanges()
    }

    /// Plays an audio file included in the app's bundle.
    /// - Parameters:
    ///   - fileName: The name of the audio file (without the extension).
    ///   - ext: The file extension (e.g., "mp3", "wav").
    /// - Returns: A publisher that emits `true` if the sound played successfully, or an error if playback failed.
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
    
    /// Plays a system sound based on the specified sound identifier.
    /// - Parameter sound: The system sound to be played (e.g., lock device sound, notification sound).
    public func playSystemSound(_ sound: SystemSound) {
        AudioServicesPlaySystemSound(sound.rawValue)
    }
    
    /// Triggers a vibration pattern.
    /// - Parameter pattern: The vibration pattern to trigger (e.g., light, medium, or heavy vibration).
    public func playVibration(pattern: Vibrations) {
        AudioServicesPlaySystemSound(pattern.rawValue)
    }
    
    /// Retrieves the current system volume level.
    /// - Returns: The current system volume as a float value between 0.0 (mute) and 1.0 (maximum).
    public func getSystemVolume() -> Float {
        return AVAudioSession.sharedInstance().outputVolume
    }
    
    /// Observes changes in the system volume and publishes the updated volume.
    /// This method uses Key-Value Observing (KVO) to detect volume changes.
    private func observeVolumeChanges() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(true)
        
        // Key-Value Observing (KVO)로 볼륨 변경 감지
        audioSession.publisher(for: \.outputVolume)
            .sink { newVolume in
                let volume = audioSession.outputVolume
                self.volumeSubject.send(volume)
            }
            .store(in: &cancellables)
    }
    /// Provides a volume control UI using `MPVolumeView`.
    /// This is required to give users manual control over the system volume, as programmatic volume changes are restricted.
    /// - Parameter frame: The frame to display the volume control view.
    /// - Returns: An `MPVolumeView` instance that displays the volume slider.
    public func provideVolumeView(frame: CGRect) -> MPVolumeView {
        let volumeView = MPVolumeView(frame: frame)
        volumeView.showsVolumeSlider = true
        volumeView.showsRouteButton = false
        return volumeView
    }
}


extension AudioUtility: AVAudioPlayerDelegate {
    
    /// Delegate method that triggers when audio playback finishes.
    /// Updates the `isPlayingPublisher` to notify subscribers that playback has completed.
    /// - Parameter player: The audio player that completed playback.
    /// - Parameter flag: Indicates whether the playback finished successfully.
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlayingPublisher.send(!flag)
    }
}
