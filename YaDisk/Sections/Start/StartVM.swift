//
//  StartVM.swift
//  YaDisk
//
//  Created by Devel on 07.07.2022.
//

import Shared
import UIKit
import YaAPI

protocol StartVMProtocol: AnyObject, VMProtocol {
    var model: StartModel?     { get }
    func toAuthorizeVC  () -> UIViewController
    func toNextVC       () -> UIViewController
    func refreshAuth    ()
    func clearError     ()
}

final class StartVM: VMClass, StartVMProtocol {
    private(set) var model: StartModel?
    
    func toAuthorizeVC() -> UIViewController {
        guard let model = model,
              let url = model.authURL
        else { return UIViewController() }
        let vc = model.authorizeVC.init(url: url)
        vc.dismissButtonStyle = .close
        // set a state field for checking auth responce
        model.setResponceAuthState()
        return vc
    }
    
    func toNextVC() -> UIViewController {
        model?.nextVC.init() ?? UIViewController()
    }
    
    func refreshAuth () {
        Auth().checkAuthorization()
    }
    
    func clearError () {
        ErrorStruct.myError.value = nil
    }
    
    override init() {
        super.init()
        model = StartModel(viewModel: self)
    }
    
    override func binder () {
        super.binder()
        ErrorStruct.myError.bindAndFire { [weak self] error in
            guard let error = error,
            let self = self
            else { return }
            self.errorHandled.value = error.errorStruct
        }
        Auth.authorized.bind { [weak self] authorized in
            guard let self = self
            else { return }
            if self.authorized.value != authorized {
                self.authorized.value = authorized
            }
        }
    }
        
}
