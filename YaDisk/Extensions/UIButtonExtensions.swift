//
//  UIButtonExtensions.swift
//  YaDisk
//
//  Created by Devel on 10.07.2022.
//

import UIKit
enum CustomButtonTypes {
    case nextButton
}

extension UIButton {
    convenience init(customType: CustomButtonTypes,
                     title: String? = nil,
                     bottomRelativeToView: UIView? = nil,
                     actionSelector: Selector? = nil) {
        switch customType {
        case .nextButton:
            self.init(type: .roundedRect)
            layer.cornerRadius = 10
            setTitleColor(.white, for: .normal)
            backgroundColor = .systemBlue
            frame.size = CGSize(width: 320, height: 50)
            if let view = bottomRelativeToView {
                frame.origin = CGPoint(x: (view.frame.width - frame.width)/2, y: view.frame.height - 142)
            }
            if let title = title {
                setTitle(title, for: .normal)
            } else {
                setTitle(NSLocalizedString("Next", comment: "Button.Next"), for: .normal)
            }
            if let actionSelector = actionSelector {
                addTarget(nil, action: actionSelector, for: .touchUpInside)
            }
        }
    }
}
