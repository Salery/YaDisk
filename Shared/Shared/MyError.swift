//
//  MyError.swift
//  Shared
//
//  Created by Devel on 09.07.2022.
//

import Foundation

public protocol LocalizedErrorStructProtocol: LocalizedError, RawRepresentable where RawValue == Int {
    var errorHeader:        String      { get }
    var errorStruct:        ErrorStruct { get }
    var successCodes:      [Int]        { get }
    var errorsToShowCache: [Int]        { get }
    var errorToLogoff:      Int         { get }
}

extension LocalizedErrorStructProtocol {
    public var errorStruct: ErrorStruct {
        ErrorStruct(title: self.errorHeader,
                    message: self.localizedDescription,
                    actionHandler: nil, completion: nil)
    }
}

public enum MyError: Int, Error {
    case noConnectionToDisk = 0,    invalidAuthResponce,    noConnectionToAuth,
         tokenDidntSave,            tokenDidntUpdate,       cantAuthWithToken = 401,
         invalidDiskResponce = 400
}
extension MyError: LocalizedErrorStructProtocol {
    public var successCodes:      [Int] { [200] }
    public var errorToLogoff:      Int  { 401 }
    public var errorsToShowCache: [Int] { [0, 400] }
    public var errorDescription:   String? {
        switch self {
        case .invalidAuthResponce:
            return NSLocalizedString("Invalid responce from the claud server. Try again!",
                                     comment: "Error.invalidAuthResponce")
        case .tokenDidntSave:
            return NSLocalizedString("Auth token didn't save",
                                     comment: "Error.tokenDidntSave")
        case .noConnectionToAuth:
            return NSLocalizedString("No connection to the auth server",
                                     comment: "Error.noConnectionToAuth")
        case .tokenDidntUpdate:
            return NSLocalizedString("Auth token didn't update",
                                     comment: "Error.tokenDidntUpdate")
        case .noConnectionToDisk:
            return NSLocalizedString("No connection to the cloud server.",
                                     comment: "Error.noConnectionToDisk")
            // Нет соединения с сервером.Попробуйте снова
        case .cantAuthWithToken:
            return NSLocalizedString("Authorisation failed! New authorisation required. App data cleared.",
                                     comment: "Error.cantAuthWithToken")
            // Ошибка авторизации! Необходимо авторизоваться заново. Данные приложения очищены.
        case .invalidDiskResponce:
            return NSLocalizedString("Invalid responce from the claud server. Try again!",
                                     comment: "Error.invalidDiskResponce")
            // Неверный ответ от сервера Диска. Попробуйте снова.
        }
    }
    
    public var errorHeader: String {
        switch self {
        default:
            return NSLocalizedString("Error", comment: "Error.Title")
            // Ошибка
        }
    }
}
