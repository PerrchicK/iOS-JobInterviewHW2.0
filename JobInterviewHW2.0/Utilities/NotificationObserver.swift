//
//  NotificationObserver.swift
//  JobInterviewHW2.0
//
//  Created by Perry Sh on 26/09/2016.
//  Copyright © 2018 perrchick. All rights reserved.
//

import Foundation

public class NotificationObserver: CustomDebugStringConvertible {
    private let observer: AnyObject?
    private let observerName: Notification.Name
    private weak var notificationCenter: NotificationCenter?
    
    private init(name: Notification.Name, notificationCenter: NotificationCenter = NotificationCenter.default, object:AnyObject?, usingBlock block: @escaping (Notification) -> Void) {
        self.observer = notificationCenter.addObserver(forName: name, object: object, queue: OperationQueue.main, using: block)
        self.notificationCenter = notificationCenter
        self.observerName = name
    }
    
    deinit {
        if let observer = observer {
            notificationCenter?.removeObserver(observer)
        }
    }
    
    /**
     Usage:
     ```
     let notificationObserver = NotificationObserver.newObserverForNotificationWithName(NOTIFICATION_NAME, object: nil) { (notification) -> Void in
     //…
     }
     // Keep the returned 'notificationObserver' object alive if you want to keep observe the specified notification
     ```
     
     - Parameter name: The notification's name to observe
     - Parameter object: The object whose notifications you want to add the block to the operation queue (notification’s sender).
     - Parameter block: The block to be executed when the notification is received.
     - Returns: NotificationObserver, Keep it alive as long as you want to keep observing
     */
    public class func newObserverForNotificationWithName(name: NSNotification.Name, object: AnyObject?, usingBlock block: @escaping (Notification) -> Void) -> NotificationObserver {
        return NotificationObserver(name: name, object: object, usingBlock: block)
    }
    
    public var debugDescription: String {
        return "observer with notification name: \(self.observerName)"
    }
}
