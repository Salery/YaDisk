//
//  CoreDataFunctrions.swift
//  YaDisk
//
//  Created by Devel on 22.07.2022.
//

import Foundation
import CoreData
import UIKit

public final class CoreDataManager {
    public static let shared = CoreDataManager()
    // MARK: - Core Data stack
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let modelURL = Bundle(for: CoreDataManager.self).url(forResource: "DataModel", withExtension: "momd")
        let objectModel = NSManagedObjectModel(contentsOf: modelURL!)
        let container = NSPersistentContainer(name: "DataModel", managedObjectModel: objectModel!)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    private lazy var context = persistentContainer.viewContext
    
    var cacheIsEnabled: Bool {
        get { context.stalenessInterval != 0 }
        set { context.stalenessInterval = newValue ? -1 : 0
            context.refreshAllObjects()
        }
    }
    
    // MARK: - Core Data Saving support
    
    public func saveContext () {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // LastFiles
    func setLastFiles (_ lastFiles: [FileResource]) {
        compareDataWithStore(lastFiles)
        deleteAllEntityData(entityName: "LastFiles")
        guard !lastFiles.isEmpty,
              let entity = NSEntityDescription.entity(forEntityName: "LastFiles", in: context)
        else { print("Error while saving LastFiles to CoreData"); return }
        let formatter = ISO8601DateFormatter()
        var n: Int32 = 0
        lastFiles.forEach { file in
            let lastFile = LastFiles(entity: entity, insertInto: context)
            lastFile.resource_id = file.resource_id
            lastFile.type = file.type
            lastFile.name = file.name
            lastFile.path = file.path
            lastFile.file = file.file
            lastFile.preview = file.preview
            lastFile.created  = formatter.date(from: file.created)  ?? Date()
            lastFile.modified = formatter.date(from: file.modified) ?? Date()
            lastFile.size = file.size ?? 0
            lastFile.mime_type = file.mime_type
            lastFile.media_type = file.media_type
            lastFile.md5 = file.md5
            lastFile.revision = file.revision ?? 0
            lastFile.public_url = file.public_url
            lastFile.sortOrder  = n
            n += 1
        }
        do {
            try context.save()
        }
        catch { print("Saving LastFiles to CoreData: ", error.localizedDescription) }
    }
    // AllFiles
    func setAllFiles (_ fileResource: FileResource, offset: Int = 0) {
        guard let entity = NSEntityDescription.entity(forEntityName: "AllFiles", in: context),
              let listEntity = NSEntityDescription.entity(forEntityName: "List", in: context)
        else { print("Error while saving AllFiles to CoreData"); return }
        let formatter = ISO8601DateFormatter()
        let allFile: AllFiles = getAllFilesObject(
            resource_id: fileResource.resource_id, md5: nil, path: fileResource.path
        ) ?? AllFiles(entity: entity, insertInto: context)
        let items = allFile.embedded?.items as? Set<AllFiles> ?? []
        if offset == 0 {
            allFile.resource_id = fileResource.resource_id
            allFile.name        = fileResource.name
            allFile.path        = fileResource.path
            allFile.type        = fileResource.type
            allFile.created     = formatter.date(from: fileResource.created)  ?? Date()
            allFile.modified    = formatter.date(from: fileResource.modified) ?? Date()
            allFile.revision    = fileResource.revision ?? 0
            allFile.public_url  = fileResource.public_url
            allFile.public_key  = fileResource.public_key
            // the item field is already actual or nil if it is "/"
            let embedded = allFile.embedded ?? List(entity: listEntity, insertInto: context)
            embedded.limit  = fileResource._embedded?.limit  ?? Int64(YaConst.allFilesPageLimit)
            embedded.offset = fileResource._embedded?.offset ?? 0
            embedded.path   = fileResource._embedded?.path   ?? ""
            embedded.sort   = fileResource._embedded?.sort
            embedded.total  = fileResource._embedded?.total  ?? 0
            embedded.host   = allFile
            allFile.embedded = embedded
            // delete files, disactivate folders
            items.forEach({ item in
                if item.type == "dir" { item.stale = true }
                else {
                    allFile.embedded?.removeFromItems(item)
                    context.delete(item)
                }
            })
        }
        // Add items
        // newFile - an exists dir or a new file
        fileResource._embedded?.items.forEach { file in
            let newFile: AllFiles = (
                file.type == "dir" ?
                items.first(where: {
                 if let resourceId = file.resource_id {return $0.resource_id == resourceId}
                    else { return $0.path == file.path }
                })     // end first
                : nil  // nil - if its not a folder
            ) ?? AllFiles(entity: entity, insertInto: context)
            newFile.resource_id = file.resource_id
            newFile.type        = file.type
            newFile.name        = file.name
            newFile.path        = file.path
            newFile.file        = file.file
            newFile.preview     = file.preview
            newFile.created     = formatter.date(from: file.created)  ?? Date()
            newFile.modified    = formatter.date(from: file.modified) ?? Date()
            newFile.size        = file.size ?? 0
            newFile.mime_type   = file.mime_type
            newFile.media_type  = file.media_type
            newFile.md5         = file.md5
            newFile.revision    = file.revision ?? 0
            newFile.public_url  = file.public_url
            newFile.stale       = false
            newFile.item        = allFile.embedded
            allFile.embedded?.addToItems(newFile)
        }
        // Delete stale files after loading full folder from api
        if let count = fileResource._embedded?.items.count,
           let total = allFile.embedded?.total,
            count + offset >= total {
            (allFile.embedded?.items as? Set<AllFiles>)?.forEach({ item in
                if item.stale == true {
                    allFile.embedded?.removeFromItems(item)
                    context.delete(item)
                }
            })
        }
        do {
            try context.save()
        }
        catch { print("Saving AllFiles to CoreData: ", error.localizedDescription) }
    }
    
    // PublicFiles
    func setPublicFiles (_ publicFiles: [PublicResource], offset: Int = 0) {
        if offset == 0 { deleteAllEntityData(entityName: "PublicFiles") }
        guard !publicFiles.isEmpty,
              let entity = NSEntityDescription.entity(forEntityName: "PublicFiles", in: context)
        else { print("Error while saving PublicFiles to CoreData"); return }
        let formatter = ISO8601DateFormatter()
        var n = Int32(offset)
        publicFiles.forEach { file in
            let publicFile = PublicFiles(entity: entity, insertInto: context)
            publicFile.resource_id = file.resource_id
            publicFile.type = file.type
            publicFile.name = file.name
            publicFile.path = file.path
            publicFile.file = file.file
            publicFile.preview = file.preview
            publicFile.created  = formatter.date(from: file.created)  ?? Date()
            publicFile.modified = formatter.date(from: file.modified) ?? Date()
            publicFile.size = file.size ?? 0
            publicFile.mime_type = file.mime_type
            publicFile.media_type = file.media_type
            publicFile.md5 = file.md5
            publicFile.revision = file.revision ?? 0
            publicFile.public_url = file.public_url
            publicFile.public_key = file.public_key ?? ""
            publicFile.sortOrder  = n
            n += 1
        }
        do {
            try context.save()
        }
        catch { print("Saving LastFiles to CoreData: ", error.localizedDescription) }
    }
    
    // AllFlsFCache
    public func setAllFlsFCache (resource_id: String?, md5: String?,
                          path: String, cacheFileName: String,
                          revision: Int64) {
        guard resource_id != nil || md5 != nil,
              let entity = NSEntityDescription.entity(
                forEntityName: "AllFlsFCache",in: context)
        else { print("Error while saving AllFlsFCache to CoreData"); return }
        let allFlsFCache = AllFlsFCache(entity: entity, insertInto: context)
        allFlsFCache.resource_id   = resource_id
        allFlsFCache.md5           = md5
        allFlsFCache.path          = path
        allFlsFCache.cacheFileName = cacheFileName
        allFlsFCache.revision      = revision
        do {
            try context.save()
        }
        catch { print("Saving AllFlsFCache to CoreData: ", error.localizedDescription) }
    }
    
    // MARK: Get data
    // LastFiles
    func getLastFiles (limit: Int? = nil, offset: Int = 0, predicate: NSPredicate? = nil) -> [FileResource] {
        let resultController = NSFetchedResultsController<LastFiles>(
            fetchRequest: LastFiles.fetchRequest(limit: limit, offset: offset, predicate: predicate),
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil)
        do {
            try resultController.performFetch()
        }
        catch { print("Perform fetch failed: ", error.localizedDescription) }
        guard let result = resultController.fetchedObjects, !result.isEmpty else { return [] }
        let formatter = ISO8601DateFormatter()
        let out: [FileResource] = result.map { lastFile in
            let created  = formatter.string(from: lastFile.created)
            let modified = formatter.string(from: lastFile.modified)
            return FileResource(
                resource_id: lastFile.resource_id, type: lastFile.type,               _embedded: nil,
                name: lastFile.name,               path: lastFile.path,               file: lastFile.file,
                preview: lastFile.preview,         created: created,                  modified: modified,
                size: lastFile.size,               mime_type: lastFile.mime_type,     media_type: lastFile.media_type,
                md5: lastFile.md5,                 revision: lastFile.revision,       public_key: nil,
                public_url: lastFile.public_url
                
            )
        }
        return out
    }
    
    func getLastFilesCount () -> Int {
        ( try? context.count(for: LastFiles.fetchRequestCount()) ) ?? 0
    }
    
    func getLastFilesObject (resource_id: String?, md5: String?) -> LastFiles? {
        var predicate: NSPredicate
        if let resource_id = resource_id {
            predicate = NSPredicate(format: "resource_id == '\(resource_id)'")
        } else if let md5 = md5 {
            predicate = NSPredicate(format: "md5 == '\(md5)'")
        } else { print("LastFiles: perform fetch failed"); return nil }
        let resultController = NSFetchedResultsController<LastFiles>(
            fetchRequest: LastFiles.fetchRequest(limit: 1, offset: 0, predicate: predicate),
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil)
        do {
            try resultController.performFetch()
        }
        catch { print("LastFiles: perform fetch failed: ", error.localizedDescription) }
        return resultController.fetchedObjects?.first
    }
    
    // AllFlsFCache
    func getAllFlsFCache () -> [AllFlsFCache] {
        let resultController = NSFetchedResultsController<AllFlsFCache>(
            fetchRequest: AllFlsFCache.fetchRequest(),
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil)
        do {
            try resultController.performFetch()
        }
        catch { print("Perform fetch failed: ", error.localizedDescription) }
        return resultController.fetchedObjects ?? []
    }
    
    func getAllFlsFCacheObject (cacheFileName: String) -> AllFlsFCache? {
        let predicate = NSPredicate(format: "cacheFileName == '\(cacheFileName)'")
        let resultController = NSFetchedResultsController<AllFlsFCache>(
            fetchRequest: AllFlsFCache.fetchRequest(predicate: predicate),
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil)
        do {
            try resultController.performFetch()
        }
        catch { print("Perform fetch failed: ", error.localizedDescription) }
        return resultController.fetchedObjects?.first
    }
    
    // AllFiles
    func getAllFiles (path: String, limit: Int? = nil, offset: Int = 0) -> FileResource? {
        let predicate = NSPredicate(format: "path == '\(path)'")
        let stalePredicate = NSPredicate(format: "stale == 'false'")
        let predicateCompound = NSCompoundPredicate.init(type: .and, subpredicates: [stalePredicate,predicate])
        let resultController = NSFetchedResultsController<AllFiles>(
            fetchRequest: AllFiles.fetchRequest(predicate: predicateCompound),
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil)
        do {
            try resultController.performFetch()
        }
        catch { print("Perform fetch failed: ", error.localizedDescription) }
        guard let result = resultController.fetchedObjects?.first else { print("Nil fetch result "); return nil }
        let formatter = ISO8601DateFormatter()
        let created  = formatter.string(from: result.created)
        let modified = formatter.string(from: result.modified)
print(result.path)
print(result.embedded?.items?.first)
        let itemsSet = result.embedded?.items as? Set<AllFiles> ?? []
        let limit = limit ?? YaConst.allFilesPageLimit
        let limitIndex = limit == 0 ? itemsSet.count :
                offset + limit > itemsSet.count ?
                    itemsSet.count : offset + limit
        let sort: (FileResource, FileResource) -> Bool = {
            ($0.type == "dir" && $1.type != "dir")
                || ($0.type == $1.type && $0.name < $1.name)
        }
        let items: [FileResource] = Array( (itemsSet.map ({ file in
            let created  = formatter.string(from: file.created)
            let modified = formatter.string(from: file.modified)
            return FileResource(
                resource_id: file.resource_id, type: file.type,           _embedded: nil,
                name: file.name,               path: file.path,           file: file.file,
                preview: file.preview,         created: created,          modified: modified,
                size: file.size,               mime_type: file.mime_type, media_type: file.media_type,
                md5: file.md5,                 revision: file.revision,   public_key: file.public_key,
                public_url: file.public_url
            )
        }).sorted(by: sort))[offset..<limitIndex] )
        let embedded = FileResourceList(
            sort: result.embedded?.sort,
            items: items,
            type: result.embedded?.type,     limit: result.embedded?.limit,
            offset: result.embedded?.offset, path: result.embedded?.path,
            total: YaAPI.driveServerConnectionStatus.value ? result.embedded?.total
                                                           : Int64(itemsSet.count) )
        let out = FileResource(
            resource_id: result.resource_id, type: result.type,           _embedded: embedded,
            name:        result.name,        path:      result.path,      file:       result.file,
            preview:     result.preview,     created:   created,          modified:   modified,
            size:        result.size,        mime_type: result.mime_type, media_type: result.media_type,
            md5:         result.md5,         revision:  result.revision,  public_key: result.public_key,
            public_url:  result.public_url
        )
        return out
    }
    
    func getAllFilesObject (resource_id: String?, md5: String?, path: String) -> AllFiles? {
        let stalePredicate = NSPredicate(format: "stale == 'false'")
        var predicate: NSPredicate
        if let resource_id = resource_id {
            predicate = NSPredicate(format: "resource_id == '\(resource_id)'")
        } else if let md5 = md5 {
            predicate = NSPredicate(format: "md5 == '\(md5)'")
        } else {
            predicate = NSPredicate(format: "path == '\(path)'")
        }
        let predicateCompound = NSCompoundPredicate.init(type: .and, subpredicates: [stalePredicate,predicate])
        let resultController = NSFetchedResultsController<AllFiles>(
            fetchRequest: AllFiles.fetchRequest(predicate: predicateCompound),
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil)
        do {
            try resultController.performFetch()
        }
        catch { print("AllFiles: perform fetch failed: ", error.localizedDescription) }
        return resultController.fetchedObjects?.first
    }
    
    // PublicFiles
    func getPublicFiles (limit: Int? = nil, offset: Int = 0, predicate: NSPredicate? = nil) -> [PublicResource] {
        let resultController = NSFetchedResultsController<PublicFiles>(
            fetchRequest: PublicFiles.fetchRequest(limit: limit, offset: offset, predicate: predicate),
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil)
        do {
            try resultController.performFetch()
        }
        catch { print("Perform fetch failed: ", error.localizedDescription) }
        guard let result = resultController.fetchedObjects, !result.isEmpty else { return [] }
        let formatter = ISO8601DateFormatter()
        let out: [PublicResource] = result.map { publicFile in
            let created  = formatter.string(from: publicFile.created)
            let modified = formatter.string(from: publicFile.modified)
            return PublicResource(
                resource_id: publicFile.resource_id, type: publicFile.type,               _embedded: nil,
                name: publicFile.name,               path: publicFile.path,               file: publicFile.file,
                preview: publicFile.preview,         created: created,                    modified: modified,
                size: publicFile.size,               mime_type: publicFile.mime_type,     media_type: publicFile.media_type,
                md5: publicFile.md5,                 revision: publicFile.revision,       public_key: publicFile.public_key,
                public_url: publicFile.public_url
                
            )
        }
        return out
    }
    
    func getPublicFilesCount () -> Int {
        ( try? context.count(for: PublicFiles.fetchRequestCount()) ) ?? 0
    }
    
    func getPublicFilesObject (resource_id: String?, md5: String?, path: String) -> PublicFiles? {
        var predicate: NSPredicate
        if let resource_id = resource_id {
            predicate = NSPredicate(format: "resource_id == '\(resource_id)'")
        } else if let md5 = md5 {
            predicate = NSPredicate(format: "md5 == '\(md5)'")
        } else {
            predicate = NSPredicate(format: "path == '\(path)'")
        }
        let resultController = NSFetchedResultsController<PublicFiles>(
            fetchRequest: PublicFiles.fetchRequest(limit: 1, offset: 0, predicate: predicate),
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil)
        do {
            try resultController.performFetch()
        }
        catch { print("PublicFiles: perform fetch failed: ", error.localizedDescription) }
        return resultController.fetchedObjects?.first
    }
    
    // MARK: change/delete data
    // LastFiles
    public func deleteFromLastFiles (name: String, resource_id: String?, md5: String?) {
        guard resource_id != nil || md5 != nil,
              let object = getLastFilesObject(resource_id: resource_id, md5: md5)
        else { return }
        context.delete(object)
        do{
            try context.save()
            // delete files
            guard let fileCacheToRemove = getFileName(name: name,
                                                      resource_id: resource_id,
                                                      md5: md5)
            else { return }
            YaFileManager().removeStaleFileCache([fileCacheToRemove])
        }
        catch { print(error.localizedDescription) }
    }
    
    public func renameLastFile (name: String, resource_id: String?, md5: String?, pathTo: String) {
        guard resource_id != nil || md5 != nil,
              let object = getLastFilesObject(resource_id: resource_id, md5: md5)
        else { return }
        object.name = name
        object.path = pathTo
        do{ try context.save() }
        catch { print(error.localizedDescription) }
    }
    
    public func publishLastFile (public_url: String, resource_id: String?, md5: String?) {
        guard resource_id != nil || md5 != nil,
              let object = getLastFilesObject(resource_id: resource_id, md5: md5)
        else { return }
        object.public_url = public_url
        do{ try context.save() }
        catch { print(error.localizedDescription) }
    }
    // AllFiles
    public func deleteFromAllFiles (name: String, resource_id: String?, md5: String?, path: String) {
        guard let object = getAllFilesObject(resource_id: resource_id, md5: md5, path: path)
        else { return }
        object.item?.removeFromItems(object)
        context.delete(object)
        do{
            try context.save()
            
            // delete files
            guard resource_id != nil || md5 != nil,
                  let fileCacheToRemove = getFileName(name: name,
                                                      resource_id: resource_id,
                                                      md5: md5)
            else { return }
            YaFileManager().removeAllFlsFCache(cacheFileName: fileCacheToRemove)
        }
        catch { print(error.localizedDescription) }
    }
    
    public func renameAllFile (name: String, resource_id: String?, md5: String?, pathFrom: String, pathTo: String) {
        guard let object = getAllFilesObject(resource_id: resource_id, md5: md5, path: pathFrom)
        else { return }
        object.name = name
        object.path = pathTo
        do{
            try context.save()
            // update object cache to take real values in the AllFiles items subquery:
            let _ = object.item?.items?.first
        }
        catch { print(error.localizedDescription) }
    }
    
    public func publishAllFile (public_url: String, resource_id: String?, md5: String?, path: String) {
        guard let object = getAllFilesObject(resource_id: resource_id, md5: md5, path: path)
        else { return }
        object.public_url = public_url
        do{
            try context.save()
            // update object cache to take real values in the AllFiles items subquery:
            let _ = object.item?.items?.first
        }
        catch { print(error.localizedDescription) }
    }
    
    // PublicFiles
    public func deleteFromPublicFiles (name: String, resource_id: String?, md5: String?, path: String) {
        guard let object = getPublicFilesObject(resource_id: resource_id, md5: md5, path: path)
        else { return }
        context.delete(object)
        do{
            try context.save()
            // delete files
            guard resource_id != nil || md5 != nil,
                  let fileCacheToRemove = getFileName(name: name,
                                                      resource_id: resource_id,
                                                      md5: md5)
            else { return }
            YaFileManager().removeAllFlsFCache(cacheFileName: fileCacheToRemove)
        }
        catch { print(error.localizedDescription) }
    }
    
    public func renamePublicFile (name: String, resource_id: String?, md5: String?, pathFrom: String, pathTo: String) {
        guard let object = getPublicFilesObject(resource_id: resource_id, md5: md5, path: pathFrom)
        else { return }
        object.name = name
        object.path = pathTo
        do{
            try context.save()
        }
        catch { print(error.localizedDescription) }
    }
    
    // AllFlsFCache
    public func deleteFromAllFlsFCache (cacheFileName: String) {
        guard let object = getAllFlsFCacheObject(cacheFileName: cacheFileName)
        else { return }
        context.delete(object)
        do{
            try context.save()
        }
        catch { print(error.localizedDescription) }
    }
    
    // MARK: Comparing remote & locald data
    // For LastFiles
    // Compare data from a remote server with the CoraData cache,
    // than removes the stale file cache
    private func compareDataWithStore (_ lastFiles: [FileResource]) {
        let coraData = getLastFiles(limit: 0, offset: 0, predicate: nil)
        let remoteCompareIDs = Set(lastFiles.compactMap {
            let revision = $0.revision ?? 0
            if ($0.resource_id == nil && $0.md5 == nil)
                || (revision == 0 && $0.md5 == nil) {
                return nil
            }
            var out = ($0.resource_id ?? "")
            out += $0.md5 != nil ? ($0.md5 ?? "") : revision.description
            return out
        } as [String])
        let toRemoveIDs: [String] = coraData.compactMap {
            if $0.resource_id == nil && $0.md5 == nil {
                return nil
            }
            let revision = $0.revision ?? 0
            var compareID = ($0.resource_id ?? "")
            compareID += $0.md5 != nil ? ($0.md5 ?? "") : revision.description
            if remoteCompareIDs.contains(compareID) {
                return nil
            } else {
                return getFileName(name: $0.name, resource_id: $0.resource_id, md5: $0.md5)
            }
        }
        YaFileManager().removeStaleFileCache(toRemoveIDs)
    }
    
    // MARK: clear functions
    // 1 with store destriong
    func clearDatabase() {
        guard let url = persistentContainer.persistentStoreDescriptions.first?.url else { return }
        
        let persistentStoreCoordinator = persistentContainer.persistentStoreCoordinator
        
        do {
            try persistentStoreCoordinator.destroyPersistentStore(at:url, ofType: NSSQLiteStoreType, options: nil)
            try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            print("Attempted to clear persistent store: " + error.localizedDescription)
        }
    }
    // 2 With entity deletion
    func resetAllCoreData() {
        // Debug before
        /*
        print("Files count: ",
              ( try? context.count(for: Files.fetchRequestCount()) ) ?? "nil")
        print("LastFiles count: ",
              ( try? context.count(for: LastFiles.fetchRequestCount()) ) ?? "nil")
        print("AllFiles count: ",
              ( try? context.count(for: AllFiles.fetchRequestCount()) ) ?? "nil")
        print("List count: ",
              ( try? context.count(for: List.fetchRequestCount()) ) ?? "nil")
        print("AllFlsFCache count: ",
              ( try? context.count(for: AllFlsFCache.fetchRequestCount()) ) ?? "nil")
        */
        
        // get all entities and loop over them
        let entityNames = persistentContainer.managedObjectModel.entities.map({ $0.name!})
        entityNames.forEach { entityName in
            deleteAllEntityData (entityName: entityName)
        }
        do { try context.save() }
        catch {
            print("Error saving context after cleanup:", error.localizedDescription)
        }
        
        // Debug after
        /*
        print("Files count: ",
              ( try? context.count(for: Files.fetchRequestCount()) ) ?? "nil")
        print("LastFiles count: ",
              ( try? context.count(for: LastFiles.fetchRequestCount()) ) ?? "nil")
        print("AllFiles count: ",
              ( try? context.count(for: AllFiles.fetchRequestCount()) ) ?? "nil")
        print("List count: ",
              ( try? context.count(for: List.fetchRequestCount()) ) ?? "nil")
        print("AllFlsFCache count: ",
              ( try? context.count(for: AllFlsFCache.fetchRequestCount()) ) ?? "nil")
        */
    }
    // 3 with objects deletion
    func deleteAllEntityData (entityName: String) {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult> (entityName: entityName)
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(batchDeleteRequest)
            // witout save. Use manual save context!
        } catch {
            print("Detele all data in \(entityName) error :", error.localizedDescription)
        }
    }
    
    // MARK: Compare data for file cache
    private func getFileName (name: String, resource_id: String?, md5: String?) -> String? {
        guard var fileName = (resource_id ?? md5)?
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
        else { return nil }
        fileName += name.suffix(from: name.lastIndex(of: ".") ?? name.endIndex)
        return fileName
    }
}
