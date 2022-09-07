//
//  Model.swift
//  YaDisk
//
//  Created by Devel on 07.07.2022.
//

import Foundation
import YaAPI
import SafariServices

final class StartModel {
    let authorizeVC  = SFSafariViewController.self  // AuthVC.self
    var nextVC = TabBarController.self
    var authURL: URL?
    var requestAuthState: String?
    private weak var viewModel: StartVMProtocol?
    
    init(viewModel: StartVMProtocol) {
        self.viewModel = viewModel
        DispatchQueue.main.async {
            [weak self] in
            self?.checkAuth()
        }
    }
    
    private func checkAuth () {
        let auth = Auth()
        authURL = auth.getURLForAuth()
        requestAuthState = auth.state
        auth.checkAuthorization()
    }
    
    func setResponceAuthState () {
        guard let requestAuthState = requestAuthState
        else { print("requestAuthState is empty!"); return }
        Auth.responceAuthState = requestAuthState
    }
}
