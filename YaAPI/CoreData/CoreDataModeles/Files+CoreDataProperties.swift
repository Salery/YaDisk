//
//  Files+CoreDataProperties.swift
//  YaAPI
//
//  Created by Devel on 10.08.2022.
//
//

import Foundation
import CoreData


extension Files {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Files> {
        return NSFetchRequest<Files>(entityName: "Files")
    }
    @nonobjc public class func fetchRequestCount() -> NSFetchRequest<Files> {
        let rqst = NSFetchRequest<Files>(entityName: "Files")
        rqst.resultType = .countResultType
        return rqst
    }
}

extension Files : Identifiable {

}
