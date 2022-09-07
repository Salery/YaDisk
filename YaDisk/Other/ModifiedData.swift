//
//  ModifiedData.swift
//  YaAPI
//
//  Created by Devel on 15.08.2022.
//

enum ModifiedType {
    case deleted, renamed, published
}
// Registers changed data for synchronization
struct ModifiedData {
    static var register = [ModifiedData]()
    var index:        Int
    let resource_id:  String?
    let md5:          String?
    let modifiedType: ModifiedType
    let name:         String
    let pathFrom:     String
    var pathTo:       String? = nil
    var public_url:   String? = nil
    let modifiedBy:   String  // app section
    var lstFlUpdated: Bool    = false
    var allFlUpdated: Bool    = false
    var pubFlUpdated: Bool    = false
}
