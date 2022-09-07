//
//  DetailedM.swift
//  YaDisk
//
//  Created by Devel on 26.07.2022.
//

import Foundation

enum DetailedTypes: String {
    case dir, image, document, pdf, withoutView
}

struct DetailedInput {
    let index:       Int
    let resource_id: String?
    var name:        String
    let size:        Int64
    let created:     String
    let type:        DetailedTypes
    let md5:         String?
    let file:        String?
    var path:        String
    var public_url:  String?
    let revision:    Int64
    let startsFrom:  String
}

struct DetailedOutput {
    let name:    String
    let fileInf: String
}

final class DetailedM {
    init (_ input: DetailedInput) {
        self.input = input
    }
    
    var input:  DetailedInput
    
    func getDataForDetailes () -> DetailedOutput {
        let name = input.name
        let fileInf = Functions().getFileInf(size: input.size, created: input.created)
        return DetailedOutput(name: name, fileInf: fileInf)
    }
    
    func getDataForDownload () -> (id: String, url: String, size: Int64)? {
        guard let url = input.file,
              var id = (input.resource_id ?? input.md5)?
                .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
        else { return nil }
        id += input.name.suffix(from: input.name.lastIndex(of: ".") ?? input.name.endIndex)
        return (id: id, url: url, input.size)
    }
}
