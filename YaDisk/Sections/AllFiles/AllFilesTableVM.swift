//
//  AllFilesVM.swift
//  YaDisk
//
//  Created by Devel on 10.08.2022.
//

import Foundation
import YaAPI

final class AllFilesTableVM: LastFilesTableVM {
    var path: String
    // MARK: Gets first rows of the table
    override func getData () {
        guard canRqstData else { return }
        canRqstData = false
        let fileManager = YaFileManager()
        fileManager.getAllFiles(path: path) {[weak self] fileResource, error in
            guard let self = self else { return }
            Functions().markAllFlUpdatedAsAppliedForPath(path: self.path)
            self.canRqstData = true
            self.actIndicator.value = false
            self.auth()
            self.filesCount = fileResource?._embedded?.total ?? 0
            self.tableData.value = fileResource?._embedded?.items
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
        YaFileManager().getAllFiles(path: path, offset: offset) {[weak self] fileResource, error in
            guard let self = self else { return }
            Functions().markAllFlUpdatedAsAppliedForPath(path: self.path)
            self.canRqstData = true
            self.actIndicator.value = false
            guard let fileResources = fileResource?._embedded?.items,
                  !fileResources.isEmpty
            else { return }
            self.tableData.value?.append(contentsOf: fileResources)
        }
    }
    
    init(path: String? = nil) {
        self.path = path ?? "disk:/"
        super.init()
        identify = "AllFiles"
    }
}
