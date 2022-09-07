//
//  ViewController.swift
//  YaDisk
//
//  Created by Devel on 07.07.2022.
//

import UIKit
import Shared

final class StartVC: StartScreensVCTemplate {
    private let viewModel: StartVMProtocol = StartVM()
    private lazy var button = UIButton( customType: .nextButton,
                                   title: NSLocalizedString("Login", comment: "Login"),
                                   bottomRelativeToView: view,
                                   actionSelector: #selector(buttonClick) )
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.center = button.center
        return activityIndicator
    }()
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        setupViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bindError()
    }
    
    override func binder () {
        viewModel.authorized.bind { [weak self] value in
            guard let value = value,
                  let self = self
            else { return }
            if value {
                self.nextVC = self.viewModel.toNextVC()
                self.toNextVC(vc: self.nextVC!, animated: true)
            } else {
                self.nextVC = self.viewModel.toAuthorizeVC()
                self.showButton()
            }
        }
        viewModel.connStatus.bind { [weak self] value in
            guard let value = value,
                  let self = self
            else { return }
            if value && self.nextVC != nil
                && self.viewModel.authorized.value == true {
                self.toNextVC(vc: self.nextVC!, animated: true)
            } else {
                self.showButton()
            }
        }
    }
    
    // viewDidAppear needed, because an error may appear
    // before opening the window with the StartVC
    private func bindError () {
        viewModel.errorHandled.bindAndFire { [weak self] errorStruct in
            guard let self = self,
                  let errorStruct = errorStruct
            else { return }
            self.showError(errorStruct: errorStruct)
            self.viewModel.clearError()
        }
    }
    
    private func setupViews () {
        if !view.subviews.contains(button) {
            view.addSubview(activityIndicator)
            activityIndicator.startAnimating()
        }
        imageView.image = Const.Images.drive
        view.addSubview(imageView)
        imageView.frame.size = CGSize(width: 200, height: 200)
        imageView.center = view.center
    }
    
    private func showButton () {
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
        view.addSubview(button)
        let options: UIView.AnimationOptions = .transitionCrossDissolve
        let duration: TimeInterval = 1.0
        UIView.transition(with: view, duration: duration, options: options, animations: {}, completion: nil)
    }
    
    private func presentNextVC (animated: Bool) {
        guard let vc = nextVC else { return }
        present(vc, animated: animated, completion: nil)
    }
    
    @objc private func buttonClick () {
        if viewModel.connStatus.value == false { viewModel.refreshAuth() }
        else { presentNextVC (animated: true) }
    }
    
    func hideButton() {
        button.removeFromSuperview()
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
    }
}
