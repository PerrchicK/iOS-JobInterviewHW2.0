//
//  DrawerContainerViewController.swift
//  JobInterviewHW2.0
//
//  Created by Perry on 30/11/2017.
//  Copyright © 2017 perrchick. All rights reserved.
//

import UIKit
import MMDrawerController
import FLEX

class DrawerContainerViewController: MMDrawerController {

    /// https://stackoverflow.com/questions/28187261/ios-swift-fatal-error-use-of-unimplemented-initializer-init
    override init?(center centerViewController: UIViewController!, leftDrawerViewController: UIViewController!) {
        super.init(center: centerViewController, leftDrawerViewController: leftDrawerViewController)
    }

    override init?(center centerViewController: UIViewController!, leftDrawerViewController: UIViewController!, rightDrawerViewController: UIViewController!) {
        super.init(center: centerViewController, leftDrawerViewController: leftDrawerViewController, rightDrawerViewController: rightDrawerViewController)
    }
    
    var isMenuOpen: Bool {
        return openSide != .none
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init() {
        // Create:
        let mapViewController: MapViewController = MapViewController.instantiate()
        let leftMenuViewController = LeftMenuViewController.instantiate()

        self.init(center: mapViewController, leftDrawerViewController: leftMenuViewController)!

        // Configure:
        leftMenuViewController.delegate = self
        openDrawerGestureModeMask = .all
        closeDrawerGestureModeMask = .all
        shouldStretchDrawer = true
        let customTitleButton = UIButton()
        let customTitleView = UIView()
        customTitleView.backgroundColor = UIColor.red
        //customTitleView.addSubview(customTitleButton)
        //b.stretchToSuperViewEdges()
        navigationItem.titleView = customTitleButton
        customTitleButton.setTitle("i Here U", for: UIControlState.normal)
        customTitleButton.setTitleColor(UIColor.black, for: UIControlState.normal)
        customTitleButton.onClick { _ in
            📗("TODO: Open sub menu")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func open() {
        open(.left, animated: true, completion: nil)
    }
    
    func close() {
        closeDrawer(animated: true, completion: nil)
    }
    
    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            FLEXManager.shared().showExplorer()
//            if isMenuOpen {
//                close()
//            } else {
//                open()
//            }
        }
    }
}

extension DrawerContainerViewController: LeftMenuViewControllerDelegate {
    func leftMenuViewController(_ leftMenuViewController: LeftMenuViewController, selectedOption: LeftMenuOptions.MenuOption) {
        close()

        switch selectedOption.symbol {
        case LeftMenuOptions.About.AboutApp.symbol: // LeftMenuOptions.About.AboutApp():
            navigationController?.pushViewController(AboutViewController.instantiate(), animated: true)
        case LeftMenuOptions.Application.WhereIsHere.symbol:
            if let currentLocation = LocationHelper.shared.currentLocation?.coordinate {
                LocationHelper.fetchAddressByCoordinates(latitude: currentLocation.latitude, longitude: currentLocation.longitude, completion: { address in
                    if let address = address {
                        let currentLocation = currentLocation.toString()
                        UIAlertController.makeActionSheet(title: "You are here:", message: "\(address)\n\(currentLocation)")
                            .withAction(UIAlertAction(title: "Thanks", style: UIAlertActionStyle.cancel, handler: nil))
                            .withAction(UIAlertAction(title: "Copy coordinates", style: UIAlertActionStyle.default, handler: { _ in
                                PerrFuncs.copyToClipboard(stringToCopy: currentLocation)
                            }))
                            .withAction(UIAlertAction(title: "Center map", style: UIAlertActionStyle.default, handler: { [weak self] _ in
                                (self?.centerViewController as? MapViewController)?.moveCameraToCurrentLocation()
                            }))
                            .show()
                    } else {
                        UIAlertController.makeAlert(title: "Error", message: "Failed to fetch address")
                            .withAction(UIAlertAction(title: "Fine", style: UIAlertActionStyle.cancel, handler: nil))
                            .show()
                    }
                })
            }
        case LeftMenuOptions.Application.WhereIsMapCenter.symbol:
            if let currentMapLocation = (centerViewController as? MapViewController)?.currentMapViewCenter {
                LocationHelper.fetchAddressByCoordinates(latitude: currentMapLocation.latitude, longitude: currentMapLocation.longitude, completion: { address in
                    if let address = address {
                        UIAlertController.makeActionSheet(title: "Map current location:", message: "\(address)\n\(currentMapLocation.toString())")
                            .withAction(UIAlertAction(title: "Thanks", style: UIAlertActionStyle.cancel, handler: nil))
                            .withAction(UIAlertAction(title: "Copy coordinates", style: UIAlertActionStyle.default, handler: { _ in
                                PerrFuncs.copyToClipboard(stringToCopy: currentMapLocation.toString())
                            }))
                            .show()
                    } else {
                        UIAlertController.makeAlert(title: "Error", message: "Failed to fetch address")
                            .withAction(UIAlertAction(title: "Fine", style: UIAlertActionStyle.cancel, handler: nil))
                            .show()
                    }
                })
            }
        default:
            UIAlertController.alert(title: "Under contruction 🔨", message: "to be continued... 😉")
            📗("to be continued...")
        }
    }
    
    override func prepare(toPresentDrawer drawer: MMDrawerSide, animated: Bool) {
        super.prepare(toPresentDrawer: drawer, animated: animated)

        NotificationCenter.default.post(name: Notification.Name.DrawerWillOpen, object: nil)
    }
}

extension Notification.Name {
    static var DrawerWillOpen = Notification.Name(rawValue: "DrawerWillOpenNotification")
    static var CloseDrawer = Notification.Name(rawValue: "CloseDrawer")
}
