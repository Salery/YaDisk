//
//  LastFilesTableVM.swift
//  YaDisk
//
//  Created by Devel on 19.07.2022.
//

//import Foundation
import YaAPI
import Shared
import UIKit

protocol LastFilesTableVMProtocol: VMProtocol {
    var tableData:    Box<[FileResource]?>   { get }
    var actIndicator: Box<Bool>              { get }
    var canRqstData:  Bool                   { get }
    var modifiedData: [ModifiedData]         { get }
    func getData        ()
    func getNextPage    ()
    func getDataForCell (index: Int) -> FilesListCellInput?
    func getDetailes    (index: Int) -> DetailedInput?
    func modifiedDataHandler (_ modifiedData: ModifiedData)
    func removeModifiedData  ()
    func detailedDataModified()
}

class LastFilesTableVM: VMClass, LastFilesTableVMProtocol {
    let tableData:      Box<[FileResource]?>   = Box(value: nil) // Model
    
    let actIndicator:   Box<Bool>              = Box(value: false)
    var canRqstData = true
    private(set) var modifiedData = [ModifiedData]()
    var filesCount: Int64 = 0
    var identify = "LastFiles"
    
    // MARK: Gets first rows of the table
    func getData () {
        guard canRqstData else { return }
        canRqstData = false
        let fileManager = YaFileManager()
        fileManager.getLastFiles() {[weak self] fileResources, error, resultDefferedAnswer in
            guard let self = self else { return }
            Functions().markAllLstFlUpdatedAsApplied()
            if resultDefferedAnswer != nil, resultDefferedAnswer!.value > 0 {
                resultDefferedAnswer?.bind({ result in
                    self.canRqstData = true
                    self.filesCount = Int64(resultDefferedAnswer?.value ?? 0)
                    resultDefferedAnswer?.unBind()
                })
            } else {
                self.filesCount = -Int64(resultDefferedAnswer?.value ?? 0)
                self.canRqstData = true
            }
            self.auth()
            self.tableData.value = fileResources
            if let error = error,
               error != .cantAuthWithToken
                && error != .noConnectionToDisk {
                self.errorHandled.value = error.errorStruct
            }
        }
    }
    // MARK: Gets new rows after scrolling down the table
    func getNextPage () {
        let offset = tableData.value?.count ?? 0
        guard canRqstData && offset > 0 && filesCount > offset
        else { return }
        canRqstData = false
        YaFileManager().getLastFiles(offset: offset) {[weak self] fileResources, error, resultDefferedAnswer in
            guard let self = self else { return }
            Functions().markAllLstFlUpdatedAsApplied()
            self.canRqstData = true
            self.actIndicator.value = false
            guard let fileResources = fileResources,
                  !fileResources.isEmpty
            else { return }
            self.tableData.value?.append(contentsOf: fileResources)}
    }
    // MARK: Data for the table cells
    func getDataForCell (index: Int) -> FilesListCellInput? {
        guard let fileResource = tableData.value?[index]
        else { return nil }
        return FilesListCellInput(
            resource_id: fileResource.resource_id,
            name:      fileResource.name,
            size:      fileResource.size ?? 0,
            created:   fileResource.created,
            type:      fileResource.type,
            mime_type: fileResource.mime_type,
            preview:   fileResource.preview,
            md5:       fileResource.md5
        )
    }
    // MARK: Data for the Detailed view
    func getDetailes (index: Int) -> DetailedInput? {
        guard let fileResource = tableData.value?[index]
        else { return nil }
        let type: DetailedTypes = fileResource.type == "dir" ? .dir :
            fileResource.mime_type?.contains("pdf") ?? false ? .pdf :
                DetailedTypes(rawValue: fileResource.media_type ?? "") ?? .withoutView
        return DetailedInput(
            index:       index,
            resource_id: fileResource.resource_id,
            name:        fileResource.name,
            size:        fileResource.size ?? 0,
            created:     fileResource.created,
            type:        type,
            md5:         fileResource.md5,
            file:        fileResource.file,
            path:        fileResource.path,
            public_url:  fileResource.public_url,
            revision:    fileResource.revision ?? 0,
            startsFrom:  identify
        )
    }
    // MARK: Handle response from Detailed view
    func modifiedDataHandler (_ modifiedData: ModifiedData) {
        var modifiedData = modifiedData
        if modifiedData.modifiedBy != identify {
            guard let newIndex = tableData.value?.firstIndex(where: { file in
                (file.resource_id != nil
                 && file.resource_id == modifiedData.resource_id)
                || (file.md5 != nil
                    && file.md5 == modifiedData.md5)
                || file.path == modifiedData.pathFrom
            })
            else { return }
            modifiedData.index = newIndex
        }
        if modifiedData.modifiedType != .published {
            self.modifiedData.append(modifiedData)
        }
        switch modifiedData.modifiedType {
        case .deleted: break
        case .renamed:
            rename (modifiedData.index, name: modifiedData.name, pathTo: modifiedData.pathTo)
        case .published:
            setPublicUrl (modifiedData.index, publicUrl: modifiedData.public_url)
        }
    }
    
