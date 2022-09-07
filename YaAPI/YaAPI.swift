//
//  YaAPI.swift
//  YaAPI
//
//  Created by Devel on 10.07.2022.
//

import Foundation
import Shared

final public class YaAPI {
    public static var oauthServerConnectionStatus = Box(value: true)
    public static var driveServerConnectionStatus = Box(value: true)
    
    // MARK: OAUTH
    func getUserToken (code: String, completion: @escaping (UserToken?, Int?)->Void) {
        struct GetRequest: Codable {
            let grant_type:    String
            let code:          String
            let client_id:     String
            let client_secret: String
        }
        let parameters = GetRequest (grant_type: "authorization_code",
                                     code: code,
                                     client_id: YaConst.regID,
                                     client_secret: YaConst.regPW)
        NetworkService().postRequest(url: YaConst.oauthToken, parameters: parameters, completion: completion)
    }
    
    func revokeUserToken (token: String, completion: @escaping (Bool?, Int?)->Void) {
        struct RevokeRequest: Codable {
            let access_token:  String
            let client_id:     String
            let client_secret: String
        }
        let parameters = RevokeRequest(access_token: token,
                                       client_id: YaConst.regID,
                                       client_secret: YaConst.regPW)
        NetworkService().postRequest (url: YaConst.oauthRevokeToken, parameters: parameters) {
            (result: StringStatusResponce?, httpStatusCode: Int?) in
            if result != nil && httpStatusCode == nil {
                completion(true, nil)
            } else { completion(nil, httpStatusCode) }
        }
    }
    
    func updateUserToken (refresh_token: String, completion: @escaping (UserToken?, Int?)->Void) {
        struct RevokeRequest: Codable {
            let grant_type:    String
            let refresh_token: String
            let client_id:     String
            let client_secret: String
        }
        let parameters = RevokeRequest(grant_type: "refresh_token",
                                       refresh_token: refresh_token,
                                       client_id: YaConst.regID,
                                       client_secret: YaConst.regPW)
        NetworkService().postRequest (url: YaConst.oauthToken, parameters: parameters, completion: completion)
    }
    // MARK: DISK
    func userInfo (token: String, completion: @escaping (UserInfo?, Int?)->Void) {
        let url = YaConst.disk
        let parameters = [String:String]()
        NetworkService().getRequest(url: url, parameters: parameters, token: token, completion: completion)
    }
    
    // LastFiles
    func getLastFiles (token: String, limit: Int? = nil, completion: @escaping (FileResourceList?, Int?)->Void) {
        struct LastFilesParams: Codable {
            let limit: Int
            let fields: String
            let preview_size: String
            let preview_crop: String
        }
        let limit: Int = limit ?? YaConst.lastFilesLimit
        let parameters = LastFilesParams(
            limit: limit,
            fields: "limit, items.resource_id, items.name, items.path, items.file, items.preview, items.revision, items.created, items.modified, items.size, items.mime_type, items.media_type, items.md5, items.public_url",
            preview_size: YaConst.lastFilesPreviewSize,
            preview_crop: YaConst.lastFilesPreviewCrop)
        let url = YaConst.diskLastFiles
        NetworkService().getRequest(url: url, parameters: parameters, token: token) { result, httpStatusCode in
            completion(result, httpStatusCode)
        }
    }
    
    // AllFiles
    func getAllFiles (token: String, path: String, limit: Int? = nil, offset: Int = 0,
                      sort: String = "name", completion: @escaping (FileResource?, Int?)->Void) {
        struct AllFilesParams: Codable {
            let path:         String
            let fields:       String
            let limit:        Int
            let offset:       Int
            let preview_size: String
            let preview_crop: String
            let sort:         String
        }
        let limit: Int = limit ?? YaConst.allFilesPageLimit
        let parameters = AllFilesParams(
            path:   path,
            fields: """
            resource_id, name, path, type, created, modified, revision, public_url, public_key, md5, 
            _embedded.path, _embedded.limit, _embedded.offset, _embedded.sort, _embedded.total,
            _embedded.items.resource_id, _embedded.items.name, _embedded.items.type, _embedded.items.path, _embedded.items.file, _embedded.items.preview, _embedded.items.revision, _embedded.items.created, _embedded.items.modified, _embedded.items.size, _embedded.items.mime_type, _embedded.items.media_type, _embedded.items.md5, _embedded.items.public_url
            """,
            limit:  limit,
            offset: offset,
            preview_size: YaConst.allFilesPreviewSize,
            preview_crop: YaConst.allFilesPreviewCrop,
            sort:   sort
        )
        let url = YaConst.resources
        NetworkService().getRequest(url: url, parameters: parameters, token: token) { result, httpStatusCode in
            completion(result, httpStatusCode)
        }
    }
    
