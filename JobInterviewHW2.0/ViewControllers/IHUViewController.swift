//
//  IHUViewController.swift
//  JobInterviewHW2.0
//
//  Created by Perry on 01/12/2017.
//  Copyright © 2017 perrchick. All rights reserved.
//

import UIKit
import CoreLocation

class IHUViewController: UIViewController, LocationHelperDelegate {

    var applicationDidBecomeActiveNotificationObserver: NotificationObserver?
    var reachabilityNotificationObserver: NotificationObserver?

    var currentLocation: CLLocation?

    var shouldForceLocationPermissions: Bool {
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        applicationDidBecomeActiveNotificationObserver = NotificationObserver.newObserverForNotificationWithName(name: Notification.Name.UIApplicationDidBecomeActive, object: nil, usingBlock: { [weak self] (notification) in
            self?.applicationDidBecomeActive(notification: notification)
        })

        reachabilityNotificationObserver = NotificationObserver.newObserverForNotificationWithName(name: Notification.Name.ReachabilityDidChange, object: nil, usingBlock: { [weak self] (notification) in
            self?.reachabilityDidChange(notification: notification)
        })

        presentPermissionsScreenIfNeeded()

        LocationHelper.shared.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.post(name: Notification.Name.CloseDrawer, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        applicationDidBecomeActiveNotificationObserver = nil
        reachabilityNotificationObserver = nil
    }

    func presentPermissionsScreenIfNeeded() {
        if shouldForceLocationPermissions && !LocationHelper.shared.isPermissionGranted {
            present(PermissionRequestViewController(), animated: true, completion: nil)
        }
    }
    
    func applicationDidBecomeActive(notification: Notification) {
        presentPermissionsScreenIfNeeded()
    }
    
    func reachabilityDidChange(notification: Notification) {
        guard let status = Reachability.shared?.currentReachabilityStatus else { return }
        📗("Network reachability status changed: \(status)")
        
        switch status {
        case .notReachable:
            navigationController?.navigationBar.barTintColor = UIColor.red
        case .reachableViaWiFi: fallthrough
        case .reachableViaWWAN:
            navigationController?.navigationBar.barTintColor = nil
        }
    }

    func onLocationUpdated(updatedLocation: CLLocation) {
        currentLocation = updatedLocation
    }
}
