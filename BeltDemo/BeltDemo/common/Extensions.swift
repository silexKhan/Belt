//
//  Extensions.swift
//  BeltDemo
//
//  Created by ahn kyu suk on 9/10/24.
//

import UIKit
import Combine

// UIButton에 대한 Extension
extension UIButton {
    /// 버튼이 탭될 때 이벤트를 방출하는 Publisher를 생성
    var tapPublisher: AnyPublisher<Void, Never> {
        // UIButton의 이벤트를 처리하기 위해 UIControlPublisher라는 클래스를 이용
        UIControlPublisher(control: self, events: .touchUpInside).eraseToAnyPublisher()
    }
}

// UIControl을 Combine 방식으로 처리하기 위한 Publisher
class UIControlPublisher<Control: UIControl>: Publisher {
    typealias Output = Void
    typealias Failure = Never
    
    private let control: Control
    private let controlEvents: UIControl.Event
    
    init(control: Control, events: UIControl.Event) {
        self.control = control
        self.controlEvents = events
    }
    
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = UIControlSubscription(subscriber: subscriber, control: control, event: controlEvents)
        subscriber.receive(subscription: subscription)
    }
}

// UIControl과 Subscriber를 연결하는 Subscription
class UIControlSubscription<S: Subscriber, Control: UIControl>: Subscription where S.Input == Void {
    private var subscriber: S?
    private weak var control: Control?
    
    init(subscriber: S, control: Control, event: UIControl.Event) {
        self.subscriber = subscriber
        self.control = control
        control.addTarget(self, action: #selector(eventHandler), for: event)
    }
    
    @objc private func eventHandler() {
        _ = subscriber?.receive(())
    }
    
    func request(_ demand: Subscribers.Demand) {
        // We don't care about demand in this case
    }
    
    func cancel() {
        subscriber = nil
    }
}
