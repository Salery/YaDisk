//
//  LastFilesViewProtocol.swift
//  YaDisk
//
//  Created by Devel on 01.08.2022.
//


protocol LastFilesViewProtocol: AnyObject, ViewProtocol where ViewModelType: LastFilesTableVMProtocol {
    var viewModel: ViewModelType { get }
}
