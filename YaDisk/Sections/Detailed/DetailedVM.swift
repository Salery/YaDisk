//
//  DetailedVM.swift
//  YaDisk
//
//  Created by Devel on 26.07.2022.
//

import Foundation
import Shared
import YaAPI
import UIKit

protocol DetailedVMProtocol: VMProtocol {
    var tableIndex:         Int                  { get }
    var detailedType:       DetailedTypes        { get }
    var file:               Box<URL?>            { get }
    var progress:           Box<Progress?>       { get }
    var fileIsDownloading:  Box<Bool>            { get }
    var dataForDetailes:    Box<DetailedOutput?> { get }
    func rename  (to: String,
                     completion: @escaping (Bool)->Void)
    func delete  (permanently: String,
                     completion: @escaping (Bool)->Void)
    func publish (completion: @escaping (String?)->Void)
}

final class DetailedVM: VMClass, DetailedVMProtocol {
    private let model: DetailedM
    
    let tableIndex:        Int
    let detailedType:      DetailedTypes
    let file:              Box<URL?>            = Box(value: nil)
    let progress:          Box<Progress?>       = Box(value: nil)
    let fileIsDownloading: Box<Bool>            = Box(value: false)
    let dataForDetailes:   Box<DetailedOutput?> = Box(value: nil)
    private var timer: Timer?
    private var fileURL: URL?
    
    init (from: DetailedInput) {
        detailedType = from.type
        tableIndex   = from.index
        model = DetailedM(from)
        super.init()
        dataForDetailes.value = model.getDataForDetailes()
        startDownload()
    }
    // MARK: Actions with the file
    // Rename
    func rename (to: String, completion: @escaping (Bool)->Void) {
        let index       = tableIndex
        let startsFrom  = model.input.startsFrom
        let resource_id = model.input.resource_id
        let md5         = model.input.md5
        let pathFrom    = model.input.path
        let pathTo      = Functions().getFolderPath(pathFrom: pathFrom) + "/" + to
        DispatchQueue.global(qos: .utility).async {
            YaFileManager().move(pathFrom: pathFrom, pathTo: pathTo) { error in
                self.auth()
                if error == nil {
                    completion(true)
                    self.model.input.name = to
                    self.model.input.path = pathTo
                    CoreDataManager.shared.renameLastFile (
                        name:         to,
                        resource_id:  resource_id,
                        md5:          md5,
                        pathTo:       pathTo
                    )
                    CoreDataManager.shared.renameAllFile(
                        name:         to,
                        resource_id:  resource_id,
                        md5:          md5,
                        pathFrom:     pathFrom,
                        pathTo:       pathTo
                    )
                    CoreDataManager.shared.renamePublicFile(
                        name:         to,
                        resource_id:  resource_id,
                        md5:          md5,
                        pathFrom:     pathFrom,
                        pathTo:       pathTo
                    )
                    let modifiedData = ModifiedData(
                        index:        index,
                        resource_id:  resource_id,
                        md5:          md5,
                        modifiedType: .renamed,
                        name:         to,
                        pathFrom:     pathFrom,
                        pathTo:       pathTo,
                        modifiedBy:   startsFrom
                    )
                    ModifiedData.register.append(modifiedData)
                    NotificationCenter.default.post(
                        name: NSNotification.Name("com.file.changed"),
                        object: nil)
                } else {
                    completion(false)
                    if error != .cantAuthWithToken {
                        self.errorHandled.value = error!.errorStruct
                    }
                }
            }
        }
    }
    // Deelete
    func delete (permanently: String = "false",
                 completion: @escaping (Bool)->Void) {
        let name        = model.input.name
        let resource_id = model.input.resource_id
        let md5         = model.input.md5
        let pathFrom        = model.input.path
        let index       = tableIndex
        let startsFrom  = model.input.startsFrom
        
        DispatchQueue.global(qos: .utility).async {
            YaFileManager().deleteRemoteResource(
                path: pathFrom, permanently: permanently) { error in
                    self.auth()
                    if error == nil {
                        completion(true)
                        CoreDataManager.shared.deleteFromLastFiles(
                            name:         name,
                            resource_id:  resource_id,
                            md5:          md5
                        )
                        CoreDataManager.shared.deleteFromAllFiles (
                            name:         name,
                            resource_id:  resource_id,
                            md5:          md5,
                            path:         pathFrom
                        )
                        CoreDataManager.shared.deleteFromPublicFiles (
                            name:         name,
                            resource_id:  resource_id,
                            md5:          md5,
                            path:         pathFrom
                        )
                        let modifiedData = ModifiedData(
                            index:        index,
                            resource_id:  resource_id,
                            md5:          md5,
                            modifiedType: .deleted,
                            name:         "",
                            pathFrom:     pathFrom,
                            modifiedBy:   startsFrom
                        )
                        ModifiedData.register.append(modifiedData)
                        NotificationCenter.default.post(
                            name: NSNotification.Name("com.file.changed"),
                            object: nil)
                    } else {
                        completion(false)
                        if error != .cantAuthWithToken {
                            self.errorHandled.value = error!.errorStruct
                        }
                    }
                }
        }
    }
    // Publish
    func publish(completion: @escaping (String?)->Void) {
        if let url = model.input.public_url { completion(url); return }
        let resource_id = model.input.resource_id
        let md5         = model.input.md5
        let index       = tableIndex
        let startsFrom  = model.input.startsFrom
        let pathFrom        = model.input.path
        if startsFrom == "PublicFiles" { completion(nil); return }
        
        DispatchQueue.global(qos: .utility).async {
            YaFileManager().publish(path: pathFrom) { publicUrl, error in
                self.auth()
                if let publicUrl = publicUrl {
                    completion(publicUrl)
                    self.model.input.public_url = publicUrl
                    let modifiedData = ModifiedData(
                        index:        index,
                        resource_id:  resource_id,
                        md5:          md5,
                        modifiedType: .published,
                        name:         "",
                        pathFrom:     pathFrom,
                        public_url:   publicUrl,
                        modifiedBy:   startsFrom
                    )
                    ModifiedData.register.append(modifiedData)
                    NotificationCenter.default.post(
                        name: NSNotification.Name("com.file.changed"),
                        object: nil)
                    CoreDataManager.shared.publishLastFile(
                        public_url:   publicUrl,
                        resource_id:  resource_id,
                        md5:          md5
                    )
                    CoreDataManager.shared.publishAllFile (
                        public_url:   publicUrl,
                        resource_id:  resource_id,
                        md5:          md5,
                        path:         pathFrom
                    )
                } else {
                    completion(nil)
                    if let error = error, error != .cantAuthWithToken {
                           self.errorHandled.value = error.errorStruct
                       }
                }
            }
        }
    }
    
