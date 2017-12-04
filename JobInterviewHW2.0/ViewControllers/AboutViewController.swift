//
//  AboutViewController.swift
//  JobInterviewHW2.0
//
//  Created by Perry on 01/12/2017.
//  Copyright © 2017 perrchick. All rights reserved.
//

import UIKit

class AboutViewController: IHUViewController, UITextViewDelegate {

    var aboutText: String?
    var aboutTitle: String?

    @IBOutlet weak var informationTextView: UITextView!
    @IBOutlet weak var titleLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        titleLabel.text = aboutTitle
        informationTextView.text = aboutText
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: Foundation.URL, in characterRange: NSRange) -> Bool {
        📗("interacting with URL: \(URL)")
        return URL.absoluteString == Configurations.Constants.GitHubLink
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return false
    }
}
