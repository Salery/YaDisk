//
//  AllFiles+CoreDataProperties.swift
//  YaAPI
//
//  Created by Devel on 10.08.2022.
//
//

import Foundation
import CoreData

extension AllFiles {
    @nonobjc public class func fetchRequest(predicate: NSPredicate? = nil) -> NSFetchRequest<AllFiles> {
        let rqst = NSFetchRequest<AllFiles>(entityName: "AllFiles")
        rqst.predicate = predicate
        rqst.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return rqst
    }
    @nonobjc public class func fetchRequestCount() -> NSFetchRequest<AllFiles> {
        let rqst = NSFetchRequest<AllFiles>(entityName: "AllFiles")
        rqst.resultType = .countResultType
        return rqst
    }

    @NSManaged public var stale: Bool
    @NSManaged public var public_key: String?
    @NSManaged public var embedded: List?
    @NSManaged public var item: List?

}