    // MARK: File download
    // If view is reopened while downloading
    private func progressExists (id: String) -> Bool {
        if let progress = DownloadManager.shared.getSession(id: id) {
            fileIsDownloading.value = true
            self.progress.value = progress
            fileURL = getFilePath(id: id)
            timer = Timer.scheduledTimer(timeInterval: 1/10, target: self,
                                         selector: #selector(changeProgress), userInfo: nil, repeats: true)
            return true
        }
        return false
    }
    // Full local filePath
    private func getFilePath (id: String) -> URL {
        var fileUrl = Const.Paths.cachesDirectoryURL
        fileUrl = fileUrl.appendingPathComponent(YaConst.filesDir, isDirectory: true)
        return fileUrl.appendingPathComponent(id, isDirectory: false)
    }
    // To start download
    func startDownload(manualStart: Bool = false) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let download = self.model.getDataForDownload(),
                  !self.progressExists(id: download.id)
            else { return }
            self.downloadFile(url: download.url, id: download.id, size: download.size, manualStart: manualStart)
        }
    }
    // Adding cache file info to the CoreData (only for AllFiles)
    private func addAllFlsFCache(cacheFileName: String) {
        if self.model.input.startsFrom != "LastFiles" {
            // The AllFiles module takes care of the cache file
            CoreDataManager.shared.setAllFlsFCache(
                resource_id:   model.input.resource_id,
                md5:           model.input.md5,
                path:          model.input.path,
                cacheFileName: cacheFileName,
                revision:      model.input.revision)
        }
    }
    // Checks for cache and if not, downloads
    private func downloadFile (url: String, id: String, size: Int64, manualStart: Bool = false) {
        let fileUrl = getFilePath(id: id)
// MARK: Delete: false/true &&
        if true && FileManager.default.fileExists(atPath: fileUrl.path) {
            file.value = fileUrl
            if model.input.startsFrom == "LastFiles" {
                // The LastFiles module takes care of the cache file
                CoreDataManager.shared.deleteFromAllFlsFCache(cacheFileName: id)
            }
            return
        }
        // Manual upload required for large files or for files that can't be shown
        if (model.input.type == .withoutView
            || model.input.size > Const.Sizes.flAutoDownloadSize)
            && !manualStart { return }
        fileIsDownloading.value = true
        addAllFlsFCache(cacheFileName: id)
        YaFileManager().downloadFileWithUrl(url: url, id: id, size: size, preview: false,
                                            progress: {[weak self] in self?.progress.value = $0}) {
            [weak self] url, error in
            guard let self = self else { return }
            self.fileIsDownloading.value = false
            self.auth()
            if let error = error,
               error != .cantAuthWithToken
                && error != .noConnectionToDisk {
                self.errorHandled.value = error.errorStruct
            }
            guard let url = url else { return }
            self.file.value = url
        }
    }
    
    // MARK: For icon in the rename alert view
        func getPreview () -> URL? {
            return nil
        }
        
        func getIcon () -> String {
            return ""
        }
    // ----
    
    // reeading the progress using the timer
    @objc private func changeProgress () {
        progress.value = progress.value
        if progress.value?.isCancelled == true || progress.value?.isFinished == true {
            if progress.value?.isCancelled == true {
                errorHandled.value = DownloadError.downloadCanceled.errorStruct
            }
            if progress.value?.isFinished == true {
                file.value = fileURL
            }
            fileIsDownloading.value = false
            timer?.invalidate()
            timer = nil
        }
    }
    
    deinit {
        print("Deinit: ", self)
    }
}
