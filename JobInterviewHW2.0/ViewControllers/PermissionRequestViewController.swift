//
//  PermissionRequestViewController.swift
//  JobInterviewHW2.0
//
//  Created by Perry on 01/12/2017.
//  Copyright © 2017 perrchick. All rights reserved.
//

import UIKit

class PermissionRequestViewController: IHUViewController {
    override var shouldForceLocationPermissions: Bool {
        return false
    }

    lazy var requestButton: PermissionsView = PermissionsView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(requestButton)
        requestButton.stretchToSuperViewEdges()
        view.backgroundColor = UIColor.white
    }
    
    override func applicationDidBecomeActive(notification: Notification) {
        if LocationHelper.shared.isPermissionGranted {
            dismiss(animated: true, completion: nil)
        }
    }
}
