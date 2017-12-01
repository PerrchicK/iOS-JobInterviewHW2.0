//
//  AboutViewController.swift
//  JobInterviewHW2.0
//
//  Created by Perry on 01/12/2017.
//  Copyright © 2017 perrchick. All rights reserved.
//

import UIKit

class AboutViewController: IHUViewController, UITextViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: Foundation.URL, in characterRange: NSRange) -> Bool {
        📗("interacting with URL: \(URL)")
        return URL.absoluteString == Configurations.shared.projectLocationInsideGitHub
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return false
    }
}
