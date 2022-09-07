//
//  CleanUserData.swift
//  YaAPI
//
//  Created by Devel on 18.07.2022.
//

import Foundation
import Shared

final public class YaFileManager {
    /// clear files & preview cache folders
    func clearAppFolder () {
        let fileManager = FileManager.default
        let arrFolders = [
            Const.Paths.cachesDirectoryURL
                .appendingPathComponent(YaConst.previewDir, isDirectory: true),
            Const.Paths.cachesDirectoryURL
                .appendingPathComponent(YaConst.filesDir  , isDirectory: true)
        ]
        do {
            try arrFolders.forEach { url in
                let fileURLs = try fileManager.contentsOfDirectory (at: url,
                                                                    includingPropertiesForKeys: nil,
                                                                    options: [.skipsHiddenFiles])
                for url in fileURLs {
                    try fileManager.removeItem(at: url)
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    /// removes stale LastFiles file cache
    func removeStaleFileCache (_ fileNames: [String]) {
        let fileManager   = FileManager.default
        let previewFolder = Const.Paths.cachesDirectoryURL
                .appendingPathComponent(YaConst.previewDir, isDirectory: true)
        let filesFolder   = Const.Paths.cachesDirectoryURL
                .appendingPathComponent(YaConst.filesDir  , isDirectory: true)
        do {
            for name in fileNames {
                let urls = [
                    previewFolder.appendingPathComponent(name, isDirectory: false),
                    filesFolder  .appendingPathComponent(name, isDirectory: false)
                ]
                try urls.forEach { url in
                    if fileManager.fileExists(atPath: url.path) {
                        try fileManager.removeItem(at: url)
                    }
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    /// clear AllFlsFCache file from CoreData & cache folders by given file name
    func removeAllFlsFCache (cacheFileName: String) {
        CoreDataManager.shared.deleteFromAllFlsFCache(cacheFileName: cacheFileName)
        removeStaleFileCache([cacheFileName])
    }
    
    public init () { }
    
    public func getAvailableSpace () -> Int64? {
        let keys: Set<URLResourceKey> = [.volumeAvailableCapacityForOpportunisticUsageKey]
        do {
            return try Const.Paths.cachesDirectoryURL.resourceValues(forKeys: keys)
                .volumeAvailableCapacityForOpportunisticUsage
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
    // MARK: Profile
    public func getUserInfo (completion: @escaping (UserInfo?, UserInfoError?)->Void) {
        guard let token = KeyChainService().getUserKey()
        else {
            completion(nil, nil)
            Auth().logOff() // Auth unavailable without key
            return
        }
        YaAPI().userInfo(token: token) { userInfo, httpStatusCode in
            guard let userInfo = userInfo
            else {
                let error = HttpErrorHandler()
                    .checkErrorCode(httpStatusCode: httpStatusCode,
                                    errorType: UserInfoError.self)
                completion(nil, error)
                return
            }
            YaAPI.driveServerConnectionStatus.value = true
            completion(userInfo, nil)
        }
    }
    
    // MARK: LastFiles
    /// get files from YaAPI's last uploaded section or CoreData (LastFiles)
    public func getLastFiles (offset: Int = 0,
                              completion: @escaping ([FileResource]?, LastFilesError?, Box<Int>?)->Void) {
        // use resultDefferedAnswer values < 0 without binding, values >0 for binding
        let resultDefferedAnswer: Box<Int> = Box(value: 0)
        // The list updates only from the 1st page, other pages get elements from the CoreDate
        if offset != 0 {
            let fromCoreData = CoreDataManager.shared.getLastFiles(offset: offset)
            completion(fromCoreData, nil, nil)
            return
        }
        guard let token = KeyChainService().getUserKey()
        else {
            completion(nil, nil, nil)
            Auth().logOff() // Auth unavailable without key
            return
        }
        // Get elements for only 1 page from the server, then get all elements and write them to the CoreDate
        let limit = YaConst.lastFilesLimit - YaConst.lastFilesPageLimit > 15 ? // No sense otherwise
                                                  YaConst.lastFilesPageLimit : YaConst.lastFilesLimit
        YaAPI().getLastFiles(token: token, limit: limit) { fileResourceList, httpStatusCode in
            guard let fileResourceList = fileResourceList
            else {
                let error = HttpErrorHandler()
                    .checkErrorCode(httpStatusCode: httpStatusCode,
                                    errorType: LastFilesError.self)
                var fromCoreData: [FileResource]? = nil
                if error != nil
                    && error!.errorsToShowCache.contains(error!.rawValue) {
                    // Use data from the CoreData, return not delayed -count (without binding)
                    resultDefferedAnswer.value = -CoreDataManager.shared.getLastFilesCount()
                    fromCoreData = CoreDataManager.shared.getLastFiles(offset: offset)
                }
                
                completion(fromCoreData, error, resultDefferedAnswer)
                return
            }
            YaAPI.driveServerConnectionStatus.value = true
            
            // Return first page, page data +count (with binding)
            resultDefferedAnswer.value = fileResourceList.items.count
            completion(fileResourceList.items, nil, resultDefferedAnswer)
            
            // If all data received - save to the CoreData & exit
            if limit != YaConst.lastFilesPageLimit
                || fileResourceList.items.count != YaConst.lastFilesPageLimit {
                DispatchQueue.global(qos: .utility).async {
                    CoreDataManager.shared.setLastFiles(fileResourceList.items)
                    // return real data count
                    DispatchQueue.main.async { resultDefferedAnswer.value = fileResourceList.items.count }
                }
                return
            }
            YaAPI().getLastFiles(token: token) { fileResourceList, httpStatusCode in
                guard let fileResourceList = fileResourceList
                else {
                    print( HttpErrorHandler()
                            .checkErrorCode(httpStatusCode: httpStatusCode,
                                            errorType: LastFilesError.self) ?? "fileResourceList - nil" )
                    // return real data count from the CoreData
                    resultDefferedAnswer.value = CoreDataManager.shared.getLastFilesCount()
                    return
                }
                DispatchQueue.global(qos: .utility).async {
                    CoreDataManager.shared.setLastFiles(fileResourceList.items)
                    // return real data count
                    DispatchQueue.main.async { resultDefferedAnswer.value = fileResourceList.items.count }
                }
            }
        }
        
    }
    
    // MARK: AllFiles
    /// get files from YaAPI's meta info section or CoreData (AllFiles)
    public func getAllFiles (path: String = "/", limit: Int? = nil, offset: Int = 0,
                             sort: String = "name", completion: @escaping (FileResource?, AllFilesError?)->Void) {
        // clearing stale file cache
        clearStaleAllFlsFCache()
        guard let token = KeyChainService().getUserKey()
        else {
            completion(nil, nil)
            Auth().logOff() // Auth unavailable without key
            return
        }
        // if disconnected & next page - shows CoreData
        if offset > 0 && !YaAPI.driveServerConnectionStatus.value {
            let fromCoreData = CoreDataManager.shared
                .getAllFiles(path: path, limit: limit, offset: offset)
            completion(fromCoreData, nil)
            return
        }
        YaAPI().getAllFiles(token: token, path: path,
                            limit: limit, offset: offset,
                            sort: sort) { fileResource, httpStatusCode in
            guard let fileResource = fileResource
            else {
                let error = HttpErrorHandler()
                    .checkErrorCode(httpStatusCode: httpStatusCode,
                                    errorType: AllFilesError.self)
                var fromCoreData: FileResource? = nil
                if error != nil
                    && error!.errorsToShowCache.contains(error!.rawValue) {
                    fromCoreData = CoreDataManager.shared
                        .getAllFiles(path: path, limit: limit, offset: offset)
                }
                completion(fromCoreData, error)
                return
            }
            YaAPI.driveServerConnectionStatus.value = true
            completion(fileResource, nil)
            
            // save to the CoreData
            DispatchQueue.global(qos: .utility).async {
                CoreDataManager.shared.setAllFiles(fileResource, offset: offset)
            }
        }
    }
    
    // MARK: PublicFiles
    /// get files from YaAPI's meta info section or CoreData (PublicFiles)
    public func getPublicFiles (limit: Int? = nil, offset: Int = 0,
                                completion: @escaping ([PublicResource]?, PublicFilesError?)->Void) {
        guard let token = KeyChainService().getUserKey()
        else {
            completion(nil, nil)
            Auth().logOff() // Auth unavailable without key
            return
        }
        // if disconnected & next page - shows CoreData
        if offset > 0 && !YaAPI.driveServerConnectionStatus.value {
            let fromCoreData = CoreDataManager.shared
                .getPublicFiles(limit: limit, offset: offset)
            completion(fromCoreData, nil)
            return
        }
        YaAPI().getPublicFiles(token: token, limit: limit,
                               offset: offset) {
            publicResourceList, httpStatusCode in
            guard let publicResources = publicResourceList?.items
            else {
                let error = HttpErrorHandler()
                    .checkErrorCode(httpStatusCode: httpStatusCode,
                                    errorType: PublicFilesError.self)
                var fromCoreData = [PublicResource]()
                if error != nil
                    && error!.errorsToShowCache.contains(error!.rawValue) {
                    fromCoreData = CoreDataManager.shared
                        .getPublicFiles(limit: limit, offset: offset)
                }
                completion(fromCoreData, error)
                return
            }
            YaAPI.driveServerConnectionStatus.value = true
            completion(publicResources, nil)
            
            // save to the CoreData
            DispatchQueue.global(qos: .utility).async {
                CoreDataManager.shared.setPublicFiles(publicResources, offset: offset)
            }
        }
    }
    
    // Updates AllFlsFCache on app start or 1 time per day
    private static var AllFlsFCacheUpdated: Date? = nil
    /// clearing stale cache
    public func clearStaleAllFlsFCache () {
        guard YaFileManager.AllFlsFCacheUpdated == nil
        || Date().timeIntervalSince(YaFileManager.AllFlsFCacheUpdated ?? Date()) > 24*3600
        else { return }
        guard let token = KeyChainService().getUserKey()
        else {
            Auth().logOff() // Auth unavailable without key
            return
        }
        let allFlsFCache = CoreDataManager.shared.getAllFlsFCache()
        func handler (file: AllFlsFCache, fileResource: FileResource?, httpStatusCode: Int?) {
            if httpStatusCode == 404
                || fileResource?.md5 != file.md5
                || fileResource?.revision != file.revision {
                removeAllFlsFCache(cacheFileName: file.cacheFileName)
            }
            if file === allFlsFCache.last
                && (httpStatusCode == 404 || fileResource != nil) {
                YaFileManager.AllFlsFCacheUpdated = Date()
            }
        }
        for file in allFlsFCache {
            if let resourceId = file.resource_id {
                YaAPI().getResource(token: token, resourceId: resourceId) {
                    fileResource, httpStatusCode in
                    handler(file: file, fileResource: fileResource, httpStatusCode: httpStatusCode)
                }
            } else {
                YaAPI().getAllFiles(token: token, path: file.path, limit: 1, offset: 0) {
                    fileResource, httpStatusCode in
                    handler(file: file, fileResource: fileResource, httpStatusCode: httpStatusCode)
                }
            }
        }
    }
    /// return url of the file in the files or the preview cache directory
    public func getFilesDirectory (preview: Bool = false) -> URL {
        let dir = Const.Paths.cachesDirectoryURL
        if preview { return dir.appendingPathComponent(YaConst.previewDir, isDirectory: true) }
        else       { return dir.appendingPathComponent(YaConst.filesDir  , isDirectory: true) }
    }
    
    // MARK: Download
    /// Downloads file from the Ya disk server
    public func downloadFileWithUrl (url: String, id: String, size: Int64? = nil,
                                     preview: Bool = false, progress: @escaping (Progress)->Void,
                                     completion: @escaping (URL?, DownloadError?)->Void) {
        guard let token = KeyChainService().getUserKey()
        else {
            completion(nil, nil)
            Auth().logOff() // Auth unavailable without key
            return
        }
        if let freeSpace = getAvailableSpace(),
           size != nil && size! > freeSpace {
            completion(nil, .notAvailableSpaceOnDevice)
            return
        }
        var progressHandler: (Progress)-> Void = {progress in }
        if !preview {
            progressHandler = { prgrss in
                DownloadManager.shared.newSession(id: id, progress: prgrss)
                progress(prgrss)
            }
        }
        let to = getFilesDirectory(preview: preview)
            .appendingPathComponent(id, isDirectory: false)
        YaAPI().downloadFileWithUrl(url: url, token: token, progressHandler: progressHandler, to: to) { url, httpStatusCode in
            var error = HttpErrorHandler()
                .checkErrorCode(httpStatusCode: httpStatusCode, errorType: DownloadError.self)
            if error == nil && url == nil { error = .downloadCanceled }
            if url != nil { YaAPI.driveServerConnectionStatus.value = true }
            completion (url, error)
            DownloadManager.shared.removeSession(id: id)
        }
    }
    
    // MARK: Delete from YaDisk
    /// Deletes a file from the Ya disk server
    public func deleteRemoteResource (path: String, permanently: String = "false",
                                      completion: @escaping (DeleteError?)->Void) {
        guard let token = KeyChainService().getUserKey()
        else {
            completion(.cantAuthWithToken)
            Auth().logOff() // Auth unavailable without key
            return
        }
        YaAPI().deletePath(token: token, path: path, permanently: permanently) { httpStatusCode in
            let error = HttpErrorHandler()
                .checkErrorCode(httpStatusCode: httpStatusCode,
                                errorType: DeleteError.self)
            completion(error)
        }
    }
    // MARK: Move/rename YaDisk resource
    /// Moves a file on the Ya disk server
    public func move (pathFrom: String, pathTo: String, overwrite: String = "false",
                                      completion: @escaping (MoveError?)->Void) {
        guard let token = KeyChainService().getUserKey()
        else {
            completion(.cantAuthWithToken)
            Auth().logOff() // Auth unavailable without key
            return
        }
        YaAPI().move(pathFrom: pathFrom, pathTo: pathTo, overwrite: overwrite,
                     token: token) { link, httpStatusCode in
            if link != nil { completion(nil) }
            else {
                let error = HttpErrorHandler()
                    .checkErrorCode(httpStatusCode: httpStatusCode,
                                    errorType: MoveError.self)
                completion(error)
            }
        }
    }
    // MARK: Publish YaDisk resource
    /// Publishes/unpublishes a file on the Ya disk server
    public func publish (unpubl: Bool = false, path: String,
                         completion: @escaping (String?, PublishError?)->Void) {
        guard let token = KeyChainService().getUserKey()
        else {
            completion(nil, .cantAuthWithToken)
            Auth().logOff() // Auth unavailable without key
            return
        }
        YaAPI().publish(unpubl: unpubl, path: path, token: token) { urlString, httpStatusCode in
            if urlString != nil { completion(urlString, nil) }
            else {
                let error = HttpErrorHandler()
                    .checkErrorCode(httpStatusCode: httpStatusCode,
                                    errorType: PublishError.self)
                completion(nil, error)
            }
        }
    }
    
}