    // PublicFiles
    func getPublicFiles (token: String, limit: Int? = nil, offset: Int = 0,
                         completion: @escaping (PublicResourceList?, Int?)->Void) {
        struct PublicFilesParams: Codable {
            let limit: Int
            let offset: Int
            let fields: String
            let preview_size: String
            let preview_crop: String
        }
        let limit: Int = limit ?? YaConst.publicFilesPageLimit
        let parameters = PublicFilesParams(
            limit:  limit,
            offset: offset,
            fields: "items.resource_id, items.name, items.path, items.type, items.file, items.preview, items.revision, items.created, items.modified, items.size, items.mime_type, items.media_type, items.md5, items.public_url, items.public_key",
            preview_size: YaConst.publicFilesPreviewSize,
            preview_crop: YaConst.publicFilesPreviewCrop)
        let url = YaConst.diskPublicFiles
        NetworkService().getRequest(url: url, parameters: parameters, token: token) { result, httpStatusCode in
            completion(result, httpStatusCode)
        }
    }
    
    // Item resource
    func getResource (token: String, resourceId: String, completion: @escaping (FileResource?, Int?)->Void) {
        struct ItemResourceParams: Codable {
            let fields: String
        }
        let parameters = ItemResourceParams(
            fields: "resource_id, name, type, path, file, preview, revision, created, modified, size, mime_type, media_type, md5, public_url"
        )
        let url = YaConst.resources + resourceId
        NetworkService().getRequest(url: url, parameters: parameters, token: token) { result, httpStatusCode in
            completion(result, httpStatusCode)
        }
    }
    
    // Download
    func downloadFileWithUrl (url: String, token: String,
                              progressHandler: @escaping (Progress) -> Void,
                              to: URL, completion: @escaping (URL?, Int?)->Void) {
        let parameters = [String:String]()
        NetworkService().download(url: url, parameters: parameters,
                                  to: to, token: token, progressHandler: progressHandler,
                                  completion: completion)
    }
    
    // Delete
    func deletePath (token: String, path: String, permanently: String,
                     completion: @escaping (Int)->Void) {
        struct DeleteParams: Codable {
            let path: String
            let permanently: String
        }
        let url = YaConst.resources
        let parameters = DeleteParams(path: path, permanently: permanently)
        
        NetworkService().delete(url: url, parameters: parameters,
                                token: token, completion: completion)
    }
    
    // Move/Rename
    func move (pathFrom: String, pathTo: String, overwrite: String = "false",
               token: String, completion: @escaping (Link?, Int?)->Void) {
        struct UpdateParams: Codable {
            let from:       String
            let path:       String
            let overwrite:  String
        }
        let parameters = UpdateParams(from: pathFrom, path: pathTo, overwrite: overwrite)
        NetworkService().postRequest(url: YaConst.move, token: token, parameters: parameters,
                                     parametersEncodeTo: .queryString, completion: completion)
    }
    
    // Publish/unpublish resource
    func publish (unpubl: Bool = false, path: String, token: String,
                  completion: @escaping (String?, Int?)->Void) {
        struct UpdateParams: Codable {
            let path:       String
        }
        let url = unpubl ? YaConst.unpublish : YaConst.publish
        let parameters = UpdateParams(path: path)
        NetworkService().postRequest (url: url, token: token,
                                     method: "PUT", parameters: parameters,
                                      parametersEncodeTo: .queryString){ (link: Link?, httpStatusCode: Int?) in
            guard let getUrl = link?.href else {
                completion(nil, httpStatusCode)
                return
            }
            if unpubl {
                completion(getUrl, nil)
                return
            }
            let parameters = [String:String]()
            NetworkService().getRequest(url: getUrl, parameters: parameters, token: token) {
                (fileResource: FileResource?, httpStatusCode: Int?) in
                guard let urlString = fileResource?.public_url else {
                    completion(nil, httpStatusCode)
                    return
                }
                completion(urlString, nil)
            }
        }
    }
}
