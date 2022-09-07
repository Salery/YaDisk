//
//  Const.swift
//  YaAPI
//
//  Created by Devel on 06.07.2022.
//

import UIKit

public enum YaConst {
    // authWithCode, true - with post request after receiving the code, false - receiving an user key from URL
    static let authWithCode = true
    // updateUserKeyAfter3Month, true - For clearing token every 3 month, only if receiving an user key from URL (without refresh_token), ignoring if used authWithCode
    static let updateUserKeyAfter3Month = true
    static let host = "https://cloud-api.yandex.net/v1/"
    static let disk = host + "disk/"
    static let trash = disk + "trash/"
    static let resources = disk + "resources/"
    static let move = resources + "move/"
    static let publish   = resources + "publish/"
    static let unpublish = resources + "unpublish/"
    static let trashResources = trash + "resources/"
    static let memotype = "application/json"
    // Temp registration
    static let regID = "326d6a3a19db49b1bcce5b743ba0d546"
    static let regPW = "04f971953c6d4ea9804b066e27abff08"
    static let callbackURL = "YaDisk://auth"
    // oauth
    static let oauthServer = "https://oauth.yandex.ru/"
    static let oauthWithURL  = oauthServer + "authorize?response_type=token&client_id=" + regID
    static let oauthWithCode = oauthServer + "authorize?response_type=code&client_id="  + regID
    static let oauthToken = oauthServer + "token"
    static let oauthRevokeToken = oauthServer + "revoke_token"
    // disk
    public static let previewDir = "preview"
    public static let filesDir   = "files"
    //LastFiles
    public static let lastFilesLimit = 50
    public static let lastFilesPageLimit = 20
    public static let lastFilesPreviewWidth  = 25
    public static let lastFilesPreviewHeight = 22
    static let lastFilesPreviewSize = "\(lastFilesPreviewWidth)x\(lastFilesPreviewHeight)"
    static let lastFilesPreviewCrop = "true" // String
    static let diskLastFiles = resources + "last-uploaded/"
    //AllFiles
    public static let allFilesPageLimit = 20
    public static let allFilesPreviewWidth  = 25
    public static let allFilesPreviewHeight = 22
    static let allFilesPreviewSize = "\(lastFilesPreviewWidth)x\(lastFilesPreviewHeight)"
    static let allFilesPreviewCrop = "true" // String
    //PublicFiles
    public static let publicFilesPageLimit = 20
    public static let publicFilesPreviewWidth  = 25
    public static let publicFilesPreviewHeight = 22
    static let publicFilesPreviewSize = "\(lastFilesPreviewWidth)x\(lastFilesPreviewHeight)"
    static let publicFilesPreviewCrop = "true" // String
    static let diskPublicFiles = resources + "public/"
    // Timeout
    static let requestTimeout: TimeInterval = 10
}

enum TokenType: String {
    case bearer, refresh_token
}

public enum MimeType: String {
    case unknown, dir, text, image, video, audio, pdf
    public var icon: UIImage? {
        switch self {
        case .unknown:
            return UIImage(systemName: "questionmark.circle")
        case .dir:
            return UIImage(systemName: "folder")
        case .text:
            return UIImage(systemName: "doc.plaintext")
        case .image:
            return UIImage(systemName: "photo")
        case .video:
            return UIImage(systemName: "video")
        case .audio:
            return UIImage(systemName: "music.note.list")
        case .pdf:
            return UIImage(systemName: "doc.richtext")
        }
    }
}
