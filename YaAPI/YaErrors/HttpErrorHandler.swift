//
//  YaErrorHandler.swift
//  YaAPI
//
//  Created by Devel on 20.07.2022.
//

import Foundation
import Shared

public final class HttpErrorHandler {
    public init () {}
    
    public func checkErrorCode<T: LocalizedErrorStructProtocol> (httpStatusCode: Int?, errorType: T.Type) -> T? {
        if httpStatusCode == 200 { return nil }         // Default Ok code, but nil result
        let httpStatusCode: Int = httpStatusCode ?? 0   // Nil error & nil result
        let out = T.init(rawValue: httpStatusCode) ?? T.init(rawValue: 0) // Unknown, etc -1 = 0 (default)
        if out != nil
            && out!.successCodes.contains(httpStatusCode) { return nil } // Another Ok code, but nil result
        if out != nil && out!.errorsToShowCache.contains(out?.rawValue ?? 0) {
            YaAPI.driveServerConnectionStatus.value = false
        } else {
            YaAPI.driveServerConnectionStatus.value = true
        }
        if httpStatusCode == out?.errorToLogoff {
            Auth().logOff()
        }
        return out
    }
}
