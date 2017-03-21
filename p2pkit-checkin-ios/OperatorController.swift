//
//  OperatorController.swift
//  p2pkit-checkin-ios
//
//  Copyright © 2017 Uepaa AG. All rights reserved.
//

import Foundation


class OperatorController: NSObject {
    
    // Singleton instance
    static let sharedController = OperatorController()
    
    // Manager for holding guest objects
    fileprivate let guestManager = GuestManager.sharedManager
    
    weak var nearbyGuestsController: NearbyPeersViewController?
    weak var transactionController: CheckinTransactionViewController?
    weak var historyController: HistoryViewController?
    
    
    // MARK: - Guest Discovery
    
    func guestArrived(_ guest: Guest) {
        
        print("Guest \(guest.guestId) arrived")
        
        guestManager.addDiscoveredGuest(guest)
        self.handleGuest(guest)
    }
    
    func guestLeft(_ guest: Guest) {
        
        print("Guest \(guest.guestId) left")
        
        if let discoveredGuest = guestManager.getDiscoveredGuest(guest.guestId) {
        
            guestManager.removeDiscoveredGuest(discoveredGuest)
            guestManager.removeNearbyGuest(discoveredGuest)
            
            self.cancelCheckIn(discoveredGuest)
            self.cancelCheckOut(discoveredGuest)
            
            self.sendGuestLeftNotification(discoveredGuest)
        }
    }
    
    func guestUpdated(_ guest: Guest) {
        
        if let discoveredGuest = guestManager.getDiscoveredGuest(guest.guestId) {
            
            let previousProximityStrength = discoveredGuest.proximityStrength
            
            discoveredGuest.name = guest.name
            discoveredGuest.proximityStrength = guest.proximityStrength
            
            if discoveredGuest.proximityStrength != previousProximityStrength {
                self.handleGuest(discoveredGuest)
            }
            
            self.sendGuestUpdatedNotification(discoveredGuest)
        }
    }
    
    func removeGuestFromHistory(_ guest: Guest) {
        
        if let discoveredGuest = self.guestManager.getDiscoveredGuest(guest.guestId) {
            self.succeedCheckOutGuest(discoveredGuest)
        }
        else {
            self.guestManager.removeGuestFromHistory(guest)
            self.sendGuestRemovedFromHistoryNotification(guest)
        }
    }
    
    
    // MARK: - Guest Handling
    
    fileprivate func handleGuest(_ guest: Guest) {
        
        if guestManager.isGuestInHistory(guest) {
            // Existing guest in history
            handleGuestInHistory(guest)
        }
        else if guestManager.isNearbyGuest(guest) {
            // Existing guest nearby
            handleNearbyGuest(guest)
        }
        else {
            // New guest nearby
            guestManager.addNearbyGuest(guest)
            handleNearbyGuest(guest)
            self.sendGuestArrivedNotification(guest)
        }
    }
    
    fileprivate func handleNearbyGuest(_ guest: Guest) {
        
        if guest.isInCheckinRange() {
            self.checkInGuest(guest)
        }
        else {
            self.cancelCheckIn(guest)
        }
    }
    
    fileprivate func handleGuestInHistory(_ guest: Guest) {
        
        if guest.isInCheckinRange() {
            self.checkOutGuest(guest)
        }
        else {
            self.cancelCheckOut(guest)
        }
    }
    
    
    // MARK: - Notifications to views
    
    fileprivate func sendGuestArrivedNotification(_ guest: Guest) {
        nearbyGuestsController?.addNodeForGuest(guest)
    }
    
    fileprivate func sendGuestUpdatedNotification(_ guest: Guest) {
        nearbyGuestsController?.updateNodeForGuest(guest)
    }
    
    fileprivate func sendGuestLeftNotification(_ guest: Guest) {
        nearbyGuestsController?.removeNodeForGuest(guest)
    }
    
    fileprivate func sendGuestCheckedInNotification(_ guest: Guest) {
        nearbyGuestsController?.removeNodeForGuest(guest)
        historyController?.reloadData()
    }
    
    fileprivate func sendGuestCheckedOutNotification(_ guest: Guest) {
        historyController?.reloadData()
        nearbyGuestsController?.addNodeForGuest(guest)
    }
    
    fileprivate func sendGuestRemovedFromHistoryNotification(_ guest: Guest) {
        historyController?.reloadData()
    }
    
    
    // MARK: - Check-in
    
    fileprivate func checkInGuest(_ guest: Guest) {
        
        let setupSuccessful = self.transactionController?.setupTransaction(CheckinTransactionType.checkin, success: { [weak self] (guests: Set<Guest>) in
            
            if let actualSelf = self {
                
                for guest: Guest in guests {
                    
                    if guest.proximityStrength == .immediate {
                        actualSelf.succeedCheckInGuest(guest)
                        print("Checkin successful for guest \(guest.guestId)")
                    }
                    else {
                        print("Guest \(guest.guestId) not in immediate range anymore for checkin")
                    }
                }
            }
            
        }, failed: { (guests: Set<Guest>) in
                
            for guest: Guest in guests {
                print("Checkin failed for guest \(guest.guestId)")
            }
        })
        
        if setupSuccessful != nil && setupSuccessful! {
            self.transactionController?.addGuestsToTransaction([guest], transactionType: CheckinTransactionType.checkin)
        }
    }
    
    fileprivate func succeedCheckInGuest(_ guest: Guest) {
        
        if !guestManager.isDiscoveredGuest(guest) {
            return
        }
        
        guest.wasOutOfRange = false
        
        self.guestManager.addGuestToHistory(guest)
        self.guestManager.removeNearbyGuest(guest)
        self.sendGuestCheckedInNotification(guest)
    }
    
    fileprivate func failCheckInGuest(_ guest: Guest) {
        // TODO: what should we do here?
    }
    
    fileprivate func cancelCheckIn(_ guest: Guest) {
        self.transactionController?.removeGuestsFromTransaction([guest], transactionType: CheckinTransactionType.checkin)
    }
    
    
    // MARK: - Check-out
    
    fileprivate func checkOutGuest(_ guest: Guest) {

        let setupSuccessful = self.transactionController?.setupTransaction(CheckinTransactionType.checkout, success: { [weak self] (guests: Set<Guest>) in
            
            if let actualSelf = self {
            
                for guest: Guest in guests {
                    
                    if guest.proximityStrength == .immediate {
                        actualSelf.succeedCheckOutGuest(guest)
                        print("Checkout successful for guest \(guest.guestId)")
                    }
                    else {
                        print("Guest \(guest.guestId) not in immediate range anymore for checkout")
                    }
                }
            }
            
        }, failed: { (guests: Set<Guest>) in
            
            for guest: Guest in guests {
                print("Checkout failed for guest \(guest.guestId)")
            }
        })
        
        if setupSuccessful != nil && setupSuccessful! {
            self.transactionController?.addGuestsToTransaction([guest], transactionType: .checkout)
        }
    }
    
    fileprivate func succeedCheckOutGuest(_ guest: Guest) {
        
        if !guestManager.isDiscoveredGuest(guest) {
            return
        }
        
        guest.wasOutOfRange = false
        
        self.guestManager.addNearbyGuest(guest)
        self.guestManager.removeGuestFromHistory(guest)
        self.sendGuestCheckedOutNotification(guest)
    }
    
    fileprivate func failCheckOutGuest(_ guest: Guest) {
        // TODO: what should we do here?
    }
    
    fileprivate func cancelCheckOut(_ guest: Guest) {
        self.transactionController?.removeGuestsFromTransaction([guest], transactionType: .checkout)
    }
}
