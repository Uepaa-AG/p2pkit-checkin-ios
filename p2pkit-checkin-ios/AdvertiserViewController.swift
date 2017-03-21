//
//  AdvertiserViewController.swift
//  p2pkit-checkin-ios
//
//  Copyright © 2017 Uepaa AG. All rights reserved.
//

import UIKit

class AdvertiserViewController: UIViewController, PPKControllerDelegate, UITextFieldDelegate {

    @IBOutlet weak var userInputField: UITextField!
    @IBOutlet weak var publishButton: UIButton!
    @IBOutlet weak var switchViewBarButton: UIBarButtonItem!
    
    let maxLength:Int = 10
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.switchViewBarButton.isEnabled = false;
        self.publishButton.isEnabled = false;
        self.userInputField.isEnabled = false
        self.userInputField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
    }
 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if PPKController.isEnabled() {
            PPKController.addObserver(self);
            self.userInputField.isEnabled = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if PPKController.isEnabled() {
            PPKController.removeObserver(self);
        }
    }
    
    @IBAction func publishButtonTapped(_ sender: UIButton) {
        
        self.view.endEditing(true)
        
        let guestId = PPKController.myPeerID()
        let guestName = self.userInputField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let guest = Guest(id: guestId, name: guestName, proximityStrength: PPKProximityStrength.unknown)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.p2pkitController?.publishGuest(guest)
    }
    
    // MARK: - UITextField delegate
    
    func textFieldDidChange(_ textField: UITextField) {
        guard let text = textField.text else { return }
        
        if 1 ... maxLength ~= Int(text.characters.count) {
            self.publishButton.isEnabled = true
        } else {
            self.publishButton.isEnabled = false
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        
        if text.characters.count < maxLength || string == "" {
            return true
        } else {
            return false
        }
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        guard let text = textField.text else { return true }
        
        return 1 ... maxLength ~= Int(text.characters.count) ? true : false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        DispatchQueue.main.async { 
            self.publishButtonTapped(self.publishButton)
        };
        
        return true
    }
    
    // MARK: - p2pkit delegate
    
    func discoveryStateChanged(_ state: PPKDiscoveryState) {
        
        DispatchQueue.main.async {
            
            switch state {
            case .suspended, .running, .serverConnectionUnavailable:
                self.switchViewBarButton.isEnabled = true;
            
            default:
                self.switchViewBarButton.isEnabled = false;
                Helpers.showErrorDialog()
            }
        }
    }
    
}
