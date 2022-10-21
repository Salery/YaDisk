//
//  OnBoardingVC.swift
//  YaDisk
//
//  Created by Devel on 10.07.2022.
//

import UIKit
import Shared

final class OnboardingVC: StartScreensVCTemplate {
    private let viewModel = OnboardingVM()
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .close)
        button.frame.size   = CGSize(width: 32, height: 32)
        button.frame.origin = CGPoint(x: view.frame.width - 64, y: 68)
        button.addTarget(self, action: #selector(closeClick), for: .touchUpInside)
        return button
    }()
    private lazy var label: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = Const.Fonts.onboardingFont
        label.frame.size = CGSize(width: 250, height: 48)
        return label
    }()
    private lazy var pgControl: UIPageControl = {
        let pgControl = UIPageControl()
        pgControl.currentPageIndicatorTintColor = .systemBlue
        pgControl.pageIndicatorTintColor = .systemGray
        pgControl.currentPage = 0
        pgControl.numberOfPages = 3
        pgControl.frame.size   = pgControl.size(forNumberOfPages: 3)
        pgControl.frame.origin = CGPoint(x: (view.frame.width - pgControl.frame.width)/2,
                                         y: view.frame.height - 192)
        pgControl.addTarget(self, action: #selector(pgControlChanged), for: .valueChanged)
        return pgControl
    }()
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        setupViews()
    }
    
    private func setupViews () {
        view.addSubview(closeButton)
        viewModel.getImage()
        view.addSubview(imageView)
        imageView.frame.size   = CGSize(width: 150, height: 150)
        imageView.frame.origin = CGPoint(x: (view.frame.width - imageView.frame.width)/2,
                                         y: view.frame.height/2 - imageView.frame.height)
        viewModel.getText()
        view.addSubview(pgControl)
        view.addSubview(label)
        label.frame.origin = CGPoint(x: (view.frame.width - label.frame.width)/2,
                                     y: view.frame.height/2 + (view.frame.height > 600 ? 64 : 32) )
        view.addSubview( UIButton( customType: .nextButton,
                                   bottomRelativeToView: view,
                                   actionSelector: #selector(buttonClick) ) )
    }
    
    override func binder () {
        viewModel.image.bind { [weak self] value in
            guard let value = value,
                  let self = self
            else { return }
            self.imageView.image = value
            self.animatedWindowTransition(view: self.view)
        }
        viewModel.text.bind { [weak self] value in
            guard let value = value,
                  let self = self
            else { return }
            self.label.text = value
        }
        viewModel.nextVC.bind { [weak self] value in
            guard let value = value,
                  let self = self
            else { return }
            self.nextVC = value
            self.toNextVC(vc: self.nextVC!, animated: true)
        }
    }
    
    @objc private func closeClick () {
        viewModel.getNextVC()
//        toNextVC(vc: self.nextVC!, animated: true)
    }
    
    @objc private func pgControlChanged () {
        viewModel.changeScreen(toIndex: pgControl.currentPage)
    }
    
    @objc private func buttonClick () {
        viewModel.changeScreen()
        if viewModel.indexForScreen < 3 {
            pgControl.currentPage = viewModel.indexForScreen
        }
    }
}
