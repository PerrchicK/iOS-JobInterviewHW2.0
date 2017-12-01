//
//  DrawerContainerViewController.swift
//  JobInterviewHW2.0
//
//  Created by Perry on 30/11/2017.
//  Copyright © 2017 perrchick. All rights reserved.
//

import UIKit
import MMDrawerController

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
        shouldStretchDrawer = false
        title = "i Here U"
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
    
    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            if isMenuOpen {
                closeDrawer(animated: true, completion: nil)
            } else {
                open()
            }
        }
    }
}

extension DrawerContainerViewController: LeftMenuViewControllerDelegate {
    func leftMenuViewController(_ leftMenuViewController: LeftMenuViewController, selectedOption: String) {
                switch selectedOption {
                case LeftMenuOptions.About.AboutApp:
                    navigationController?.pushViewController(AboutViewController.instantiate(), animated: true)
//                case LeftMenuOptions.Concurrency.GCD:
//                    navigationController?.pushViewController(ConcurrencyViewController.instantiate(), animated: true)
//                case LeftMenuOptions.UI.Views_Animations:
//                    navigationController?.pushViewController(AnimationsViewController.instantiate(), animated: true)
//                case LeftMenuOptions.UI.CollectionView:
//                    let gameNavigationController = GameNavigationController(rootViewController: CollectionViewController.instantiate())
//                    gameNavigationController.isNavigationBarHidden = true
//                    navigationController?.present(gameNavigationController, animated: true, completion: nil)
//                case LeftMenuOptions.iOS.Data:
//                    navigationController?.pushViewController(DataViewController.instantiate(), animated: true)
//                case LeftMenuOptions.iOS.CommunicationLocation:
//                    navigationController?.pushViewController(CommunicationMapLocationViewController.instantiate(), animated: true)
//                case LeftMenuOptions.iOS.Notifications:
//                    navigationController?.pushViewController(NotificationsViewController.instantiate(), animated: true)
//                case LeftMenuOptions.iOS.ImagesCoreMotion:
//                    navigationController?.present(ImagesAndMotionViewController.instantiate(), animated: true, completion: nil)
                default:
                    UIAlertController.alert(title: "Under contruction 🔨", message: "to be continued... 😉")
                    📗("to be continued...")
                }
    }
}
