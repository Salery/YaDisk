//
//  List+CoreDataProperties.swift
//  YaAPI
//
//  Created by Devel on 10.08.2022.
//
//

import Foundation
import CoreData

extension List {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<List> {
        let rqst = NSFetchRequest<List>(entityName: "List")
        rqst.sortDescriptors = [NSSortDescriptor(key: "path", ascending: true)]
        return rqst
    }
    @nonobjc public class func fetchRequestCount() -> NSFetchRequest<List> {
        let rqst = NSFetchRequest<List>(entityName: "List")
        rqst.resultType = .countResultType
        return rqst
    }
}

// MARK: Generated accessors for items
extension List {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: AllFiles)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: AllFiles)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)

}

extension List : Identifiable {

}
