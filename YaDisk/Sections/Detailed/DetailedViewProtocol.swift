//
//  DetailedViewProtocol.swift
//  YaDisk
//
//  Created by Devel on 02.08.2022.
//

protocol DetailedViewProtocol: AnyObject, ViewProtocol where ViewModelType: DetailedVMProtocol {
    var viewModel: ViewModelType { get }
}
