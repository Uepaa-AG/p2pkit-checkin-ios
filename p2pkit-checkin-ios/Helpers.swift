//
//  Helpers.swift
//  p2pkit-checkin-ios
//
//  Copyright © 2017 Uepaa AG. All rights reserved.
//

import Foundation

class Helpers: NSObject {
    
    static func defaultColor() -> UIColor {
        return UIColor(red: 100.0/255.0, green: 100.0/255.0, blue: 100.0/255.0, alpha: 1.0)
    }
    
    static func nearbyColor() -> UIColor {
        return UIColor(red: 222.0/255.0, green: 78.0/255.0, blue: 205.0/255.0, alpha: 1.0)
    }
    
    static func historyColor() -> UIColor {
        return UIColor(red: 130.0/255.0, green: 246.0/255.0, blue: 159.0/255.0, alpha: 1.0)
    }
    
    static func showErrorDialog() {
        DispatchQueue.main.async {
            
            let alert = UIAlertController(title: "Error starting p2pkit", message: "The application encountered an error starting p2pkit. Please contact the app creator", preferredStyle: .alert);
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appDelegate.window?.rootViewController?.present(alert, animated: true, completion: nil)
            }
        }
    }
}
