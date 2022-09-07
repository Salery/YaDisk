//
//  ErrorBox.swift
//  Shared
//
//  Created by Devel on 09.07.2022.
//

import UIKit

public struct ErrorStruct {
    public static var myError: Box<MyError?> = Box(value: nil)
    
    public let title: String
    public let message: String
    public let decisionNeeded: Bool
    public let actionHandler: ((UIAlertAction) -> Void)?
    public let completion: (() -> Void)?
    
    public init(title: String, message: String, decisionNeeded: Bool = false, actionHandler: ((UIAlertAction) -> Void)?, completion: (() -> Void)?) {
        self.title = title
        self.message = message
        self.decisionNeeded = decisionNeeded
        self.actionHandler = actionHandler
        self.completion = completion
    }
    
    public static let testError = ErrorStruct(title: "Test error", message: "This is test message for the test error", actionHandler: { action in
        print("Test error action!")
    }) {
        print("Test error completed!")
    }
}

public typealias ErrorBox = Box<ErrorStruct?>
