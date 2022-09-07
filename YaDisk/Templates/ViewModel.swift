//
//  VMProtocol.swift
//  YaDisk
//
//  Created by Devel on 01.08.2022.
//

import UIKit
import Shared
import YaAPI

protocol VMProtocol {
    var errorHandled: ErrorBox               { get }
    var authorized:   Box<Bool?>             { get }
    var connStatus:   Box<Bool?>             { get }
    var startVC:      UIViewController.Type  { get }
}

class VMClass: VMProtocol {
    var errorHandled:   ErrorBox               = ErrorBox(value: nil)
    let authorized:     Box<Bool?>             = Box(value: nil)
    let startVC:        UIViewController.Type  = StartVC.self
    let connStatus:     Box<Bool?>             = Box(value: nil)
    
    init () {
        binder()
    }
    
    func auth() {
        authorized.value = Auth.authorized.value
    }
    
    func binder () {
        YaAPI.driveServerConnectionStatus.bindAndFire { status in
            self.connStatus.value = status
        }
    }
}
