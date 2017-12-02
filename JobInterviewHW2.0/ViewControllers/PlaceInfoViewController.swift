//
//  PlaceInfoViewController.swift
//  JobInterviewHW2.0
//
//  Created by Perry on 02/12/2017.
//  Copyright © 2017 perrchick. All rights reserved.
//

import Foundation

class PlaceInfoViewController: IHUViewController {
    weak var place: Place?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureUi()
    }
    
    func configureUi() {
        guard let place = place else { return }
        
    }
}
