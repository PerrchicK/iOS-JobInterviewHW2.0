//
//  SplashScreenViewController.swift
//  JobInterviewHW2.0
//
//  Created by Perry on 30/11/2017.
//  Copyright © 2017 perrchick. All rights reserved.
//

import UIKit

class SplashScreenViewController: UIViewController {

    @IBOutlet weak var appTitleLabel: UILabel!
    @IBOutlet weak var appLogoImageView: UIImageView!
    @IBOutlet weak var floorView: UIView!

    /**
     References:
     - https://github.com/PerrchicK/swift-app/blob/2c55e6ef4d3083d2dbfff96b8461161f057d1eb9/SomeApp/SomeApp/Classes/ViewControllers/AnimationsViewController.swift#L30
     - https://www.raywenderlich.com/50197/uikit-dynamics-tutorial
     */
    var wallGravityAnimator: UIDynamicAnimator!
    var wallGravityBehavior: UIGravityBehavior!
    var wallCollision: UICollisionBehavior!
    var timer: ClosureTimer?

    lazy var drawer: DrawerContainerViewController = DrawerContainerViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        appTitleLabel.onClick({ [weak self] _ in
            self?.appTitleLabel.animateNo(duration: 0.2)
        })

        appLogoImageView.onClick({ [weak self] _ in
            self?.appLogoImageView.animateFade(fadeIn: false, duration: 0.5, completion: { _ in
                self?.presentMainView()
            })
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        PerrFuncs.runBlockAfterDelay(afterDelay: 1) { [weak self] in
            self?.appTitleLabel.animateBounce({ [weak self] _ in
                guard let strongSelf = self else { return }

                strongSelf.wallGravityAnimator = UIDynamicAnimator(referenceView: strongSelf.appLogoImageView.superview!) // Must be the top reference view
                strongSelf.wallGravityBehavior = UIGravityBehavior(items: [strongSelf.appLogoImageView])
                strongSelf.wallGravityAnimator.addBehavior(strongSelf.wallGravityBehavior)
                strongSelf.wallCollision = UICollisionBehavior(items: [strongSelf.appLogoImageView, strongSelf.floorView])
                strongSelf.wallCollision.translatesReferenceBoundsIntoBoundary = true
                strongSelf.wallGravityAnimator.addBehavior(strongSelf.wallCollision)
            })
        }
        
        timer = ClosureTimer.runBlockAfterDelay(afterDelay: 2, repeats: true, userInfo: nil, onQueue: DispatchQueue.main) { [weak self] _ in
            self?.appLogoImageView.animateBounce()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        timer?.invalidate()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.all
    }

    func presentMainView() {
        let navigationController = UINavigationController(rootViewController: DrawerContainerViewController())
        navigationController.modalTransitionStyle = .crossDissolve
        present(navigationController, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        📕("Beware!! What are you doing there dude??")
        // Dispose of any resources that can be recreated.
    }
}

