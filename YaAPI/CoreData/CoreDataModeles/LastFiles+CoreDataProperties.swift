//
//  LastFiles+CoreDataProperties.swift
//  YaAPI
//
//  Created by Devel on 10.08.2022.
//
//

import Foundation
import CoreData


extension LastFiles {

    @nonobjc public class func fetchRequest(limit: Int? = nil, offset: Int = 0, predicate: NSPredicate? = nil) -> NSFetchRequest<LastFiles> {
        let rqst = NSFetchRequest<LastFiles>(entityName: "LastFiles")
        let limit: Int = limit ?? YaConst.lastFilesPageLimit
        rqst.predicate = predicate
        rqst.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        rqst.fetchLimit  = limit
        rqst.fetchOffset = offset
        return rqst
    }
    @nonobjc public class func fetchRequestCount() -> NSFetchRequest<LastFiles> {
        let rqst = NSFetchRequest<LastFiles>(entityName: "LastFiles")
        rqst.resultType = .countResultType
        return rqst
    }
    
    @NSManaged public var sortOrder: Int32
}
