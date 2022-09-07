//
//  PublicFilesVC.swift
//  YaDisk
//
//  Created by Devel on 19.08.2022.
//

import Foundation

final class PublicFilesTableVC: LastFilesTableVC {
    init() {
        let viewModel = PublicFilesTableVM()
        let title = NSLocalizedString("Public files", comment: "Title.publicFiles")
        super.init(viewModel: viewModel, title: title)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
