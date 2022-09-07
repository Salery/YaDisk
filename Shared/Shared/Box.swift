//
//  Shared.swift
//  Shared
//
//  Created by Devel on 01.07.2022.
//

import Foundation

final public class Box<T> {
    public typealias Listener = (T) -> Void
    private var listener: Listener?

    public var value: T {
        didSet {
            listener?(value)
        }
    }

    public func bind (_ listener: Listener?) {
        self.listener = listener
    }
    public func bindAndFire (_ listener: Listener?) {
        self.listener = listener
        listener?(value)
    }
    public func unBind () {
        self.listener = nil
    }

    public init (value: T) {
        self.value = value
    }
}
