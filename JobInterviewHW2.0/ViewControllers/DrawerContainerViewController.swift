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
    
    var mapViewController: MapViewController {
        return centerViewController as! MapViewController // Yes, forcing unwrap, because it it's nil than it's MY problem (the developer's problem, a missing implementation bug)
    }
    
    var isMenuOpen: Bool {
        return openSide != .none
    }

    lazy var aboutViewController: AboutViewController = AboutViewController.instantiate()
    
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
        customTitleButton.setTitle("-= I Here You =-", for: UIControlState.normal)
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
            aboutViewController.aboutTitle = "About the app".localized()
            aboutViewController.aboutText = "about the app info".localized()
            aboutViewController.title = "About"
            navigationController?.present(aboutViewController, animated: true, completion: nil)
        case LeftMenuOptions.Driving.LeaveParking.symbol:
            aboutViewController.aboutTitle = "How iLeave works?".localized()
            aboutViewController.title = "iLeave"
            aboutViewController.aboutText = "Simply takes your location automatically and shares it with anyone that is in a parking search 'mission', no user action is needed, only may undo in a 'false alarm'.".localized()
            navigationController?.present(aboutViewController, animated: true, completion: nil)
        case LeftMenuOptions.Driving.SeekParking.symbol:
            aboutViewController.aboutTitle = "How iPark works?".localized()
            aboutViewController.title = "iPark"
            aboutViewController.aboutText = "Simply shares free parking spot locations, from anyone who left one while using this app, on the map screen.".localized()
            navigationController?.present(aboutViewController, animated: true, completion: { [weak self] in
                guard let strongSelf = self else { return }
                let isActivated = strongSelf.mapViewController.mapState == MapViewController.MapState.parkingSeeker

                let toggleActionTitle = isActivated ? "Deacivate".localized() : "Acivate".localized()
                let toggleAlertTitle = isActivated ? "iPark is Acivated".localized() : "iPark is Deacivated".localized()
                UIAlertController.makeAlert(title: toggleAlertTitle, message: "Acivate iPark? You can decide later...")
                    .withAction(UIAlertAction(title: "Cancel".localized(), style: UIAlertActionStyle.cancel, handler: nil))
                    .withAction(UIAlertAction(title: toggleActionTitle, style: UIAlertActionStyle.default, handler: { [weak self] _ in
                        guard let strongSelf = self else { return }
                        // The usr chose to toggle:
                        if isActivated {
                            // It's activated, so let's decativate
                            strongSelf.mapViewController.mapState = MapViewController.MapState.placesSeeker
                        } else {
                            strongSelf.mapViewController.mapState = MapViewController.MapState.parkingSeeker
                        }
                    }))
                .show()
            })
        case LeftMenuOptions.Location.WhereIsHere.symbol: // Just a thought, It feels like messing UI with logic, but it's a string eventually :)
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
                                self?.mapViewController.moveCameraToCurrentLocation()
                            }))
                            .show()
                    } else {
                        UIAlertController.makeAlert(title: "Error", message: "Failed to fetch address")
                            .withAction(UIAlertAction(title: "Fine", style: UIAlertActionStyle.cancel, handler: nil))
                            .show()
                    }
                })
            }
        case LeftMenuOptions.Location.ShareLocation.symbol:
            if let currentLocation = LocationHelper.shared.currentLocation?.coordinate {
                let alertController = UIAlertController.makeAlert(title: "Choose nickanme".localized(), message: "Choose the name you would like people to see:")
                    .withInputText(configurationBlock: { (textField) in
                        textField.placeholder = "nickname".localized()
                        textField.text = FirebaseHelper.currentNicknameOnFirebase ?? ""
                    })

                    alertController.withAction(UIAlertAction(title: "Cancel".localized(), style: UIAlertActionStyle.cancel, handler: nil))
                    .withAction(UIAlertAction(title: "Publish".localized(), style: UIAlertActionStyle.default, handler: { alertAction in
                        if let textField = alertController.textFields?.first, let nickname = textField.text {
                            FirebaseHelper.shareLocation(nickname, withLocation: currentLocation, completionCallback: { (error) in
                                if error != nil {
                                    ToastMessage.show(messageText: "Failed!")
                                }
                            })
                        }
                    }))
                .show()
            }
        case LeftMenuOptions.Location.WhereIsMapCenter.symbol:
            if let currentMapLocation = mapViewController.currentMapViewCenter {
                LocationHelper.fetchAddressByCoordinates(latitude: currentMapLocation.latitude, longitude: currentMapLocation.longitude, completion: { address in
                    if let address = address {
                        UIAlertController.makeActionSheet(title: "Map's current location:", message: "\(address)\n\(currentMapLocation.toString())")
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
