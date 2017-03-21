//
//  AppDelegate.swift
//  p2pkit-checkin-ios
//
//  Copyright © 2017 Uepaa AG. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, PPKControllerDelegate {
    
    var window: UIWindow?
    var p2pkitController: P2PKitController?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        PPKController.enable(withConfiguration: "<YOUR APPLICATION KEY>", observer: self)
        return true
    }
    
    func ppkControllerInitialized() {
        self.p2pkitController = P2PKitController(operatorController: OperatorController.sharedController)
    }
    
    func ppkControllerFailedWithError(_ errorCode: PPKErrorCode) {
        Helpers.showErrorDialog()
    }
}

