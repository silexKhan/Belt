//
//  ReachabilityUtility.swift
//
//
//  Created by ahn kyu suk on 9/5/24.
//


/// ReachabilityUtility는 네트워크 연결 상태(Wi-Fi, 셀룰러 등)를 실시간으로 감지하는 유틸리티 클래스입니다.
/// 이 클래스를 사용하면 네트워크 연결 여부와 연결된 네트워크 타입을 실시간으로 구독할 수 있습니다.
///
/// - 네트워크 상태 변경 시, 연결 여부(`Bool`)와 연결된 네트워크 타입(`NetworkConnectionType`)을 외부로 전달합니다.
///
/// ### 사용 예시:
/// ```swift
/// let reachabilityUtility = ReachabilityUtility()
///
/// reachabilityUtility.networkStatusPublisher
///     .sink { isConnected, connectionType in
///         if isConnected {
///             switch connectionType {
///             case .wifi:
///                 print("Connected via Wi-Fi")
///             case .cellular:
///                 print("Connected via Cellular")
///             case .ethernet:
///                 print("Connected via Ethernet")
///             case .none:
///                 print("No network connection")
///             }
///         } else {
///             print("No network connection")
///         }
///     }
///     .store(in: &cancellables)
///
/// reachabilityUtility.startMonitoring()
/// ```
///
/// - Note: 모니터링을 시작하려면 `startMonitoring()`을 호출해야 합니다.

import Foundation
import SystemConfiguration
import Combine


public class ReachabilityUtility {
    
    private var reachability: SCNetworkReachability?
    private var reachabilitySubject = PassthroughSubject<(Bool, NetworkConnectionType), Never>()
    
    /// 네트워크 상태 변경을 실시간으로 전송하는 Publisher
    public var networkStatusPublisher: AnyPublisher<(Bool, NetworkConnectionType), Never> {
        return reachabilitySubject.eraseToAnyPublisher()
    }
    
    /// Reachability 초기화
    public init(hostname: String = "www.google.com") {
        reachability = SCNetworkReachabilityCreateWithName(nil, hostname)
    }
    
    /// 네트워크 연결 상태를 확인하는 메서드
    public func startMonitoring() {
        guard let reachability = reachability else { return }
        
        var context = SCNetworkReachabilityContext(
            version: 0,
            info: UnsafeMutableRawPointer(Unmanaged<ReachabilityUtility>.passUnretained(self).toOpaque()),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        
        let callback: SCNetworkReachabilityCallBack = { (_, flags, info) in
            let reachability = Unmanaged<ReachabilityUtility>.fromOpaque(info!).takeUnretainedValue()
            reachability.updateReachabilityStatus(flags: flags)
        }
        
        if SCNetworkReachabilitySetCallback(reachability, callback, &context) {
            SCNetworkReachabilityScheduleWithRunLoop(
                reachability,
                CFRunLoopGetCurrent(),
                CFRunLoopMode.defaultMode.rawValue
            )
        }
    }
    
    /// 네트워크 모니터링 중지
    public func stopMonitoring() {
        guard let reachability = reachability else { return }
        SCNetworkReachabilityUnscheduleFromRunLoop(reachability, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
    }
}

extension ReachabilityUtility {
    
    /// 네트워크 상태 업데이트
    private func updateReachabilityStatus(flags: SCNetworkReachabilityFlags) {
        let isConnected = flags.contains(.reachable) && !flags.contains(.connectionRequired)
        let connectionType = getConnectionType(flags: flags)
        reachabilitySubject.send((isConnected, connectionType))
    }
    
    /// 네트워크 연결 타입 확인 (Wi-Fi, 셀룰러, 이더넷, 없음)
    private func getConnectionType(flags: SCNetworkReachabilityFlags) -> NetworkConnectionType {
        if flags.contains(.isWWAN) {
            return .cellular
        } else if flags.contains(.reachable) {
            return .wifi
        } else {
            return .none
        }
    }
}
