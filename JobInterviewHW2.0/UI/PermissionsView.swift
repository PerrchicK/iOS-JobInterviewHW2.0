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

    override func viewDidLoadFromNib() {
        let mapImageView = UIImageView()
        mapImageView.image = #imageLiteral(resourceName: "times-square")
        mapImageView.contentMode = .scaleAspectFit
        customViewContainer.addSubview(mapImageView)
        mapImageView.stretchToSuperViewEdges()

        //let coordinates = CLLocationCoordinate2D(latitude: 40.758873, longitude: -73.984916)
        //mapImageView.animate(toLocation: coordinates)
        
        grantButton.localize()
        grantButton.onClick { _ in
            LocationHelper.shared.requestPermissionsIfNeeded()
        }
    }
}
