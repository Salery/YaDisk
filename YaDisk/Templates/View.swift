//
//  View.swift
//  YaDisk
//
//  Created by Devel on 01.08.2022.
//

import UIKit

protocol ViewProtocol {
    associatedtype ViewModelType:          VMProtocol
    var viewModel:                         ViewModelType { get }
    var navTitle:                          String     { get }
    var navBarAppearanceConnectedColor:    UIColor { get }
    var navBarAppearanceDisconnectedColor: UIColor { get }
    func binder            ()
    func connectionChanged (status: Bool)
    func toNextVC          (vc: UIViewController, animated: Bool)
    func finishRefreshAnimation ()
}

extension ViewProtocol where Self: UIViewController {
    func binder () {
        viewModel.authorized.bind { [weak self] authorized in
            guard self != nil && authorized != true
            else { return }
            self!.toNextVC(vc: self!.viewModel.startVC.init(), animated: true)
        }
        
        viewModel.errorHandled.bind { [weak self] errorStruct in
            guard let errorStruct = errorStruct, self != nil
            else { return }
            self?.finishRefreshAnimation()
            self?.showError(errorStruct: errorStruct)
        }
        viewModel.connStatus.bind { [weak self] status in
            guard let status = status,
                  let self = self
            else { return }
            self.finishRefreshAnimation()
            self.connectionChanged(status: status)
        }
    }
    
    func connectionChanged (status: Bool) {
        let navgationView = UIView()
        let label = UILabel()
        label.text = navTitle
        label.sizeToFit()
        label.center = navgationView.center
        label.textAlignment = .center
        navgationView.addSubview(label)
        var color: UIColor
        if status {
            color = navBarAppearanceConnectedColor
        } else {
            let image = UIImageView()
            image.image = UIImage(systemName: "wifi.slash")
            let imageAspect = image.image!.size.width/image.image!.size.height
            image.frame = CGRect(
                x: label.frame.origin.x-label.frame.size.height*imageAspect,
                y: label.frame.origin.y,
                width: label.frame.size.height*imageAspect,
                height: label.frame.size.height)
            image.contentMode = .scaleAspectFit
            navgationView.addSubview(image)
            color = navBarAppearanceDisconnectedColor
        }
        navigationItem.titleView = navgationView
        navgationView.sizeToFit()
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = color
        appearance.titleTextAttributes = navigationController?.navigationBar.titleTextAttributes ?? [:]
        navigationController?.navigationBar.standardAppearance   = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        if #available(iOS 15, *) {} else {
            navigationController?.navigationBar.barTintColor = color
        }
    }
}
