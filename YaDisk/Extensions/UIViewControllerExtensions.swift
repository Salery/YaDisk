//
//  UIViewControllerExtensions.swift
//  YaDisk
//
//  Created by Devel on 09.07.2022.
//

import UIKit
import Shared

extension UIViewController {
    func showError (errorStruct: ErrorStruct) {
        let alertController = UIAlertController(title: errorStruct.title, message: errorStruct.message, preferredStyle: .alert)
        if errorStruct.decisionNeeded {
            alertController.addAction(
                UIAlertAction(title: NSLocalizedString("Yes", comment: "Action.yes"), style: .destructive, handler: errorStruct.actionHandler)
            )
            alertController.addAction(
                UIAlertAction(title: NSLocalizedString("Cancel", comment: "Action.cancel"), style: .cancel)
            )
        } else {
            alertController.addAction(
                UIAlertAction(title: "Ok", style: .destructive, handler: errorStruct.actionHandler)
            )
        }
        self.present(alertController, animated: true, completion: errorStruct.completion)
    }
    
    func animatedWindowTransition (view: UIView) {
        let options: UIView.AnimationOptions = .transitionFlipFromLeft
        let duration: TimeInterval = 1.0
        // Though `animations` is optional, the documentation tells us that it must not be nil.
        UIView.transition (with: view, duration: duration, options: options, animations: {}, completion: nil)
    }
    
    func toNextVC (vc: UIViewController, animated: Bool) {
        guard let window = view.window
        else { return }
        window.rootViewController = vc
        if animated { animatedWindowTransition(view: window) }
    }
}
