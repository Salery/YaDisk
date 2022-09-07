//
//  FileListCellVM.swift
//  YaDisk
//
//  Created by Devel on 26.07.2022.
//

import UIKit
import Shared
import YaAPI

protocol FileListCellVMProtocol {
    var icon:              Box<UIImage?>             { get }
    var iconIsDownloading: Box<Bool>                 { get }
    var dataForCell:       Box<FilesListCellOutput?> { get }
}

final class FileListCellVM: FileListCellVMProtocol {
    private let model: FilesListCellM
    let icon:              Box<UIImage?>             = Box(value: nil)
    let iconIsDownloading: Box<Bool>                 = Box(value: false)
    let dataForCell:       Box<FilesListCellOutput?> = Box(value: nil)
    
    init (from: FilesListCellInput) {
        model = FilesListCellM(from)
        dataForCell.value = model.getDataForCell()
        guard let preview = model.getDataForPreview()
        else { return }
        downloadPreview(url: preview.url, id: preview.id)
    }
    
    private func downloadPreview (url: String, id: String) {
        var previewUrl = Const.Paths.cachesDirectoryURL
        previewUrl = previewUrl.appendingPathComponent(YaConst.previewDir, isDirectory: true)
        previewUrl = previewUrl.appendingPathComponent(id, isDirectory: false)
        if FileManager.default.fileExists(atPath: previewUrl.path) {
            icon.value = UIImage(contentsOfFile: previewUrl.path)
            return
        }
        iconIsDownloading.value = true
        YaFileManager().downloadFileWithUrl(url: url, id: id, preview: true, progress: {progress in }) {
            [weak self] url, error in
            guard let self = self else { return }
            self.iconIsDownloading.value = false
            guard let url = url else { return }
            self.icon.value = UIImage(contentsOfFile: url.path)
        }
    }
}
