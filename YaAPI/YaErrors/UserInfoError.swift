//
//  UserInfoError.swift
//  YaAPI
//
//  Created by Devel on 17.08.2022.
//

import Foundation
import Shared

public enum UserInfoError: Int, Error {
    case invalidDiskResponce    = 400, cantAuthWithToken  = 401, deniedModify              = 403,
         resourceNotFound       = 404, presentationFailed = 406, uploadNotAvailable        = 413,
         downloadingUnavailable = 423, tooManyRequests    = 429, temporarilyUnavailable    = 503,
         noConnectionToDisk     = 0
}

extension UserInfoError: LocalizedErrorStructProtocol {
    public var errorToLogoff:      Int  { 401 }
    public var successCodes:      [Int] { [200] }
    public var errorsToShowCache: [Int] { [0, 400, 423, 429, 503] }
    public var errorDescription: String? {
        switch self {
        case .invalidDiskResponce:
            return NSLocalizedString("Invalid responce from the claud server. Try again!",
                                     comment: "Error.invalidDiskResponce")
            // Неверный ответ от сервера Диска. Попробуйте обновить список файлов!
        case .cantAuthWithToken:
            return NSLocalizedString("Authorisation failed! New authorisation required. App data cleared.",
                                     comment: "Error.cantAuthWithToken")
            // Ошибка авторизации! Необходимо авторизоваться заново. Данные приложения очищены.
        case .deniedModify:
            return NSLocalizedString("Insufficient rights to modify data in the shared folder.",
                                     comment: "Error.deniedModify")
            // Не достаточно прав для изменения данных в общей папке.
        case .resourceNotFound:
            return NSLocalizedString("The requested resource could not be found.",
                                     comment: "Error.resourceNotFound")
            // Не удалось найти запрошенный ресурс.
        case .presentationFailed:
            return NSLocalizedString("The resource cannot be represented in the requested format.",
                                     comment: "Error.presentationFailed")
            // Ресурс не может быть представлен в запрошенном формате.
        case .uploadNotAvailable:
            return NSLocalizedString("File upload is not available. The file is too large.",
                                     comment: "Error.uploadNotAvailable")
            // Загрузка файла недоступна. Файл слишком большой.
        case .downloadingUnavailable:
            return NSLocalizedString("Downloading files is not available, you can only view and download. You have reached the file upload limit.",
                                     comment: "Error.downloadingUnavailable")
            // Загрузка файлов недоступна, можно только просматривать и скачивать. Вы достигли ограничения по загрузке файлов.
        case .tooManyRequests:
            return NSLocalizedString("Too many requests.",
                                     comment: "Error.tooManyRequests")
            // Слишком много запросов.
        case .temporarilyUnavailable:
            return NSLocalizedString("Service is temporarily unavailable",
                                     comment: "Error.temporarilyUnavailable")
            // Сервис временно недоступен.
        case .noConnectionToDisk:
            return NSLocalizedString("No connection to the cloud server.",
                                     comment: "Error.noConnectionToDisk")
            // Нет соединения с сервером Диска
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
