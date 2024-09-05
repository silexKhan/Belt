//
//  Vibrations.swift
//
//
//  Created by ahn kyu suk on 9/5/24.
//

import AudioToolbox

/// 자주 사용되는 진동 패턴을 정의한 enum (진동 ID 포함)
public enum Vibrations: SystemSoundID {
    /// 기본 진동 (가벼운 진동)
    case light = 1519
    
    /// 중간 강도의 진동
    case medium = 1520
    
    /// 강한 진동
    case heavy = 1521
    
    /// 두 번 진동 (더블 탭)
    case doubleTap = 1522
    
    /// 세 번 진동 (트리플 탭)
    case tripleTap = 1523
    
    /// 사용자 정의 진동 (커스텀)
    case custom = kSystemSoundID_Vibrate
}
