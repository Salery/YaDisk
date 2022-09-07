//
//  OnboardingModel.swift
//  YaDisk
//
//  Created by Devel on 10.07.2022.
//

import Shared
import UIKit

final class OnboardingModel {
    private weak var viewModel: OnboardingVMProtocol?
    private let images = [
        Const.Images.onboarding1,
        Const.Images.onboarding2,
        Const.Images.onboarding3
    ]
    private let texts = [
        Const.Texts.onboarding1,
        Const.Texts.onboarding2,
        Const.Texts.onboarding3
    ]
    let nextVC = StartVC.self
    
    init(viewModel: OnboardingVMProtocol) {
        self.viewModel = viewModel
    }
    
    func getImage (index: Int) {
        viewModel?.image.value = images[index]
    }
    
    func getText (index: Int) {
        viewModel?.text.value = texts[index]
    }
}
