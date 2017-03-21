//
//  GuestManager.swift
//  p2pkit-checkin-ios
//
//  Copyright © 2017 Uepaa AG. All rights reserved.
//

import Foundation

class GuestManager: NSObject {
    
    // Singleton instance
    static let sharedManager = GuestManager()
    
    
    // Contains all discovered peers (nearby + history)
    fileprivate var discoveredGuests = Set<Guest>()
    
    // Guests which are not checked in
    fileprivate var nearbyGuests = Set<Guest>()
    
    // Guests which are checked in
    fileprivate var historyGuests = Array<Guest>()
    
    
    static func createGuest(_ guestId: String!, guestName: String?, proximityStrength: PPKProximityStrength!) -> Guest {
        return Guest(id: guestId, name: guestName, proximityStrength: proximityStrength)
    }
    
    
    // MARK: Discovered Guests
    
    func addDiscoveredGuest(_ guest: Guest) {
        self.discoveredGuests.insert(guest)
    }
    
    func removeDiscoveredGuest(_ guest: Guest) {
        self.discoveredGuests.remove(guest)
    }
    
    
    func getDiscoveredGuest(_ id: String!) -> Guest? {
        for guest in self.discoveredGuests {
            if guest.guestId == id {
                return guest
            }
        }
        
        return nil
    }
    
    func isDiscoveredGuest(_ guest: Guest) -> Bool {
        return self.discoveredGuests.contains(guest)
    }
    
    // MARK: Nearby Guests
    
    func addNearbyGuest(_ guest: Guest) {
        self.nearbyGuests.insert(guest)
    }
    
    func removeNearbyGuest(_ guest: Guest) {
        self.nearbyGuests.remove(guest)
    }
    
    func getNearbyGuest(_ id: String!) -> Guest? {
        for guest in self.nearbyGuests {
            if guest.guestId == id {
                return guest
            }
        }
        
        return nil
    }
    
    func getNearbyGuests() -> Set<Guest> {
        return self.nearbyGuests
    }
    
    func isNearbyGuest(_ guest: Guest) -> Bool {
        return self.nearbyGuests.contains(guest)
    }
    
    // MARK: History
    
    func addGuestToHistory(_ guest: Guest) {
        if !self.historyGuests.contains(guest) {
            self.historyGuests.append(guest)
        }
    }
    
    func removeGuestFromHistory(_ guest: Guest) {
        if let index = self.historyGuests.index(of: guest) {
            self.historyGuests.remove(at: index)
        }
    }
    
    func getGuestsInHistory() -> Array<Guest> {
        return self.historyGuests.reversed()
    }
    
    func isGuestInHistory(_ guest: Guest) -> Bool {
        return self.historyGuests.contains(guest)
    }
}
