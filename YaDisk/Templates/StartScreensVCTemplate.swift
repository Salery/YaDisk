//
//  StartScreensVCTemplate.swift
//  YaDisk
//
//  Created by Devel on 10.07.2022.
//

import UIKit
import Shared

class StartScreensVCTemplate: UIViewController {
    var nextVC: UIViewController?
    let imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage())
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        binder ()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        binder ()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Const.Colors.viewsMainBgColor
    }
    
    func binder () {}
}
