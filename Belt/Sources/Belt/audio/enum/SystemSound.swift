//
//  File.swift
//  
//
//  Created by ahn kyu suk on 9/5/24.
//

import Foundation

/// 자주 사용되는 시스템 사운드를 정의한 enum
public enum SystemSound: UInt32 {
    case newMail = 1000           // 새로운 메일 도착음
    case mailSent = 1001          // 메일 전송음
    case smsReceived = 1002       // SMS 도착음
    case calendarAlert = 1003     // 시스템 경고음
    case lowPower = 1004          // 로우 배터리 경고음
    case tweetSent = 1016         // 트위터 전송 사운드
    case photoShutter = 1108      // 카메라 셔터음
    case photoAlbumAdded = 1007   // 포토 앨범 추가음
    case photoAlbumRemoved = 1008 // 포토 앨범 삭제음
    case voicemailReceived = 1011 // Voicemail 도착음
    case lockDevice = 1100        // 장치 잠금음
    case unlockDevice = 1101      // 장치 잠금 해제음
    case typingSound = 1104       // 키보드 타이핑 소리
}
