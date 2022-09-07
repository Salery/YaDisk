//
//  PublicFiles+CoreDataProperties.swift
//  YaAPI
//
//  Created by Devel on 18.08.2022.
//
//

import Foundation
import CoreData


extension PublicFiles {

    @nonobjc public class func fetchRequest(limit: Int? = nil, offset: Int = 0, predicate: NSPredicate? = nil) -> NSFetchRequest<PublicFiles> {
        let rqst = NSFetchRequest<PublicFiles>(entityName: "PublicFiles")
        let limit: Int = limit ?? YaConst.publicFilesPageLimit
        rqst.predicate = predicate
        rqst.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        rqst.fetchLimit  = limit
        rqst.fetchOffset = offset
        return rqst
    }
    @nonobjc public class func fetchRequestCount() -> NSFetchRequest<PublicFiles> {
        let rqst = NSFetchRequest<PublicFiles>(entityName: "PublicFiles")
        rqst.resultType = .countResultType
        return rqst
    }

    @NSManaged public var public_key: String
    @NSManaged public var sortOrder: Int32

}
