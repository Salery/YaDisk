//
//  Functions.swift
//  YaDisk
//
//  Created by Devel on 21.07.2022.
//

import Foundation

final class Functions {
    func fileSizeToShortString (value: Int64) -> String {
        switch value {
        case 0...1024:
            return value.description + " " + NSLocalizedString("B", comment: "Size.Byte")
        case 1025...1024*1024:
            return (value/1024).description + " " + NSLocalizedString("KB", comment: "Size.KByte")
        case 1024*1024+1...1024*1024*1024:
            return (value/(1024*1024)).description + " " + NSLocalizedString("MB", comment: "Size.MByte")
        default:
            return (value/(1024*1024*1024)).description + " " + NSLocalizedString("GB", comment: "Size.GByte")
        }
    }
    
    func fileCreatedToShortFormat (created: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: created)
        else { return "" }
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("dd.MM.yy")
        return formatter.string(from: date) + " " + DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
    }
    
    func getFileInf (size: Int64, created: String) -> String {
        (size > 0 ? (fileSizeToShortString(value: size) + " ") : "")
        + fileCreatedToShortFormat(created: created)
    }
    
    func getFolderPath(pathFrom: String) -> String {
        (String(pathFrom[..<(pathFrom.lastIndex(of: "/") ?? pathFrom.endIndex)]))
    }
    
    // ModifiedData functions
    func clearAppliedChanges () {
        ModifiedData.register.removeAll(
            where: {$0.allFlUpdated && $0.lstFlUpdated})
    }
    /// Marks all changes to the LastFiles as already applied.
    /// Should be executed after loading the table from the API/ the CoreData.
    func markAllLstFlUpdatedAsApplied () {
        for i in 0..<ModifiedData.register.count {
            ModifiedData.register[i].lstFlUpdated = true
        }
        clearAppliedChanges()
    }
    func markAllFlUpdatedAsAppliedForPath (path: String) {
        for index in 0..<ModifiedData.register.count {
            let pathFrom = ModifiedData.register[index].pathFrom
            let mPath = Functions().getFolderPath(pathFrom: pathFrom)
            if path == mPath || path == mPath + "/" {
                ModifiedData.register[index].allFlUpdated = true
            }
        }
        clearAppliedChanges()
    }
    func markAllPubFlUpdatedAsApplied () {
        for i in 0..<ModifiedData.register.count {
            ModifiedData.register[i].pubFlUpdated = true
        }
        clearAppliedChanges()
    }
}
