//
//  File.swift
//  
//
//  Created by Daniel Watson on 22.02.2024.
//

import Foundation
import UIKit

public final class Utilities {
    // error on key window here is ok - Nick Sarno
    public static let shared = Utilities()
    private init() {}
    
    @MainActor
    public func topViewController(controller: UIViewController? = nil) -> UIViewController? {
        let controller = controller ?? UIApplication.shared.keyWindow?.rootViewController
        
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}
