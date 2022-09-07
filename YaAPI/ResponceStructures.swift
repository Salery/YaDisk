//
//  ResponceStructures.swift
//  YaAPI
//
//  Created by Devel on 17.07.2022.
//

import Foundation

struct StringStatusResponce: Codable {
    let status: String
}

struct UserToken: Codable {
    let token_type: String
    let access_token: String
    let expires_in: Int64
    let refresh_token: String
    var scope: String? = nil
}

public struct UserInfo: Codable {
    struct SysFolders: Codable {
        let applications: String
        let downloads:    String
    }
    public let trash_size:  Int64
    public let total_space: Int64
    public let used_space:  Int64
    let system_folders: SysFolders
}

public struct FileResourceList: Codable {
    public var sort :   String?   = nil
    public let items :  [FileResource]
    public var type :   String?   = nil
    public var limit :  Int64?    = nil
    public var offset : Int64?    = nil
    public var path :   String?   = nil
    public var total :  Int64?    = nil
}

public struct FileResource: Codable {
    public var resource_id :   String? = nil
    public var type :          String? = nil
    public var _embedded :     FileResourceList? = nil
    public var name :          String
    public var path :          String
    public var file :          String? = nil
    public var preview :       String? = nil
    public let created :       String
    public let modified :      String
    public var size :          Int64?  = nil
    public var mime_type :     String? = nil
    public var media_type :    String? = nil
    public var md5 :           String? = nil
    public var revision :      Int64?  = nil
    public var public_key :    String? = nil
    public var public_url :    String? = nil
    public init (resource_id: String?, type: String?, _embedded: FileResourceList?, name: String, path: String, file: String?, preview: String?, created: String, modified: String, size: Int64?, mime_type: String?, media_type: String?, md5: String?, revision: Int64?, public_key: String?, public_url: String?) {
        self.resource_id = resource_id
        self.type = type
        self._embedded = _embedded
        self.name = name
        self.path = path
        self.file = file
        self.preview = preview
        self.created = created
        self.modified = modified
        self.size = size
        self.mime_type = mime_type
        self.media_type = media_type
        self.md5 = md5
        self.revision = revision
        self.public_key = public_key
        self.public_url = public_url
    }
}

public typealias PublicResourceList = FileResourceList
public typealias PublicResource     = FileResource

struct Link: Codable {
    let href :      String
    let method :    String
    var templated : Bool? = nil
}
