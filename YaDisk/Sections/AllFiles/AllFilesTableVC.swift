//
//  AllFilesTableVC.swift
//  YaDisk
//
//  Created by Devel on 11.08.2022.
//

import Foundation

final class AllFilesTableVC: LastFilesTableVC {
    init(path: String? = nil, title: String? = nil) {
        let viewModel = AllFilesTableVM(path: path)
        super.init(viewModel: viewModel, title: title)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
