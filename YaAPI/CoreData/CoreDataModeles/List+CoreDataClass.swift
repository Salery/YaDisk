//
//  List+CoreDataClass.swift
//  YaAPI
//
//  Created by Devel on 10.08.2022.
//
//

import Foundation
import CoreData


public class List: NSManagedObject {
    @NSManaged public var limit:  Int64
    @NSManaged public var offset: Int64
    @NSManaged public var path:   String
    @NSManaged public var sort:   String?
    @NSManaged public var total:  Int64
    @NSManaged public var type:   String?
    @NSManaged public var items:  NSSet?
    @NSManaged public var host:   AllFiles?
}
