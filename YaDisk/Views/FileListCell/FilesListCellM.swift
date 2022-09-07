//
//  FilesListCellM.swift
//  YaDisk
//
//  Created by Devel on 26.07.2022.
//

import UIKit
import YaAPI

struct FilesListCellInput {
    let resource_id: String?
    let name:        String
    let size:        Int64
    let created:     String
    let type:        String?
    let mime_type:   String?
    let preview:     String?
    let md5:         String?
}

struct FilesListCellOutput {
    let name:    String
    let fileInf: String
    let icon:    UIImage?
}

final class FilesListCellM {
    init (_ input: FilesListCellInput) {
        self.input = input
    }
    
    private let input:  FilesListCellInput
    
    func getDataForCell () -> FilesListCellOutput {
        let name = input.name
        let fileInf = Functions().getFileInf(size: input.size, created: input.created)
        var mime = ""
        if input.mime_type != nil {
            mime = String( input.mime_type!.prefix{$0.isLetter} )
            if input.mime_type!.contains("pdf") { mime = "pdf" }
        }
        if input.type == "dir" { mime = "dir"}
//        print(input.type)
        let icon = (MimeType(rawValue: mime) ?? .unknown).icon
        return FilesListCellOutput(name: name, fileInf: fileInf, icon: icon)
    }
    
    func getDataForPreview () -> (id: String, url: String)? {
        guard let url = input.preview,
              var id = (input.resource_id ?? input.md5)?
                .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
        else { return nil }
        id += input.name.suffix(from: input.name.lastIndex(of: ".") ?? input.name.endIndex)
        return (id: id, url: url)
    }
}
