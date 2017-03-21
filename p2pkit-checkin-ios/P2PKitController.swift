//
//  P2PKitController.swift
//  p2pkit-checkin-ios
//
//  Copyright © 2017 Uepaa AG. All rights reserved.
//

import Foundation

class P2PKitController: NSObject, PPKControllerDelegate {
    
    let operatorController: OperatorController
    
    required init(operatorController: OperatorController) {
        
        self.operatorController = operatorController
        super.init()
        
        PPKController.addObserver(self)
    }
    
    deinit {
        PPKController.removeObserver(self)
    }
    
    func publishGuest(_ guest: Guest) {
        
        if PPKController.isEnabled() {
            
            let discoveryInfo = P2PKitController.getDiscoveryInfoFromName(guest.name!)
            
            if PPKController.discoveryState() == .stopped {
                
                PPKController.enableProximityRanging()
                PPKController.startDiscovery(withDiscoveryInfo: discoveryInfo, stateRestoration: false)
            }
            else {
                PPKController.pushNewDiscoveryInfo(discoveryInfo)
            }
        }
    }
    
    // MARK: P2PKit Events
    
    func peerDiscovered(_ peer: PPKPeer) {
        DispatchQueue.main.async {
            let guest = self.createGuestFromPeer(peer)
            self.operatorController.guestArrived(guest)
        }
    }
    
    func peerLost(_ peer: PPKPeer) {
        DispatchQueue.main.async {
            let guest = self.createGuestFromPeer(peer)
            self.operatorController.guestLeft(guest)
        }
    }
    
    func proximityStrengthChanged(for peer: PPKPeer) {
        DispatchQueue.main.async {
            let guest = self.createGuestFromPeer(peer)
            self.operatorController.guestUpdated(guest)
        }
    }
    
    func discoveryInfoUpdated(for peer: PPKPeer) {
        DispatchQueue.main.async {
            let guest = self.createGuestFromPeer(peer)
            self.operatorController.guestUpdated(guest)
        }
    }
    
    // MARK: Helpers
    
    func createGuestFromPeer(_ peer: PPKPeer) -> Guest {
        let name = P2PKitController.getNameFromDiscoveryInfo(peer.discoveryInfo)
        return GuestManager.createGuest(peer.peerID, guestName: name, proximityStrength: peer.proximityStrength)
    }
    
    static func getNameFromDiscoveryInfo(_ info: Data?) -> String? {
        guard info != nil else {
            return nil
        }
        
        return String(data: info!, encoding: String.Encoding.utf8)
    }
    
    static func getDiscoveryInfoFromName(_ name: String) -> Data? {
        return name.data(using: String.Encoding.utf8)
    }
}
