//
//  OnboardingVM.swift
//  YaDisk
//
//  Created by Devel on 10.07.2022.
//

import Shared
import UIKit

protocol OnboardingVMProtocol: AnyObject {
    var image:  Box<UIImage?>           { get }
    var text:   Box<String?>            { get }
    var nextVC: Box<UIViewController?>  { get }
    var model:  OnboardingModel?        { get }
    var indexForScreen: Int             { get }
    func getImage     ()
    func getText      ()
    func changeScreen (toIndex: Int?)
    func getNextVC ()
}

final class OnboardingVM: OnboardingVMProtocol {
    let image:  Box<UIImage?>           = Box(value: nil)
    let text:   Box<String?>            = Box(value: nil)
    let nextVC: Box<UIViewController?>  = Box(value: nil)
    var indexForScreen = 0
    
    func getImage() {
        model?.getImage(index: indexForScreen)
    }
    
    func getText() {
        model?.getText(index: indexForScreen)
    }
    
    func changeScreen (toIndex: Int? = nil) {
        if let toIndex = toIndex {
            indexForScreen = toIndex-1
        }
        if indexForScreen < 2 && indexForScreen > -2 {
            indexForScreen += 1
            getImage()
            getText()
        } else {
            getNextVC()
        }
    }
    
    func getNextVC () {
        guard let vc = model?.nextVC else { return }
        nextVC.value = vc.init()
    }
    
    private(set) var model: OnboardingModel?
    
    init() {
        model = OnboardingModel(viewModel: self)
    }
        
}
