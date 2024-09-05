//
//  File.swift
//  
//
//  Created by ahn kyu suk on 9/5/24.
//

import Foundation
import UserNotifications
import Combine

/**
 NotificationUtility 클래스는 iOS에서 로컬 및 푸시 알림을 관리하는 유틸리티 클래스입니다.
 이 클래스는 사용자에게 알림 권한을 요청하고, 로컬 알림을 생성 및 삭제하는 기능을 제공합니다.
 
 주요 기능:
 - **알림 권한 요청**: 앱이 사용자에게 알림을 보낼 수 있도록 권한을 요청합니다.
 - **로컬 알림 생성**: 사용자에게 지정된 시간에 알림을 전송합니다.
 - **알림 삭제**: 특정 알림을 삭제하거나, 예정된 모든 알림을 제거합니다.
 - **알림 설정 확인**: 사용자가 알림을 허용했는지 여부를 확인할 수 있습니다.
 
 이 클래스는 알림 관련 기능을 간편하게 관리할 수 있도록 설계되었습니다.
 */
public class NotificationUtility {
    
    /// 푸시 알림 권한을 요청하는 메서드
    /// - Returns: 권한이 허용되었는지 여부를 비동기적으로 반환하는 `Future`
    public func requestNotificationPermission() -> Future<Bool, Never> {
        return Future { promise in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                switch settings.authorizationStatus {
                case .authorized, .provisional:
                    promise(.success(true))
                case .denied:
                    promise(.success(false))
                case .notDetermined:
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                        promise(.success(granted))
                    }
                @unknown default:
                    promise(.success(false))
                }
            }
        }
    }
    
    /// 로컬 알림을 생성하는 메서드
    /// - Parameters:
    ///   - title: 알림의 제목
    ///   - body: 알림의 본문
    ///   - timeInterval: 알림이 발송될 시간 간격 (초 단위)
    ///   - identifier: 알림을 구분하는 고유 식별자
    public func scheduleLocalNotification(title: String, body: String, timeInterval: TimeInterval, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("로컬 알림 추가 중 오류 발생: \(error.localizedDescription)")
            }
        }
    }
    
    /// 지정된 알림을 삭제하는 메서드
    /// - Parameter identifier: 삭제할 알림의 식별자
    public func removePendingNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    /// 모든 예정된 알림을 삭제하는 메서드
    public func removeAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    /// 전달된 알림을 삭제하는 메서드
    /// - Parameter identifier: 전달된 알림의 식별자
    public func removeDeliveredNotification(identifier: String) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
    }
    
    /// 모든 전달된 알림을 삭제하는 메서드
    public func removeAllDeliveredNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    /// 현재 알림 설정을 가져오는 메서드
    /// - Returns: 알림 권한 상태를 반환하는 `Future`
    public func getNotificationSettings() -> Future<UNNotificationSettings, Never> {
        return Future { promise in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                promise(.success(settings))
            }
        }
    }
}
