//
//  ProfileViewProtocol.swift
//  YaDisk
//
//  Created by Devel on 16.08.2022.
//

protocol ProfileViewProtocol: AnyObject, ViewProtocol where ViewModelType: ProfileVMProtocol {
    var viewModel: ViewModelType { get }
}
