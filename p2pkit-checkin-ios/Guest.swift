//
//  Guest.swift
//  p2pkit-checkin-ios
//
//  Copyright © 2017 Uepaa AG. All rights reserved.
//

import Foundation

class Guest: NSObject {
    
    let guestId: String!
    var name: String?
    var wasOutOfRange = true
    var proximityStrength = PPKProximityStrength.unknown {
        didSet {
            if self.proximityStrength.rawValue <= 3 { // medium
                self.wasOutOfRange = true
            }
        }
    }
    
    init(id: String!, name: String?, proximityStrength: PPKProximityStrength) {
        self.guestId = id!
        self.name = name
        self.proximityStrength = proximityStrength
    }
    
    func isInCheckinRange() -> Bool {
        
        if self.wasOutOfRange {
            return self.proximityStrength.rawValue == PPKProximityStrength.immediate.rawValue
        }
        
        return false
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        
        if let obj = object {
            
            if (obj as AnyObject).isKind(of: Guest.self) && (obj as AnyObject).guestId == self.guestId {
                
                return true
            }
        }
        
        return false
    }
}
