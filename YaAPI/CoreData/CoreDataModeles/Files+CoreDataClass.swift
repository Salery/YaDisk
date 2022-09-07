//
//  Files+CoreDataClass.swift
//  YaAPI
//
//  Created by Devel on 10.08.2022.
//
//

import Foundation
import CoreData


public class Files: NSManagedObject {
    @NSManaged public var created:     Date
    @NSManaged public var file:        String?
    @NSManaged public var md5:         String?
    @NSManaged public var mime_type:   String?
    @NSManaged public var media_type:  String?
    @NSManaged public var modified:    Date
    @NSManaged public var name:        String
    @NSManaged public var path:        String
    @NSManaged public var preview:     String?
    @NSManaged public var resource_id: String?
    @NSManaged public var revision:    Int64
    @NSManaged public var size:        Int64
    @NSManaged public var type:        String?
    @NSManaged public var public_url:  String?
}
