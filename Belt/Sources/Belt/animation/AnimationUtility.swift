//
//  AnimationUtility.swift
//
//
//  Created by ahn kyu suk on 9/5/24.
//

/**
 `AnimationUtility` 클래스는 iOS 애플리케이션에서 자주 사용되는 다양한 애니메이션 효과를 손쉽게 구현할 수 있도록 돕는 유틸리티 클래스입니다. 위치 이동, 크기 변경, 회전 및 페이드 효과와 같은 애니메이션을 간단하게 사용할 수 있습니다. 또한, 스프링 효과를 적용한 동적인 애니메이션도 제공하여 사용자 경험을 향상시킬 수 있습니다.

 ## 주요 기능:
 - **뷰 이동 애니메이션**: `moveView` 및 `moveViewWithSpring`을 통해 UIView의 위치를 변경하는 애니메이션을 제공합니다.
 - **뷰 크기 조절 애니메이션**: `resizeView` 및 `resizeViewWithSpring`으로 뷰의 크기를 동적으로 변경할 수 있습니다.
 - **페이드 인/아웃**: `fadeIn` 및 `fadeOut`을 사용하여 뷰의 투명도를 조정할 수 있습니다.
 - **뷰 회전 애니메이션**: `rotateView` 및 `rotateViewWithSpring`으로 뷰를 회전시킬 수 있습니다.
 - **스프링 효과 애니메이션**: 자연스럽고 동적인 애니메이션 효과를 위해 스프링 애니메이션을 지원합니다.

 ## 사용 예시:
 ```swift
 let animationUtility = AnimationUtility()
 let view = UIView()

 // 뷰를 새로운 위치로 이동
 animationUtility.moveView(view, to: CGPoint(x: 100, y: 200), duration: 0.5) {
     print("이동 애니메이션 완료")
 }

 // 스프링 효과를 적용한 뷰 이동
 animationUtility.moveViewWithSpring(view, to: CGPoint(x: 200, y: 300), duration: 1.0, damping: 0.7, velocity: 0.5) {
     print("스프링 이동 애니메이션 완료")
 }

 // 페이드 인
 animationUtility.fadeIn(view, duration: 0.4) {
     print("페이드 인 완료")
 }

 // 뷰 회전 애니메이션
 animationUtility.rotateView(view, angle: .pi / 2, duration: 0.6) {
     print("회전 애니메이션 완료")
 }
 
 ```
 이 클래스는 다양한 애니메이션 효과를 쉽게 구현할 수 있도록 설계되어 있으며, 사용자 인터페이스에 다채로운 애니메이션을 더할 수 있습니다.
 */

import UIKit


public class AnimationUtility {

    /// 스프링 효과가 있는 뷰 이동 애니메이션
    /// - Parameters:
    ///   - view: 이동할 뷰
    ///   - to: 이동할 위치
    ///   - duration: 애니메이션 지속 시간
    ///   - damping: 뷰의 탄성 효과 (0 ~ 1 사이의 값)
    ///   - velocity: 초기 속도 (크면 클수록 빠르게 시작)
    ///   - completion: 애니메이션 완료 후 처리
    public func moveViewWithSpring(_ view: UIView, to: CGPoint, duration: TimeInterval, damping: CGFloat, velocity: CGFloat, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: velocity, options: [], animations: {
            view.center = to
        }, completion: { _ in
            completion?()
        })
    }
    
    /// 스프링 효과가 있는 뷰 크기 조절 애니메이션
    /// - Parameters:
    ///   - view: 크기 조절할 뷰
    ///   - to: 최종 크기
    ///   - duration: 애니메이션 지속 시간
    ///   - damping: 뷰의 탄성 효과 (0 ~ 1 사이의 값)
    ///   - velocity: 초기 속도 (크면 클수록 빠르게 시작)
    ///   - completion: 애니메이션 완료 후 처리
    public func resizeViewWithSpring(_ view: UIView, to: CGSize, duration: TimeInterval, damping: CGFloat, velocity: CGFloat, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: velocity, options: [], animations: {
            view.bounds.size = to
        }, completion: { _ in
            completion?()
        })
    }
    
    /// 스프링 효과가 있는 뷰 회전 애니메이션
    /// - Parameters:
    ///   - view: 회전할 뷰
    ///   - angle: 회전할 각도
    ///   - duration: 애니메이션 지속 시간
    ///   - damping: 뷰의 탄성 효과 (0 ~ 1 사이의 값)
    ///   - velocity: 초기 속도 (크면 클수록 빠르게 시작)
    ///   - completion: 애니메이션 완료 후 처리
    public func rotateViewWithSpring(_ view: UIView, angle: CGFloat, duration: TimeInterval, damping: CGFloat, velocity: CGFloat, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: velocity, options: [], animations: {
            view.transform = CGAffineTransform(rotationAngle: angle)
        }, completion: { _ in
            completion?()
        })
    }
}

extension AnimationUtility {
    
    /// 스프링 효과가 있는 뷰 이동 애니메이션
    /// - Parameters:
    ///   - view: 이동할 뷰
    ///   - to: 이동할 위치
    ///   - duration: 애니메이션 지속 시간
    ///   - damping: 뷰의 탄성 효과 (0 ~ 1 사이의 값)
    ///   - velocity: 초기 속도 (크면 클수록 빠르게 시작)
    ///   - completion: 애니메이션 완료 후 처리
    public func moveViewWithSpring(_ view: UIView, to: CGPoint, duration: TimeInterval, damping: CGFloat, velocity: CGFloat, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: velocity, options: [], animations: {
            view.center = to
        }, completion: { _ in
            completion?()
        })
    }
    
    /// 스프링 효과가 있는 뷰 크기 조절 애니메이션
    /// - Parameters:
    ///   - view: 크기 조절할 뷰
    ///   - to: 최종 크기
    ///   - duration: 애니메이션 지속 시간
    ///   - damping: 뷰의 탄성 효과 (0 ~ 1 사이의 값)
    ///   - velocity: 초기 속도 (크면 클수록 빠르게 시작)
    ///   - completion: 애니메이션 완료 후 처리
    public func resizeViewWithSpring(_ view: UIView, to: CGSize, duration: TimeInterval, damping: CGFloat, velocity: CGFloat, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: velocity, options: [], animations: {
            view.bounds.size = to
        }, completion: { _ in
            completion?()
        })
    }
    
    /// 스프링 효과가 있는 뷰 회전 애니메이션
    /// - Parameters:
    ///   - view: 회전할 뷰
    ///   - angle: 회전할 각도
    ///   - duration: 애니메이션 지속 시간
    ///   - damping: 뷰의 탄성 효과 (0 ~ 1 사이의 값)
    ///   - velocity: 초기 속도 (크면 클수록 빠르게 시작)
    ///   - completion: 애니메이션 완료 후 처리
    public func rotateViewWithSpring(_ view: UIView, angle: CGFloat, duration: TimeInterval, damping: CGFloat, velocity: CGFloat, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: velocity, options: [], animations: {
            view.transform = CGAffineTransform(rotationAngle: angle)
        }, completion: { _ in
            completion?()
        })
    }
    
}
