//
//  FilesListCell.swift
//  YaDisk
//
//  Created by Devel on 20.07.2022.
//

import UIKit
import Shared
import SnapKit
import YaAPI

protocol CellDelegate: AnyObject {
    func unpublButtonClick (cell: FilesListCellV)
}

final class FilesListCellV: UITableViewCell {
    private var viewModel: FileListCellVMProtocol?
    weak var cellDelegate: CellDelegate?
    
    private lazy var nameLabel: UILabel  = {
        let label = UILabel()
        label.font = Const.Fonts.filesNameFont
        label.textColor = Const.Colors.filesNameFontColor
        return label
    }()
    private lazy var infLabel: UILabel  = {
        let label = UILabel()
        label.font = Const.Fonts.filesInfFont
        label.textColor = Const.Colors.filesInfColor
        return label
    }()
    private lazy var icon: UIImageView  = {
        let icon = UIImageView()
        icon.contentMode = .scaleAspectFit
        return icon
    }()
    private lazy var unpublButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 2.5
        button.setImage(Const.Images.unpublButton, for: .normal)
        button.setImage(Const.Images.unpublButton?.withTintColor(
            Const.Colors.unpublBHghLtColor, renderingMode: .alwaysOriginal), for: .highlighted)
        button.layer.shadowColor   = Const.Colors.unpublBShdwColor
        button.layer.shadowOffset  = Const.Sizes.unpublBShdwOffset
        button.layer.shadowRadius  = Const.Sizes.unpublBShdwRadius
        button.layer.shadowOpacity = Const.Sizes.unpublBShdwOpacity
        button.addTarget(self, action: #selector(unpublButtonClick), for: .touchUpInside)
        return button
    }()
    private let activityIndicator = UIActivityIndicatorView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func config (viewModel: FileListCellVMProtocol, unpublButton: Bool = false) {
        self.viewModel = viewModel
        binder()
        if unpublButton { setupunpublButton() }
    }
    
    private func binder () {
        guard let viewModel = viewModel else { return }

        viewModel.dataForCell.bindAndFire { [weak self] dataForCell in
            guard let self = self, let dataForCell = dataForCell
            else { return }
            self.nameLabel.text = dataForCell.name
            self.infLabel.text  = dataForCell.fileInf
            self.icon.image     = dataForCell.icon
        }
        viewModel.icon.bindAndFire { [weak self] icon in
            guard let self = self, let icon = icon
            else { return }
            self.icon.image = icon
        }
        viewModel.iconIsDownloading.bindAndFire { [weak self] isDownloading in
            guard let self = self
            else { return }
            self.activityAnimation(isDownloading)
        }
    }
    
    @objc private func unpublButtonClick () {
        cellDelegate?.unpublButtonClick(cell: self)
    }
    
    private func setupunpublButton () {
        contentView.addSubview(unpublButton)
        unpublButton.snp.makeConstraints { make in
            make.centerY.equalTo(contentView.snp.centerY)
            make.right.equalTo(contentView.snp.right).offset(-18)
            make.width.equalTo(Const.Sizes.unpublButtonWidth)
            make.height.equalTo(Const.Sizes.unpublButtonHeight)
        }
        nameTrailingConstraint?.deactivate()
        nameLabel.snp.makeConstraints { make in
            make.trailing.equalTo(unpublButton.snp.leading).offset(-15)
        }
    }
    
    private func setupViews () {
        contentView.addSubview(icon)
        contentView.addSubview(nameLabel)
        contentView.addSubview(infLabel)
    }
    
    private func activityAnimation (_ value: Bool) {
        if value {
            contentView.addSubview(activityIndicator)
            activityIndicator.snp.makeConstraints { make in
                make.center.equalTo(icon.snp.center)
            }
            activityIndicator.startAnimating()
        } else {
            self.activityIndicator.stopAnimating()
            self.activityIndicator.removeFromSuperview()
        }
    }
    
    private var nameTrailingConstraint: Constraint?
    private func setConstraints () {
        icon.snp.makeConstraints { make in
            make.centerY.equalTo(contentView.snp.centerY)
            make.leading.equalTo(18)
            make.width.equalTo (YaConst.lastFilesPreviewWidth)
            make.height.equalTo(YaConst.lastFilesPreviewHeight)
        }
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.top).offset(6)
            make.leading.equalTo(icon.snp.trailing).offset(15)
            nameTrailingConstraint = make.trailing
                .equalTo(contentView.snp.trailing).offset(-18).constraint
        }
        infLabel.snp.makeConstraints { make in
            make.bottom.equalTo(contentView.snp.bottom).offset(-6)
            make.leading.equalTo(icon.snp.trailing).offset(15)
            make.trailing.equalTo(contentView.snp.trailing).offset(-18)
        }
    }
}
