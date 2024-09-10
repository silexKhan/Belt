//
//  AnimationUtility.swift
//
//
//  Created by ahn kyu suk on 9/5/24.
//

import Foundation
import UIKit

/// The `AnimationUtility` class helps to easily implement various animation effects commonly used in iOS applications.
/// It supports animations such as movement, resizing, rotation, fade effects, and dynamic spring animations to enhance the user experience.
///
/// ## Key Features:
/// - **View Movement Animation**: Provides `moveView` and `moveViewWithSpring` to animate the position changes of a UIView.
/// - **View Resizing Animation**: Allows dynamic resizing of views using `resizeView` and `resizeViewWithSpring`.
/// - **Fade In/Out**: Adjust the opacity of a view with `fadeIn` and `fadeOut`.
/// - **View Rotation Animation**: Rotate views using `rotateView` and `rotateViewWithSpring`.
/// - **Spring Effect Animation**: Supports spring animations for smooth and dynamic effects.
///
/// ## Example Usage:
/// ```swift
/// let animationUtility = AnimationUtility()
/// let view = UIView()
///
/// // Move the view to a new position
/// animationUtility.moveView(view, to: CGPoint(x: 100, y: 200), duration: 0.5) {
///     print("Move animation completed")
/// }
///
/// // Move the view with a spring effect
/// animationUtility.moveViewWithSpring(view, to: CGPoint(x: 200, y: 300), duration: 1.0, damping: 0.7, velocity: 0.5) {
///     print("Spring move animation completed")
/// }
///
/// // Fade In
/// animationUtility.fadeIn(view, duration: 0.4) {
///     print("Fade in completed")
/// }
///
/// // Rotate the view
/// animationUtility.rotateView(view, angle: .pi / 2, duration: 0.6) {
///     print("Rotation animation completed")
/// }
/// ```
///
/// This class is designed to simplify the implementation of various animation effects,
/// allowing you to add vibrant animations to the user interface.


public class AnimationUtility {
    
    public init() {}    
    /// Fade out animation for a view
    /// - Parameters:
    ///   - view: The view to fade out
    ///   - duration: The duration of the animation
    ///   - completion: Closure to be called upon animation completion
    public func fadeOut(_ view: UIView, duration: TimeInterval, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, animations: {
            view.alpha = 0.0
        }, completion: { _ in
            completion?()
        })
    }
    
    /// Fade in animation for a view
    /// - Parameters:
    ///   - view: The view to fade in
    ///   - duration: The duration of the animation
    ///   - completion: Closure to be called upon animation completion
    public func fadeIn(_ view: UIView, duration: TimeInterval, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, animations: {
            view.alpha = 1.0
        }, completion: { _ in
            completion?()
        })
    }
    
    /// Shake animation for a view
    /// - Parameters:
    ///   - view: The view to apply the shake animation to
    ///   - duration: The duration of the shake animation
    ///   - completion: Closure to be called upon animation completion
    public func shakeView(_ view: UIView, duration: TimeInterval = 0.1, completion: (() -> Void)? = nil) {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = duration
        animation.repeatCount = 4
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: view.center.x - 10, y: view.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: view.center.x + 10, y: view.center.y))
        view.layer.add(animation, forKey: "position")
        completion?()
    }

    /// Scale animation for a view
    /// - Parameters:
    ///   - view: The view to scale
    ///   - scale: The scale factor for the view
    ///   - duration: The duration of the animation
    ///   - completion: Closure to be called upon animation completion
    public func scaleView(_ view: UIView, to scale: CGFloat, duration: TimeInterval, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, animations: {
            view.transform = CGAffineTransform(scaleX: scale, y: scale)
        }, completion: { _ in
            completion?()
        })
    }
}

extension AnimationUtility {

    /// Spring effect movement animation for a view
    /// - Parameters:
    ///   - view: The view to move
    ///   - to: The final position for the view
    ///   - duration: The duration of the animation
    ///   - damping: The damping ratio for the spring effect (0 to 1)
    ///   - velocity: The initial velocity for the animation (higher values start faster)
    ///   - completion: Closure to be called upon animation completion
    public func moveViewWithSpring(_ view: UIView, to: CGPoint, duration: TimeInterval, damping: CGFloat, velocity: CGFloat, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: velocity, options: [], animations: {
            view.center = to
        }, completion: { _ in
            completion?()
        })
    }
    
    /// Spring effect resize animation for a view
    /// - Parameters:
    ///   - view: The view to resize
    ///   - to: The final size for the view
    ///   - duration: The duration of the animation
    ///   - damping: The damping ratio for the spring effect (0 to 1)
    ///   - velocity: The initial velocity for the animation (higher values start faster)
    ///   - completion: Closure to be called upon animation completion
    public func resizeViewWithSpring(_ view: UIView, to: CGSize, duration: TimeInterval, damping: CGFloat, velocity: CGFloat, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: velocity, options: [], animations: {
            view.bounds.size = to
        }, completion: { _ in
            completion?()
        })
    }
    
    /// Spring effect rotation animation for a view
    /// - Parameters:
    ///   - view: The view to rotate
    ///   - angle: The angle to rotate the view
    ///   - duration: The duration of the animation
    ///   - damping: The damping ratio for the spring effect (0 to 1)
    ///   - velocity: The initial velocity for the animation (higher values start faster)
    ///   - completion: Closure to be called upon animation completion
    public func rotateViewWithSpring(_ view: UIView, angle: CGFloat, duration: TimeInterval, damping: CGFloat, velocity: CGFloat, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: velocity, options: [], animations: {
            view.transform = CGAffineTransform(rotationAngle: angle)
        }, completion: { _ in
            completion?()
        })
    }
}

