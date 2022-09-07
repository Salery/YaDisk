//
//  ProfileVC.swift
//  YaDisk
//
//  Created by Devel on 16.08.2022.
//

import UIKit
import Shared
import YaAPI
import SnapKit

class ProfileVC: UIViewController, ProfileViewProtocol {
    let viewModel = ProfileVM()
    let navTitle: String = NSLocalizedString("Profile", comment: "Title.userInfo")
    let navBarAppearanceConnectedColor:    UIColor = .white
    let navBarAppearanceDisconnectedColor: UIColor = .red
    
    private let centralActIndicator = UIActivityIndicatorView()
    private lazy var rBarButton = UIBarButtonItem(
        image: Const.Images.logoffButton, style: .plain,
        target: self, action: #selector(logoffClicked))
    private let pieChartView = PieChartView()
    private lazy var capacityLabel: UILabel = {
        let label = UILabel()
        label.font = Const.Fonts.capacityLblFnt
        label.textColor = Const.Colors.capacityLblColor
        label.textAlignment = .center
        label.backgroundColor = .white
        label.layer.masksToBounds = true
        label.text = "Total"
        return label
    }()
    private func newStatLbl () -> UILabel {
        let label = UILabel()
        label.font = Const.Fonts.uInfoLblFnt
        label.textColor = Const.Colors.uInfoFontColor
        label.textAlignment = .left
        return label
    }
    private lazy var usedLabel  = newStatLbl()
    private lazy var trashLabel = newStatLbl()
    private lazy var freeLabel  = newStatLbl()
    private func newCircle (color: UIColor) -> UIView {
        let view = UILabel()
        view.backgroundColor = color
        view.layer.masksToBounds = true
        view.layer.cornerRadius = Const.Sizes.userInfoCircleSize.width / 2
        return view
    }
    private lazy var usedCircle  = newCircle(color: Const.Colors.uInfoUsedColor)
    private lazy var trashCircle = newCircle(color: Const.Colors.uInfoTrashColor)
    private lazy var freeCircle  = newCircle(color: Const.Colors.uInfoFreeColor)
    
    private let spacer = UIView()
    private lazy var btnChevronR: UIImageView = {
        let image = UIImage(systemName: "chevron.right")?
            .withTintColor(.gray, renderingMode: .alwaysOriginal)
        let iView = UIImageView(image: image)
        iView.contentMode = .scaleAspectFit
        return iView
    }()
    private lazy var button: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 10
        button.setTitleColor(Const.Colors.profileBtnFntColor, for: .normal)
        button.backgroundColor = Const.Colors.profileButtonColor
        button.setTitle(NSLocalizedString(
            "Public files", comment: "Button.publicFiles"), for: .normal)
        button.contentHorizontalAlignment = .left
        button.titleEdgeInsets.left = 16
        button.layer.shadowColor   = Const.Colors.profileBShdwColor
        button.layer.shadowOffset  = Const.Sizes.prflBtnShdwOffset
        button.layer.shadowRadius  = Const.Sizes.prflBtnShdwRadius
        button.layer.shadowOpacity = Const.Sizes.prflBtnShdwOpacity
        button.addSubview(btnChevronR)
        button.addTarget(self, action: #selector(buttonClick), for: .touchUpInside)
        return button
    }()
    func finishRefreshAnimation() { }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        binder ()
        extraBinder()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupViews()
        self.setupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.binder()
    }
    
    private func extraBinder () {
        viewModel.profileData.bind { [weak self] profileData in
            self?.centralActIndicatorAnimation(value: false)
            guard let self = self,
            let profileData = profileData
            else { return }
            let functions = Functions()
            self.pieChartView.segments = profileData.segments
            self.capacityLabel.text = functions
                .fileSizeToShortString(value: profileData.capacity)
            self.usedLabel.text = functions
                .fileSizeToShortString(value: profileData.used)
                    + NSLocalizedString(" used",  comment: "UInfo.used")
            self.trashLabel.text = functions
                .fileSizeToShortString(value: profileData.trash)
                    + NSLocalizedString(" trash", comment: "UInfo.trash")
            self.freeLabel.text = functions
                .fileSizeToShortString(value: profileData.free)
                    + NSLocalizedString(" free",  comment: "UInfo.free")
            self.setupPieViews()
            self.setupPieConstraints()
        }
    }
    
