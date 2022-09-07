//
//  YaAPI.swift
//  YaAPI
//
//  Created by Devel on 06.07.2022.
//
import UIKit
import Shared

final public class Auth {
    
    public static var authorized: Box<Bool?> = Box(value: nil)
    public static var responceAuthState: String?
    public static var clearTokenNeeded: Bool {
        get { UserDefaults.standard.bool(forKey: "clearTokenNeeded") }
        set { UserDefaults.standard.set(newValue, forKey: "clearTokenNeeded") }
    }
    public static var firstAuth: Bool {
        get {
            if let value = UserDefaults.standard.value(forKey: "firstAuth") as? Bool {
                return value
            } else {
                self.firstAuth = true
                return true
            }
        }
        set { UserDefaults.standard.set(newValue, forKey: "firstAuth") }
    }
    public var state = UUID().uuidString // Random String for auth request
    
    public init () {}
    
    public func checkAuthorization () {
        revokeOldTokens()
        if !Auth.firstAuth && checkUserKey() {
            checkAuthWithUserKey()
        } else if Auth.firstAuth && checkUserKey() {
            // clear token because its from previous app installation
            clearUserKey()
            Auth.authorized.value = false
        } else {
            Auth.authorized.value = false
        }
    }
    
    func checkUserKey () -> Bool {
        guard let dates = KeyChainService().getUserKeyDates() else { return false }
        let dateCreated = dates.created
        let dateExpired = dates.expired
        
        if dateExpired <= Date() || (!YaConst.authWithCode
                                     && YaConst.updateUserKeyAfter3Month
                                     && dateCreated + TimeInterval(7776000) <= Date()) {
            // Clear all user data due to expired or needed to refresh token
            logOff()
            return false
        }
        if YaConst.authWithCode
            && dateCreated + TimeInterval(7776000) <= Date() {
            updateAuthToken ()
        }
        return true
    }
    
    private var revokedTokens: [UUID] {
        get { UserDefaults.standard.array(forKey: "revokedTokens") as? [UUID] ?? [UUID]() }
        set { UserDefaults.standard.set(newValue, forKey: "revokedTokens") }
    }
    
    private func revokedTokensAppend (_ uuid: UUID) {
        var arr = revokedTokens
        arr.append(uuid)
        revokedTokens = arr
    }
    
    private func updateAuthToken () {
        guard let refresh_token = KeyChainService().getUserKey(type: .refresh_token)
        else { ErrorStruct.myError.value = MyError.tokenDidntSave; return }
        YaAPI().updateUserToken(refresh_token: refresh_token) { token, httpStatusCode in
            self.storeTokens(token: token, httpStatusCode: httpStatusCode, isUpdating: true)
        }
    }
    
    private func checkAuthWithUserKey () {
        YaFileManager().getUserInfo { userInfo, error in
            guard userInfo != nil else {
                if error == .invalidDiskResponce {
                    ErrorStruct.myError.value = .invalidDiskResponce
                } else if error == .cantAuthWithToken {}
                else {
                    ErrorStruct.myError.value = .noConnectionToDisk
                }
                return
            }
            Auth.authorized.value = true
            YaAPI.driveServerConnectionStatus.value = true
            Auth.firstAuth = false
        }
    }
    
    private func checkResponceCode (httpStatusCode: Int?) {
        if httpStatusCode != nil
            && httpStatusCode != 400
            && httpStatusCode != 401 {
            YaAPI.oauthServerConnectionStatus.value = false
            ErrorStruct.myError.value = MyError.noConnectionToAuth
        } else {
            ErrorStruct.myError.value = MyError.invalidAuthResponce
        }
    }
    
    private func storeTokens (token: UserToken?, httpStatusCode: Int?, isUpdating: Bool = false) {
        guard let token = token else {
            checkResponceCode(httpStatusCode: httpStatusCode)
            return
        }
        YaAPI.oauthServerConnectionStatus.value = true
        let keyChainService = KeyChainService()
        if isUpdating && !keyChainService.deleteTokens() {
            ErrorStruct.myError.value = MyError.tokenDidntUpdate
        }
        
        if !keyChainService.addToken     (type: TokenType.bearer,
                                            token: token.access_token,
                                            expired: token.expires_in.description) {
            ErrorStruct.myError.value = MyError.tokenDidntSave
            return
        }
        if YaConst.authWithCode
            && !keyChainService.addToken (type: TokenType.refresh_token,
                                            token: token.refresh_token,
                                            expired: token.expires_in.description) {
            clearUserKey()
            ErrorStruct.myError.value = MyError.tokenDidntSave
            return
        }
    }
    
