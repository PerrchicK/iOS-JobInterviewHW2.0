//
//  PermissionsView.swift
//  JobInterviewHW2.0
//
//  Created by Perry on 01/12/2017.
//  Copyright © 2017 perrchick. All rights reserved.
//

import Foundation

class PermissionsView: NibView {
    @IBOutlet weak var grantButton: UIButton!
    @IBOutlet weak var customViewContainer: UIView!
    @IBOutlet weak var permissionTitle: UILabel!

    override func viewDidLoadFromNib() {
        let mapImageView = UIImageView()
        //An image of Times Sqaure: CLLocationCoordinate2D(latitude: 40.758873, longitude: -73.984916)
        mapImageView.image = #imageLiteral(resourceName: "times-square")
        mapImageView.contentMode = .scaleAspectFit
        customViewContainer.addSubview(mapImageView)
        mapImageView.stretchToSuperViewEdges()
        mapImageView.beOval()

        permissionTitle.localize()
        grantButton.localize()

        grantButton.onClick { _ in
            LocationHelper.shared.requestPermissionsIfNeeded()
        }
    }
}
