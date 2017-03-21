//
//  MainViewController.swift
//  p2pkit-checkin-ios
//
//  Copyright © 2017 Uepaa AG. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.backButton.addTarget(self, action: #selector(presentSetupViewController), for: UIControlEvents.touchUpInside)
    }
    
    func presentSetupViewController() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