    func removeModifiedData () {
        modifiedData = []
    }
    
    func detailedDataModified() {
        for index in 0..<ModifiedData.register.count {
            if (identify == "LastFiles"
                && ModifiedData.register[index].lstFlUpdated)
                || (identify == "AllFiles"
                    && ModifiedData.register[index].allFlUpdated)
                || (identify == "PublicFiles"
                    && ModifiedData.register[index].pubFlUpdated){ continue }
            if identify == "LastFiles" { ModifiedData.register[index].lstFlUpdated = true }
            else if identify == "PublicFiles" { ModifiedData.register[index].pubFlUpdated = true }
            else {
                var mPath = String(ModifiedData.register[index].pathFrom.dropLast())
                mPath = Functions().getFolderPath(pathFrom: mPath)
                if identify == "AllFiles",
                   let allFlTblVMObj = self as? AllFilesTableVM,
                   allFlTblVMObj.path != mPath
                    && allFlTblVMObj.path != mPath + "/" { continue }
                ModifiedData.register[index].allFlUpdated = true
            }
            modifiedDataHandler(ModifiedData.register[index])
        }
        Functions().clearAppliedChanges()
    }
    
    func delete (_ index: Int) {
        if tableData.value != nil && index < tableData.value!.endIndex {
            tableData.value?.remove(at: index)
        }
    }
    
    func unpublResource (_ index: Int) {
        if tableData.value != nil && index < tableData.value!.endIndex {
            guard let removeData = tableData.value?[index] else { return }
            YaFileManager().publish(unpubl: true, path: removeData.path) {
                [weak self] url, error in
                guard let self = self else { return }
                self.auth()
                if url != nil {
                    DispatchQueue.main.async {
                        CoreDataManager.shared.deleteFromPublicFiles(
                            name: removeData.name, resource_id: removeData.resource_id,
                            md5: removeData.md5, path: removeData.path)
                        self.tableData.value?.remove(at: index)
                    }
                }
                if let error = error,
                   error != .cantAuthWithToken
                    && error != .noConnectionToDisk {
                    self.errorHandled.value = error.errorStruct
                }
            }
            
        }
    }
    
    private func rename (_ index: Int, name: String, pathTo: String?) {
        if tableData.value != nil && index < tableData.value!.endIndex {
            tableData.value?[index].name = name
            guard let pathTo = pathTo else { return }
            tableData.value?[index].path = pathTo
        }
    }
    
    private func setPublicUrl (_ index: Int, publicUrl: String?) {
        if tableData.value != nil && index < tableData.value!.endIndex {
            tableData.value?[index].public_url = publicUrl
        }
    }
    
    override init () {
        super.init()
        getData()
    }
    deinit {
        
    }
}
