//
//  AppDelegate.swift
//  NordicSemiConnect
//
//  Created by Ivan Brazhnikov on 08/06/16.
//  Copyright © 2016 Ivan Brazhnikov. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?


  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    BluetoothAdapter.initializeWithRestoreIdentifier(kBluetoothAdapterSharedRestoreIdentifier)
    return true
  }


}

