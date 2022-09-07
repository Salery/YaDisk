//
//  KeyChainService.swift
//  YaAPI
//
//  Created by Devel on 13.07.2022.
//

import Foundation

final class KeyChainService {
    private let server = "YaDiskServer"
    private let serverForRevoked = "YaDiskRevoked"
    
    func addToken (type: TokenType, token: String, expired: String) -> Bool {
        let dateCreated = Date().timeIntervalSinceReferenceDate.description
        let dateExpire = (Date() + TimeInterval((Int(expired) ?? 31536000) - 60))
            .timeIntervalSinceReferenceDate.description
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrAccount as String:      type.rawValue,
                                    kSecAttrServer as String:       server,
                                    kSecAttrDescription as String:  dateCreated,
                                    kSecAttrComment as String:      dateExpire,
                                    kSecValueData as String:        token.data(using: String.Encoding.utf8) ?? ""]
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess { return true }
        else { return false }
    }
    
    func readStoredUserKey (type: TokenType = .bearer, revokedID: UUID? = nil) -> [String : Any]? {
        var server = server
        var account = type.rawValue
        if let revokedID = revokedID?.uuidString {
            server = serverForRevoked
            account = revokedID
        }
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrAccount as String: account,
                                    kSecAttrServer as String:  server,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnAttributes as String: true,
                                    kSecReturnData as String: true]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let existingItem = item as? [String : Any]
        else {
            return nil
        }
        return existingItem
    }
    
    func getUserKeyDates () -> (created: Date, expired: Date)? {
        guard let existingItem = readStoredUserKey(),
              let _ = existingItem[kSecValueData as String] as? Data,
              let created = Double(existingItem[kSecAttrDescription as String] as? String ?? ""),
              let expired = Double(existingItem[kSecAttrComment as String] as? String ?? "")
        else { return nil }
        return (created: Date(timeIntervalSinceReferenceDate: TimeInterval(created)),
                expired: Date(timeIntervalSinceReferenceDate: TimeInterval(expired)))
    }
    
    func deleteTokens (revokedID: UUID? = nil) -> Bool {
        var server = server
        var query: [String: Any] = [kSecClass as String: kSecClassInternetPassword]
        if let revokedID = revokedID?.uuidString {
            server = serverForRevoked
            query[kSecAttrAccount as String] = revokedID
        }
        query[kSecAttrServer as String] = server
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound { return true }
        return false
    }
    
    func moveTokenToRevoked () -> (movedTo: UUID, refreshTokenDeleted: Bool)? {
        let uuid = UUID()
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrAccount as String: TokenType.bearer.rawValue,
                                    kSecAttrServer as String:  server]
        let attributes: [String: Any] = [kSecAttrAccount as String: uuid.uuidString,
                                         kSecAttrServer as String:  serverForRevoked]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound {
            return (uuid, deleteTokens())
        }
        return nil
    }
    
    func getUserKey (type: TokenType = .bearer, revokedID: UUID? = nil) -> String? {
        // If revokedID exists returns revoked token, else - current token with selected type
        guard let existingItem = readStoredUserKey (type: type, revokedID: revokedID),
              let tokenData = existingItem[kSecValueData as String] as? Data,
              let token = String(data: tokenData, encoding: String.Encoding.utf8)
        else { return nil }
        return token
    }
}
