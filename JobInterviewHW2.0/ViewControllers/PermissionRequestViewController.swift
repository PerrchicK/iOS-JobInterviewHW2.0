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

    lazy var requestButton: UIButton = {
        let requestButton: UIButton = UIButton()
        requestButton.setTitle("grant location permissions".localized(), for: UIControlState.normal)
        self.view.addSubview(requestButton)
        requestButton.stretchToSuperViewEdges()
        return requestButton
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        requestButton.onClick({ _ in // Ron, following our discussion in the interview,
            LocationHelper.shared.requestPermissionsIfNeeded()
        })
    }
    
    override func applicationDidBecomeActive(notification: Notification) {
        if LocationHelper.shared.isPermissionGranted {
            dismiss(animated: true, completion: nil)
        }
    }
}