    // Clicked
    @objc private func buttonClick() {
        let nextVC = PublicFilesTableVC()
        navigationController?.pushViewController(nextVC, animated: true)
    }
    @objc private func logoffClicked() {
        // Alert
        let errorStruct = ErrorStruct(
            title: "",
            message: NSLocalizedString("Are you sure you want to log off? All local user data will be deleted.",
                                       comment: "Confirm.logoff"),
            decisionNeeded: true,
            actionHandler: { [weak self] action in
                Auth().logOff(byUser: true)
                self?.viewModel.auth()
            },
            completion: nil)
        // AlertSheet
        let alertSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertSheet.addAction(UIAlertAction(
            title: NSLocalizedString("Cancel", comment: "Action.cancel"),
            style: .cancel, handler: nil))
        alertSheet.addAction(UIAlertAction(
            title: NSLocalizedString("Log off", comment: "Action.logoff"),
            style: .destructive, handler: {
                [weak self] _ in
                self?.showError(errorStruct: errorStruct)
            }))
        present(alertSheet, animated: true, completion: nil)
    }
    
    private func centralActIndicatorAnimation (value: Bool) {
        if value {
            centralActIndicator.style = .large
            view.addSubview(centralActIndicator)
            centralActIndicator.center = view.center
            centralActIndicator.startAnimating()
        } else if view.subviews.contains(centralActIndicator) {
            centralActIndicator.stopAnimating()
            centralActIndicator.removeFromSuperview()
        }
    }
    
    // show loaded views from api
    private func setupPieViews () {
        view.addSubview(pieChartView)
        view.addSubview(capacityLabel)
        view.addSubview(usedCircle)
        view.addSubview(usedLabel)
        view.addSubview(trashCircle)
        view.addSubview(trashLabel)
        view.addSubview(freeCircle)
        view.addSubview(freeLabel)
        view.addSubview(spacer)
    }
    
    private func setupPieConstraints () {
        pieChartView.snp.makeConstraints { make in
            make.centerX.equalTo(view.snp.centerX)
            make.top.equalTo(view.snp_topMargin).offset(16)
            make.width.height.equalTo(view.snp.width).dividedBy(1.5)
        }
        capacityLabel.snp.makeConstraints { make in
            make.center.equalTo(pieChartView.snp.center)
            make.width.height.equalTo(pieChartView.snp.width).dividedBy(1.5)
        }
        capacityLabel.layer.cornerRadius = view.frame.width / (1.5 * 1.5 * 2)
        usedCircle.snp.makeConstraints { make in
            make.leading.equalTo(pieChartView.snp.leading)
            make.top.equalTo(pieChartView.snp.bottom).offset(32)
            make.width.height.equalTo(Const.Sizes.userInfoCircleSize.width)
        }
        usedLabel.snp.makeConstraints { make in
            make.leading.equalTo(usedCircle.snp.trailing).offset(8)
            make.centerY.equalTo(usedCircle.snp.centerY)
        }
        usedLabel.sizeToFit()
        trashCircle.snp.makeConstraints { make in
            make.leading.equalTo(usedCircle.snp.leading)
            make.top.equalTo(usedCircle.snp.bottom).offset(16)
            make.width.height.equalTo(Const.Sizes.userInfoCircleSize.width)
        }
        trashLabel.snp.makeConstraints { make in
            make.leading.equalTo(trashCircle.snp.trailing).offset(8)
            make.centerY.equalTo(trashCircle.snp.centerY)
        }
        trashLabel.sizeToFit()
        freeCircle.snp.makeConstraints { make in
            make.leading.equalTo(trashCircle.snp.leading)
            make.top.equalTo(trashCircle.snp.bottom).offset(16)
            make.width.height.equalTo(Const.Sizes.userInfoCircleSize.width)
        }
        freeLabel.snp.makeConstraints { make in
            make.leading.equalTo(freeCircle.snp.trailing).offset(8)
            make.centerY.equalTo(freeCircle.snp.centerY)
        }
        freeLabel.sizeToFit()
        spacer.snp.makeConstraints { make in
            make.top.equalTo(freeCircle.snp.bottom)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        btnCenterConstraint?.deactivate()
        button.snp.makeConstraints { make in
            make.centerY.equalTo(spacer.snp.centerY)
        }
    }
    
    // other views
    private func setupViews () {
        view.backgroundColor = .white
        navigationItem.rightBarButtonItem = rBarButton
        view.addSubview(button)
        centralActIndicatorAnimation(value: true)
        navigationItem.backButtonTitle = ""
    }
    
    private var btnCenterConstraint: Constraint?
    private func setupConstraints () {
        button.snp.makeConstraints { make in
            btnCenterConstraint = make.centerY.equalTo(view.snp.centerY).constraint
            make.centerX.equalTo(view.snp.centerX)
            make.width.equalTo(view.snp.width).offset(-32)
            make.height.equalTo(50)
        }
        btnChevronR.snp.makeConstraints { make in
            make.centerY.equalTo(button.snp.centerY)
            make.trailing.equalTo(button.snp.trailing).offset(-16)
            make.width.height.equalTo(button.snp.height).dividedBy(3)
        }
    }
}
