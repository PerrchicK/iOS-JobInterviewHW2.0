//
//  ToastMessage.swift
//  SomeApp
//
//  Created by Perry on 2/18/16.
//  Copyright © 2016 PerrchicK. All rights reserved.
//

import Foundation
import UIKit

class ToastMessage: NibView {

    enum ToastMessageLength: TimeInterval {
        case long = 5.0
        case short = 3.0
    }

    @IBOutlet weak var messageLabel: UILabel!
    fileprivate(set) var delay: TimeInterval = 1.0

    static func show(messageText: String, delay: ToastMessageLength = ToastMessageLength.short, onGone: (() -> ())? = nil) {
        guard let appWindow = UIApplication.shared.keyWindow else { fatalError("cannot use keyWindow") }

        let width = UIScreen.main.bounds.width
        let frame = CGRect(x: 0.0, y: 0.0, width: width, height: width / 2.0)
        let toastMessage = ToastMessage(frame: frame)

        toastMessage.delay = delay.rawValue
        toastMessage.isPresented = false
        appWindow.addSubview(toastMessage)
        toastMessage.messageLabel.text = messageText
        toastMessage.backgroundColor = UIColor.gray.withAlphaComponent(0.8)
        toastMessage.layer.cornerRadius = 5
        toastMessage.layer.masksToBounds = true
        toastMessage.isUserInteractionEnabled = false
        // Irrelevant due to the following constraints...
//        toastMessage.center = CGPoint(x: appWindow.center.x, y: appWindow.center.y * 1.5)
        toastMessage.translatesAutoresizingMaskIntoConstraints = false
        let bottomConstraint = NSLayoutConstraint(item: toastMessage, attribute: .bottom, relatedBy: .equal, toItem: toastMessage.superview, attribute: .bottom, multiplier: 1, constant: -30.0)
        let leftConstraint = NSLayoutConstraint(item: toastMessage, attribute: .left, relatedBy: .equal, toItem: toastMessage.superview, attribute: .left, multiplier: 1, constant: 10.0)
        let rightConstraint = NSLayoutConstraint(item: toastMessage, attribute: .right, relatedBy: .equal, toItem: toastMessage.superview, attribute: .right, multiplier: 1, constant: -10.0)
        appWindow/* which is: toastMessage.superview */.addConstraints([bottomConstraint, leftConstraint, rightConstraint])

        let heightConstraint = NSLayoutConstraint(item: toastMessage, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 0.3 * max(appWindow.frame.height, appWindow.frame.width))
        toastMessage.addConstraint(heightConstraint)
        toastMessage.animateFade(fadeIn: true, duration: 0.5)
        toastMessage.animateBounce()

        PerrFuncs.runBlockAfterDelay(afterDelay: toastMessage.delay) {
            toastMessage.animateScaleAndFadeOut { [weak toastMessage] (completed) in
                toastMessage?.messageLabel.text = ""
                toastMessage?.removeFromSuperview()
                onGone?()
            }
        }
    }
}
