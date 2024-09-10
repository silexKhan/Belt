//
//  ReachabilityUtility.swift
//
//
//  Created by ahn kyu suk on 9/5/24.
//

import Foundation
import SystemConfiguration
import Combine

/// A utility class to monitor the network connectivity status using the SCNetworkReachability API.
/// This class provides real-time network status updates (Wi-Fi, cellular, or no connection) using the `Combine` framework.
/// It can be used to check if the device is connected to a network and to determine the type of network connection.
/// The class supports both starting and stopping network monitoring and sends status updates through a `Publisher`.
///
/// # Features:
/// - Monitor network status (Wi-Fi, cellular, or no connection)
/// - Real-time network status updates via `Combine` Publisher
/// - Start and stop monitoring at any time
/// - Determine network connection type
///
/// # Example Usage:
///
/// ```swift
/// let reachabilityUtility = ReachabilityUtility()
///
/// // Start monitoring network status
/// reachabilityUtility.startMonitoring()
///
/// // Subscribe to network status updates
/// reachabilityUtility.networkStatusPublisher
///     .sink { isConnected, connectionType in
///         print("Network connected: \(isConnected)")
///         print("Connection type: \(connectionType)")
///     }
///     .store(in: &cancellables)
///
/// // Stop monitoring network status when no longer needed
/// reachabilityUtility.stopMonitoring()
/// ```
///
/// This example demonstrates how to start monitoring the network status and handle updates using `ReachabilityUtility`.
/// The network connection status and type are printed whenever there is a change in connectivity.
public class ReachabilityUtility {
    
    private var reachability: SCNetworkReachability?
    private var reachabilitySubject = PassthroughSubject<(Bool, NetworkConnectionType), Never>()
    private var previousConnectionStatus: (Bool, NetworkConnectionType)?
    
    /// Publisher that emits real-time network status updates.
    public var networkStatusPublisher: AnyPublisher<(Bool, NetworkConnectionType), Never> {
        return reachabilitySubject.eraseToAnyPublisher()
    }
    
    /// Initializes the Reachability utility with a default hostname (e.g., www.google.com) to check network connectivity.
    /// - Parameter hostname: The hostname used to check network status. Default is "www.google.com".
    public init(hostname: String = "www.google.com") {
        reachability = SCNetworkReachabilityCreateWithName(nil, hostname)
        guard reachability != nil else {
            print("Failed to create reachability reference.")
            return
        }
    }
    
    /// Starts monitoring the network connectivity status and sends updates via the publisher.
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
        
        if !SCNetworkReachabilitySetCallback(reachability, callback, &context) {
            print("Failed to set reachability callback.")
            return
        }
        
        if !SCNetworkReachabilityScheduleWithRunLoop(
            reachability,
            CFRunLoopGetCurrent(),
            CFRunLoopMode.defaultMode.rawValue
        ) {
            print("Failed to schedule reachability with run loop.")
            return
        }
    }
    
    /// Stops monitoring the network connectivity status.
    public func stopMonitoring() {
        guard let reachability = reachability else { return }
        SCNetworkReachabilityUnscheduleFromRunLoop(reachability, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
    }
}

extension ReachabilityUtility {
    
    /// Updates the network connectivity status and sends it through the publisher.
    /// - Parameter flags: The reachability flags that indicate the current network status.
    private func updateReachabilityStatus(flags: SCNetworkReachabilityFlags) {
        let isConnected = flags.contains(.reachable) && !flags.contains(.connectionRequired)
        let connectionType = getConnectionType(flags: flags)
        
        // Prevent sending the same status multiple times
        if previousConnectionStatus?.0 != isConnected || previousConnectionStatus?.1 != connectionType {
            previousConnectionStatus = (isConnected, connectionType)
            DispatchQueue.main.async {
                self.reachabilitySubject.send((isConnected, connectionType))
            }
        }
    }
    
    /// Determines the network connection type (Wi-Fi, cellular, or none) based on the reachability flags.
    /// - Parameter flags: The reachability flags that indicate the current network connection type.
    /// - Returns: The type of network connection: `.wifi`, `.cellular`, or `.none`.
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
