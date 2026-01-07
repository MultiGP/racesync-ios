//
//  AppUtil.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2020-12-19.
//  Copyright © 2020 MultiGP Inc. All rights reserved.
//

import UIKit

struct AppUtil {

    static func lock(_ orientation: UIInterfaceOrientationMask) {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.orientationLock = orientation
        }
    }

    /// OPTIONAL Added method to adjust lock and rotate to the desired orientation
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation: UIInterfaceOrientation) {

        UIView.performWithoutAnimation {
            self.lock(orientation)
            UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
            UINavigationController.attemptRotationToDeviceOrientation()
        }
    }
}
