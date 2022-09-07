//
//  PublicFilesVM.swift
//  YaDisk
//
//  Created by Devel on 19.08.2022.
//

import Foundation
import YaAPI

final class PublicFilesTableVM: LastFilesTableVM {
    // MARK: Gets first rows of the table
    override func getData () {
        guard canRqstData else { return }
        canRqstData = false
        let fileManager = YaFileManager()
        fileManager.getPublicFiles { [weak self] publicResources, error in
            guard let self = self else { return }
            Functions().markAllPubFlUpdatedAsApplied()
            self.canRqstData = true
            self.actIndicator.value = false
            self.auth()
            let count = publicResources?.count ?? 0
            self.filesCount = count < YaConst.publicFilesPageLimit ? Int64(count)
                : Int64(YaConst.publicFilesPageLimit * 2)
            self.tableData.value = publicResources
            if let error = error,
               error != .cantAuthWithToken
                && error != .noConnectionToDisk {
                self.errorHandled.value = error.errorStruct
            }
        }
    }
    // MARK: Gets new rows after scrolling down the table
    override func getNextPage () {
        let offset = tableData.value?.count ?? 0
        guard canRqstData && offset > 0 && filesCount > offset
        else { return }
        canRqstData = false
        YaFileManager().getPublicFiles(offset: offset) {
            [weak self] publicResources, error in
            guard let self = self else { return }
            Functions().markAllPubFlUpdatedAsApplied()
            self.canRqstData = true
            self.actIndicator.value = false
            let count = publicResources?.count ?? 0
            let tbCount = self.tableData.value?.count ?? 0
            self.filesCount = count < YaConst.publicFilesPageLimit ? Int64(count+tbCount)
                : Int64(YaConst.publicFilesPageLimit * 2 + tbCount)
            guard let publicResources = publicResources,
                  !publicResources.isEmpty
            else { return }
            self.tableData.value?.append(contentsOf: publicResources)
        }
    }
    
    override init() {
        super.init()
        identify = "PublicFiles"
    }
}
