//
//  File.swift
//  
//
//  Created by ahn kyu suk on 9/5/24.
//

import Foundation
import Combine
import UserNotifications

/// A utility class for managing push and local notifications in iOS.
/// This class handles requesting notification permissions, scheduling local notifications, and removing notifications.
/// It leverages the `Combine` framework for reactive and asynchronous handling of notification requests and settings.
///
/// The class allows for scheduling local notifications, removing pending or delivered notifications, and checking the current notification settings.
/// It also ensures proper error handling and prevents duplicate permission requests.
///
/// # Features:
/// - Request notification permissions
/// - Schedule local notifications
/// - Remove pending or delivered notifications
/// - Fetch the current notification settings
///
/// # Example Usage:
///
/// ```swift
/// let notificationUtility = NotificationUtility()
///
/// // Request notification permission
/// notificationUtility.requestNotificationPermission()
///     .sink { granted in
///         if granted {
///             print("Notification permission granted.")
///         } else {
///             print("Notification permission denied.")
///         }
///     }
///     .store(in: &cancellables)
///
/// // Schedule a local notification
/// notificationUtility.scheduleLocalNotification(
///     title: "Reminder",
///     body: "Don't forget your meeting!",
///     timeInterval: 60,
///     identifier: "meeting_reminder"
/// )
/// .sink(receiveCompletion: { completion in
///     switch completion {
///     case .finished:
///         print("Notification scheduled successfully.")
///     case .failure(let error):
///         print("Error scheduling notification: \(error.localizedDescription)")
///     }
/// }, receiveValue: { success in
///     print("Notification scheduling result: \(success)")
/// })
/// .store(in: &cancellables)
///
/// // Remove a specific pending notification
/// notificationUtility.removePendingNotification(identifier: "meeting_reminder")
///
/// // Remove all pending notifications
/// notificationUtility.removeAllPendingNotifications()
///
/// // Fetch current notification settings
/// notificationUtility.getNotificationSettings()
///     .sink { settings in
///         print("Current notification settings: \(settings)")
///     }
///     .store(in: &cancellables)
/// ```
///
/// This example demonstrates how to request notification permissions, schedule a local notification,
/// remove pending notifications, and fetch the current notification settings using `NotificationUtility`.
/// The class provides asynchronous handling and ensures proper error management.
public class NotificationUtility {
    
    private var isRequestingPermission = false  // Prevents duplicate permission requests
    
    /// Requests notification permission from the user.
    /// - Returns: A `Future` that returns `true` if the permission is granted, or `false` otherwise.
    public func requestNotificationPermission() -> Future<Bool, Never> {
        return Future { promise in
            if self.isRequestingPermission {
                promise(.success(false))  // Prevents duplicate permission requests
                return
            }
            
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                switch settings.authorizationStatus {
                case .authorized, .provisional:
                    promise(.success(true))
                case .denied:
                    promise(.success(false))
                case .notDetermined:
                    self.isRequestingPermission = true
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                        self.isRequestingPermission = false
                        promise(.success(granted))
                    }
                @unknown default:
                    promise(.success(false))
                }
            }
        }
    }
    
    /// Schedules a local notification.
    /// - Parameters:
    ///   - title: The title of the notification.
    ///   - body: The body text of the notification.
    ///   - timeInterval: The time interval after which the notification will be triggered (in seconds).
    ///   - identifier: A unique identifier for the notification.
    /// - Returns: A `Future` that returns `true` if the notification was scheduled successfully, or an error if it failed.
    public func scheduleLocalNotification(
        title: String,
        body: String,
        timeInterval: TimeInterval,
        identifier: String
    ) -> Future<Bool, Error> {
        return Future { promise in
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(true))
                }
            }
        }
    }
    
    /// Removes a pending notification by its identifier.
    /// - Parameter identifier: The identifier of the notification to remove.
    public func removePendingNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    /// Removes all pending notifications.
    public func removeAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    /// Removes a delivered notification by its identifier.
    /// - Parameter identifier: The identifier of the delivered notification to remove.
    public func removeDeliveredNotification(identifier: String) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
    }
    
    /// Removes all delivered notifications.
    public func removeAllDeliveredNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    /// Fetches the current notification settings.
    /// - Returns: A `Future` that returns the current `UNNotificationSettings` object.
    public func getNotificationSettings() -> Future<UNNotificationSettings, Never> {
        return Future { promise in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                promise(.success(settings))
            }
        }
    }
}
