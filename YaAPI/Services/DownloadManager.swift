//
//  DownloadManager.swift
//  YaAPI
//
//  Created by Devel on 25.07.2022.
//

import Foundation

public final class DownloadManager {
    private var sessions = [String : Progress]()
    
    public static let shared = DownloadManager()
    
    public func newSession (id: String, progress: Progress) {
        sessions[id] = progress
    }
    
    public func getSession (id: String) -> Progress? {
        return sessions[id]
    }
    
    public func removeSession (id: String) {
        sessions[id] = nil
    }
    
    public func cleanAllSessions (id: String) {
        sessions = [:]
    }
}
