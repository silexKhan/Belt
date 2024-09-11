//
//  AnimationViewController.swift
//  BeltDemo
//
//  Created by ahn kyu suk on 9/10/24.
//

import Foundation
import UIKit
import Combine
import Belt

class AnimationViewController: UIViewController {
    
    @IBOutlet weak var start: UIButton!
    
    let animationUtility = AnimationUtility()
    var cancellables = Set<AnyCancellable>()
    
    // Views that will be animated
    var view1: UIView!
    var view2: UIView!
    var view3: UIView!
    var view4: UIView!
    
    // Original positions and transforms
    var originalPositions: [UIView: CGPoint] = [:]
    var originalTransforms: [UIView: CGAffineTransform] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        configUI()
        eventBinding() // Event binding should be called here to bind the button tap event
    }
    
    private func eventBinding() {
        start.tapPublisher
            .sink(receiveValue: { [weak self] in
                self?.startHandler()
            })
            .store(in: &cancellables)
    }
    
    private func configUI() {
        title = "Animation"
        // Initialize and configure the views
        view1 = createColoredView(color: .red, frame: CGRect(x: 50, y: 100, width: 100, height: 100))
        view2 = createColoredView(color: .blue, frame: CGRect(x: 200, y: 100, width: 100, height: 100))
        view3 = createColoredView(color: .green, frame: CGRect(x: 50, y: 250, width: 100, height: 100))
        view4 = createColoredView(color: .yellow, frame: CGRect(x: 200, y: 250, width: 100, height: 100))
        
        // Add the views to the main view
        view.addSubview(view1)
        view.addSubview(view2)
        view.addSubview(view3)
        view.addSubview(view4)
        
        // Save the original positions and transforms
        originalPositions[view1] = view1.center
        originalPositions[view2] = view2.center
        originalPositions[view3] = view3.center
        originalPositions[view4] = view4.center
        
        originalTransforms[view1] = view1.transform
        originalTransforms[view2] = view2.transform
        originalTransforms[view3] = view3.transform
        originalTransforms[view4] = view4.transform
    }
    
    // Helper function to create colored views
    func createColoredView(color: UIColor, frame: CGRect) -> UIView {
        let view = UIView(frame: frame)
        view.backgroundColor = color
        return view
    }
}

extension AnimationViewController {
    
    private func startHandler() {
        // Fade out and fade in animation on view1
        animationUtility.fadeOut(view1, duration: 1.0) { [weak self] in
            self?.animationUtility.fadeIn(self!.view1, duration: 1.0) {
                // Reset view1 to its original state after the animation
                if let originalTransform = self?.originalTransforms[self!.view1] {
                    self?.view1.transform = originalTransform
                }
            }
        }
        
        // Move view2 with a spring effect to a new position, then move it back
        animationUtility.moveViewWithSpring(view2, to: CGPoint(x: 300, y: 400), duration: 1.5, damping: 0.5, velocity: 1.0) { [weak self] in
            // Move view2 back to its original position after the animation
            if let originalPosition = self?.originalPositions[self!.view2] {
                self?.animationUtility.moveViewWithSpring(self!.view2, to: originalPosition, duration: 1.5, damping: 0.5, velocity: 1.0, completion: nil)
            }
        }
        
        // Shake animation on view3
        animationUtility.shakeView(view3, duration: 0.1) { [weak self] in
            // Reset view3 to its original state after the animation
            if let originalTransform = self?.originalTransforms[self!.view3] {
                self?.view3.transform = originalTransform
            }
        }
        
        // Rotate view4 with a spring effect, then rotate it back to its original state
        animationUtility.rotateViewWithSpring(view4, angle: .pi, duration: 1.5, damping: 0.5, velocity: 1.0) { [weak self] in
            // Rotate view4 back to its original state
            if let originalTransform = self?.originalTransforms[self!.view4] {
                self?.animationUtility.rotateViewWithSpring(self!.view4, angle: 0, duration: 1.5, damping: 0.5, velocity: 1.0, completion: nil)
            }
        }
    }
}
