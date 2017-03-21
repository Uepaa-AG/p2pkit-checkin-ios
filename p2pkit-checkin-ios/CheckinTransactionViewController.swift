//
//  CheckinTransactionViewController.swift
//  p2pkit-checkin-ios
//
//  Copyright © 2017 Uepaa AG. All rights reserved.
//

import UIKit

enum CheckinTransactionError: Error {
    case transactionIsNotSetup
    case transactionAlreadyInProgress
    case otherTransactionTypeAlreadyInProgress
}

enum CheckinTransactionType {
    case checkin, checkout
}

typealias SuccessBlock = (_ guests: Set<Guest>) -> Void
typealias FailedBlock = (_ guests: Set<Guest>) -> Void


class CheckinTransactionViewController: UIViewController {
    
    //----------------------------------
    //MARK: - Public Properties
    //----------------------------------
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var topLabel: UILabel!
    
    @IBOutlet weak var approveButton: UIButton!
    @IBOutlet weak var rejectButton: UIButton!
    @IBOutlet weak var loadingBar: UIProgressView!
    
    //----------------------------------
    //MARK: - Private Properties
    //----------------------------------
    
    fileprivate var guests = Set<Guest>()
    fileprivate var transactionType: CheckinTransactionType?
    fileprivate var isShown : Bool = true;
    
    fileprivate var successBlock: SuccessBlock?
    fileprivate var failedBlock: FailedBlock?
    
    fileprivate static let transactionTime : Double = 5
    fileprivate let timerValue : TimeInterval = 1.0 / 30.0
    fileprivate var checkinTimer: Timer?
    fileprivate var progress: Float = 1.0
    fileprivate let tick : Float = 1.0 / (Float(transactionTime)*30.0)
    
    //----------------------------------
    //MARK: - Public interface
    //----------------------------------
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        OperatorController.sharedController.transactionController = self
    }
    
    func setupTransaction(_ transactionType: CheckinTransactionType, success: SuccessBlock?, failed: FailedBlock?) -> Bool {
        
        if self.transactionType != nil {
            
            if self.transactionType != transactionType {
                return false
            }
            
            return true
        }
        
        self.transactionType = transactionType
        
        switch transactionType {
        case .checkin:
            self.headerLabel.text = "Check-In"
        case .checkout :
            self.headerLabel.text = "Check-Out"
        }
        
        self.successBlock = success
        self.failedBlock = failed

        return true
    }
    
    func addGuestsToTransaction(_ guests: Set<Guest>, transactionType: CheckinTransactionType) {
        
        if self.transactionType == nil || guests.isEmpty {
            return
        }
        
        if self.transactionType != transactionType {
            return
        }
        
        self.guests.formUnion(guests)
        
        if self.guests.count > 0 {
            self.showOnce()
            self.updatetextTopLabel()
            self.startTimer()
        }
    }
    
    func removeGuestsFromTransaction(_ guests: Set<Guest>, transactionType: CheckinTransactionType) {
        
        if self.transactionType == nil {
            return
        }
        
        if self.transactionType != transactionType {
            return
        }
        
        var needsAction = false
        for guest in guests {
            if (self.guests.remove(guest) != nil) {
                needsAction = true
            }
        }
        
        if needsAction {
            
            if self.guests.count == 0 {
                self.finishTransaction(nil)
            }else{
                self.startTimer()
                self.updatetextTopLabel()
            }
        }
    }
    
    //----------------------------------
    //MARK: - UI items interface
    //----------------------------------
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.headerLabel.backgroundColor = Helpers.historyColor()
        self.hideOnce()
    }
    
    @IBAction func approveButtonTap(_ sender: UIButton) {
        self.transactionApproved()
    }
    
    @IBAction func rejectButtonTap(_ sender: UIButton) {
        self.transactionCanceled()
    }
    
    fileprivate func updatetextTopLabel() {
        
        var labelString: String = ""
        
        for (index, element)  in self.guests.enumerated() {
            
            if let name = element.name {
                if index > 0 {labelString.append(", ")}
                labelString.append(name)
            }
        }
        
        self.topLabel.text = labelString
    }

    //----------------------------------
    //MARK: - Private interface
    //----------------------------------

    fileprivate func startTimer() {
        
        self.checkinTimer?.invalidate()
        self.progress = 1.0
        self.loadingBar.progress = self.progress
        
        self.checkinTimer = Timer.scheduledTimer(timeInterval: timerValue, target: self, selector: #selector(timerTick), userInfo: nil, repeats: true)
    }
    
    @objc fileprivate func timerTick() {
        
        if self.progress <= 0.05 {
            self.timerExpired()
            return //<- Exit
        }
        
        DispatchQueue.main.async {
            self.loadingBar.progress = self.progress;
        }
        
        self.progress -= self.tick
    }
    
   fileprivate func timerExpired() {
        self.checkinTimer?.invalidate()
        DispatchQueue.main.async { self.transactionApproved() }
    }
    
    fileprivate func transactionApproved() {
        
        self.finishTransaction { Void in
            self.successBlock?(self.guests)
        }
    }
    
    fileprivate func transactionCanceled() {
        
        self.finishTransaction { Void in
            self.failedBlock?(self.guests)
        }
    }
    
    func finishTransaction(_ block: ((Void) -> Void)?) {
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions(), animations: {
            self.view.frame.origin.y = (self.view.superview?.frame.size.height)!
            }, completion: { (value:Bool) in
                block?()
                self.teardown()
        })
    }
    
    fileprivate func showOnce() {
        
        guard !self.isShown else {
            return
        }
        
        self.isShown = true
        self.view.superview?.isHidden = false
        self.view.superview?.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions(), animations: {
            self.view.frame.origin.y = 0
            }, completion: { (value:Bool) in
        })
    }
    
    fileprivate func hideOnce() {
        
        guard self.isShown else {
            return
        }
        
        self.isShown = false
        self.view.frame.origin.y = (self.view.superview?.frame.size.height)!
        self.view.superview?.isHidden = true
        self.view.superview?.isUserInteractionEnabled = false
    }
    
    fileprivate func teardown() {
        self.hideOnce()
        self.guests.removeAll()
        self.transactionType = nil
        self.topLabel.text = ""
    }
}