    private func resetVariables () {
        Auth.authorized.value = nil
        YaAPI.driveServerConnectionStatus.value = true
        YaAPI.oauthServerConnectionStatus.value = true
        ErrorStruct.myError.value = nil
    }
    
    private func clearUserKey () {
        /* There is no need to handle deletion errors from the keychain here,
         the application will try to retry this after the token addition fails. */
        let keyChainService = KeyChainService()
        guard let token = keyChainService.getUserKey() else { return }
        guard let moveResult = keyChainService.moveTokenToRevoked()
        else { print("Token didn't moved to revoked"); return }
        let revokedID = moveResult.movedTo
        if !moveResult.refreshTokenDeleted { print("Refresh token didn't delete") }
        YaAPI().revokeUserToken(token: token) { result, httpStatusCode in
            guard result == true
            else {
                self.revokedTokensAppend(revokedID)  // Revoke next time
                self.checkResponceCode(httpStatusCode: httpStatusCode)
                return
            }
            YaAPI.oauthServerConnectionStatus.value = true
            if !keyChainService.deleteTokens(revokedID: revokedID) {
                print("Revoked token didn't cleared from keychain")
            }
        }
    }
    
    private func revokeOldTokens () {  // every auth
        guard !revokedTokens.isEmpty else { return }
        var newArr = [UUID]()
        let keyChainService = KeyChainService()
        for uuid in revokedTokens {
            guard let token = keyChainService.getUserKey(revokedID: uuid)
            else { newArr.append(uuid); break }
            YaAPI().revokeUserToken(token: token) { result, httpStatusCode in
                guard result == true
                        || httpStatusCode == 400
                        || httpStatusCode == 401
                else { newArr.append(uuid); return }
                if !keyChainService.deleteTokens(revokedID: uuid) {
                    newArr.append(uuid)
                    print("Revoked token didn't cleared from keychain")
                }
            }
        }
        revokedTokens = newArr
    }
    
    // MARK: LogOff
    public func logOff (byUser: Bool = false) {
        resetVariables()
        clearUserKey()
//        CoreDataManager.shared.clearDatabase()
        CoreDataManager.shared.resetAllCoreData()
        URLCache.shared.removeAllCachedResponses()
        YaFileManager().clearAppFolder()
        if !byUser { // invalid user token
            ErrorStruct.myError.value = .cantAuthWithToken
        }
    }
    
    public func getURLForAuth () -> URL? {
        guard let deviceID = UIDevice.current.identifierForVendor?.uuidString,
              let deviceName = UIDevice.current.name.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
        else { return nil }
        let oauthURL = URL(
            string: (YaConst.authWithCode ? YaConst.oauthWithCode : YaConst.oauthWithURL)
            + "&device_id=\(deviceID)"
            + "&device_name=\(deviceName)"
            + "&state=\(state)"
        )
        return oauthURL
    }
    
    public func checkAuthResponceNLogin (url: URL, completion: @escaping (Bool)->Void) {
        DispatchQueue.main.async {
            guard let url = URL(string: url.absoluteString.replacingOccurrences(of: "#", with: "?")),
                  let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
                  let params = components.queryItems?.reduce([String:String](), {
                      (result, item) -> [String:String] in
                      var result = result
                      result[item.name] = item.value
                      return result
                  }),
                  let state = params["state"],
                  state == Auth.responceAuthState
            else {
                ErrorStruct.myError.value = MyError.invalidAuthResponce
                completion(false)
                return
            }
            if YaConst.authWithCode {
                guard let code = params["code"] else {
                    ErrorStruct.myError.value = MyError.invalidAuthResponce
                    completion(false)
                    return
                }
                YaAPI().getUserToken(code: code) { token, httpStatusCode in
                    self.storeTokens(token: token, httpStatusCode: httpStatusCode)
                    self.checkAuthWithUserKey()
                }
            } else {
                guard let token = params["access_token"],
                      let expires_in = params["expires_in"] else {
                          ErrorStruct.myError.value = MyError.invalidAuthResponce
                          completion(false)
                          return
                      }
                if !KeyChainService().addToken (type: TokenType.bearer, token: token, expired: expires_in) {
                    ErrorStruct.myError.value = MyError.tokenDidntSave
                    completion(false)
                    return
                }
            }
            completion(true)
        }
    }
}
