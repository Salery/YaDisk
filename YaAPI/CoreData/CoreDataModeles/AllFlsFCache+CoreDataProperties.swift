//
//  AllFlsFCache+CoreDataProperties.swift
//  YaAPI
//
//  Created by Devel on 11.08.2022.
//
//

import Foundation
import CoreData


extension AllFlsFCache {

    @nonobjc public class func fetchRequest(predicate: NSPredicate? = nil) -> NSFetchRequest<AllFlsFCache> {
        let rqst = NSFetchRequest<AllFlsFCache>(entityName: "AllFlsFCache")
        rqst.sortDescriptors = [NSSortDescriptor(key: "cacheFileName", ascending: true)]
        rqst.predicate = predicate
        return rqst
    }
    @nonobjc public class func fetchRequestCount() -> NSFetchRequest<AllFlsFCache> {
        let rqst = NSFetchRequest<AllFlsFCache>(entityName: "AllFlsFCache")
        rqst.resultType = .countResultType
        return rqst
    }

    @NSManaged public var resource_id: String?
    @NSManaged public var md5: String?
    @NSManaged public var path: String
    @NSManaged public var cacheFileName: String
    @NSManaged public var revision: Int64

}

extension AllFlsFCache : Identifiable {

}
