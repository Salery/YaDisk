//
//  AuthVC.swift
//  YaDisk
//
//  Created by Devel on 08.07.2022.
//

import UIKit
import WebKit
import PDFKit
import SnapKit
import Shared
import YaAPI

class DetailedVC: UIViewController, DetailedViewProtocol {
    let viewModel: DetailedVM
    
    var navTitle: String {
        didSet {
            if let titleView = navigationItem.titleView {
                let titleLabel = titleView.subviews.first(where: ({$0 is UILabel})) as? UILabel ?? UILabel()
                titleLabel.text = navTitle
                titleLabel.sizeToFit()
                titleView.sizeToFit()
            } else {
                navigationItem.title = navTitle
            }
        }
    }
    let navBarAppearanceConnectedColor:    UIColor = .clear
    let navBarAppearanceDisconnectedColor: UIColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.3)
    func finishRefreshAnimation() {}
    
    private var lastOrientation = UIDevice.current.orientation
    // Empty view to display the view properly
    private let emptyView    = UIView()
    // FileInfo toolbar string
    private lazy var fileInfoLabel: UILabel = {
        let label          = UILabel()
        label.font         = Const.Fonts.flsInfFontDet
        label.textColor    = Const.Colors.filesInfColor
        label.shadowOffset = Const.Sizes.filesInfshdwOffset
        label.shadowColor  = Const.Colors.filesInfshdwColor
        return label
    }()
    
    private lazy var withoutViewLabel: UILabel = {
        let label           = UILabel()
        label.textAlignment = .center
        label.font          = Const.Fonts.withoutViewFnt
        label.textColor     = Const.Colors.filesInfColor
        label.text = NSLocalizedString("Unable to view the file",
                                       comment: "Message.unableViewFile")
        // Невозможно просмотреть файл
        return label
    }()
    
    // Toolbar - flexibleSpace
    private let toolBarButtonsSpace = UIBarButtonItem(
        barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    private lazy var toolBarTitle = UIBarButtonItem(customView: fileInfoLabel)
    
    // MARK: Delete components
    private lazy var rToolBarButton = UIBarButtonItem (
        image: Const.Images.delButton, style: .plain,
        target: self, action: #selector(rToolBarButtonClicked)
    )
    
    // MARK: Rename components
    private var fileExtension = ""
    private lazy var icon: UIImage? = {
        if let previewUrl = viewModel.getPreview() {
            return UIImage(contentsOfFile: previewUrl.path)
        } else {
            return ( MimeType(rawValue: viewModel.getIcon())
                    ?? MimeType.unknown ).icon
        }
    }()
    private lazy var renameAlert: UIAlertController = {
        let alert = UIAlertController(
            title: NSLocalizedString("Rename", comment: "Action.rename"),
            message: "", preferredStyle: .alert)
        alert.addTextField { [weak self] textField in
            let name = self?.navTitle ?? ""
            let pointIndex = (name.lastIndex(of: ".") ?? name.endIndex)
            let withoutExtension = String(name[..<pointIndex])
            self?.fileExtension  = String(name[pointIndex...])
            textField.text = withoutExtension
        }
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("Cancel", comment: "Action.cancel"),
            style: .cancel, handler: nil)
        )
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("Rename", comment: "Action.rename"),
            style: .destructive, handler: { [weak self] action in
                self?.rename(to: alert.textFields?.first?.text ?? "")
            })
        )
        return alert
    }()
    private lazy var rBarButton = UIBarButtonItem(
        image: Const.Images.editButton, style: .plain,
        target: self, action: #selector(rBarButtonClicked))
    
    // MARK: Publish components
    private lazy var lToolBarButton = UIBarButtonItem(
        image: Const.Images.publButton, style: .plain,
        target: self, action: #selector(lToolBarButtonClicked)
    )
    
    // MARK: Download components
    private lazy var downloadStartButton: UIButton = {
        let button = UIButton(customType: .nextButton,
                              title: NSLocalizedString("Download", comment: "Button.download"),
                              bottomRelativeToView: nil,
                              actionSelector: #selector(download))
        button.layer.cornerRadius  = Const.Sizes.dwnlFlBCrnerRadius
        button.layer.shadowOffset  = Const.Sizes.dwnlFlBShdwOffset
        button.layer.shadowColor   = Const.Colors.dwnlFlBShdwColor
        button.layer.shadowRadius  = Const.Sizes.dwnlFlBShdwRadius
        button.layer.shadowOpacity = Const.Sizes.dwnlFlBShdwOpacity
        return button
    }()
    private lazy var progressView: UIProgressView = {
        let progressView = UIProgressView()
        return progressView
    }()
    private lazy var downloadProgressLabel: UILabel = {
        let label = UILabel()
        label.font = Const.Fonts.downloadFont
        label.textColor = Const.Colors.downloadFontColor
        return label
    }()
    private lazy var downloadProgressCountLabel: UILabel = {
        let label = UILabel()
        label.contentMode = .right
        label.font = Const.Fonts.dwnldCountFont
        label.textColor = Const.Colors.dwnldCountFontColor
        return label
    }()
    private lazy var downloadCancelButton: UIButton = {
        let button = UIButton(customType: .nextButton,
                              title: NSLocalizedString("Cancel download", comment: "Button.cancelDownload"),
                              bottomRelativeToView: nil,
                              actionSelector: #selector(cancelDownload))
        return button
    }()
    
    init (viewModel: DetailedVMProtocol) {
        self.viewModel = viewModel as! DetailedVM
        navTitle = viewModel.dataForDetailes.value?.name ?? ""
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
        binder()
        binderExtra()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: File's reader views
    // ImageView
    private lazy var scrollImageView = SrollImageView()
    private lazy var tapRecogniser: UITapGestureRecognizer = {
        let tapRecogniser = UITapGestureRecognizer(target: self, action: #selector(imageViewClicked))
        tapRecogniser.numberOfTapsRequired  = 1
        return tapRecogniser
    }()
    // webView
    private lazy var webView: WKWebView = {
        let webView = WKWebView()
        webView.scrollView.delegate = nil
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        webView.allowsBackForwardNavigationGestures = false
        webView.allowsLinkPreview = false
        webView.contentMode = .scaleAspectFit
        return webView
    }()
    // pdfView
    private lazy var pdfView: PDFView = {
        let pdfView = PDFView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        pdfView.displayMode = .singlePageContinuous
        pdfView.autoScales = true
        pdfView.displayDirection = .vertical
        return pdfView
    }()
    
    // MARK: Load view
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.binder()
        // show toolbar
        navigationController?.setToolbarHidden(false, animated: animated)
        // allow rotation
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.orientationLock = .all
        let lastOrientation = appDelegate?.lastOrientation ?? 0
        if UIDevice.current.orientation.rawValue == 0
            && lastOrientation != 0 {
            UIDevice.current.setValue(lastOrientation, forKey: "orientation")
        }
        UIViewController.attemptRotationToDeviceOrientation()
    }
    
    override func viewWillLayoutSubviews() {
        if view.subviews.contains(scrollImageView) {
            scrollImageView.setupImageView(gestureRecognizer: tapRecogniser)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if view.subviews.contains(scrollImageView) {
            scrollImageView.setupImageView(gestureRecognizer: tapRecogniser)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // hide toolbar
        navigationController?.setToolbarHidden(true, animated: animated)
        // lock rotation
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.orientationLock = .portrait
        lastOrientation = UIDevice.current.orientation
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
    }
    
    // MARK: Bind
    func binderExtra () {
        viewModel.dataForDetailes.bindAndFire { [weak self] detailedData in
            guard let self = self,
                  let detailedData = detailedData
            else { return }
            self.navTitle = detailedData.name
            self.fileInfoLabel.text = detailedData.fileInf
            self.showDownloadButton()
        }
        viewModel.progress.bind { [weak self] progress in
            guard let self = self,
                  let progress = progress
            else { return }
//            DispatchQueue.main.async {
            self.downloadProgressCountLabel.text = Int(progress.fractionCompleted * 100).description + "%"
            self.progressView.progress = Float(progress.fractionCompleted)
//            }
        }
        viewModel.file.bind { [weak self] file in
            guard let self = self,
                  let file = file
            else { return }
            switch self.viewModel.detailedType {
            case .image:
                self.setupSubView(self.scrollImageView)
                if file.pathExtension == "gif" {
                    self.scrollImageView.setImage(UIImage.gif(url: file))
                } else {
                    self.scrollImageView.setImage(UIImage(contentsOfFile: file.path))
                }
            case .document:
                self.setupSubView(self.webView)
                self.webView.loadFileURL(file, allowingReadAccessTo: file)
            case .pdf:
                self.setupSubView(self.pdfView)
                self.pdfView.document = PDFDocument(url: file)
            case .withoutView:
                self.setupSubView(self.withoutViewLabel)
            case .dir:
                break
            }
        }
        viewModel.fileIsDownloading.bind { [weak self] isDownloading in
            guard let self = self
            else { return }
            if isDownloading { self.setupDownloadButton(status: false) }
            else { self.showDownloadButton() }
            self.downloadProgressLabel.text = NSLocalizedString("Downloading:", comment: "Message.downloading")
            self.setupDownloadViews(status: isDownloading)
        }
    }
    // MARK: Views & constraints
    private func setupViews () {view.backgroundColor = Const.Colors.detVCScrnWBarsColor
        // For the transparent bottom toolbar ios15, bug with image <15:
        view.addSubview(emptyView)
//        view.addSubview(fileInfoLabel)
//        fileInfoLabel.layer.zPosition = 1
        navigationItem.rightBarButtonItem = rBarButton
        toolbarItems = [lToolBarButton, toolBarButtonsSpace,
                        toolBarTitle, toolBarButtonsSpace, rToolBarButton]
        if #available(iOS 15, *) {} else {
            let appearance = UIToolbarAppearance()
            appearance.configureWithTransparentBackground()
            navigationController?.toolbar.standardAppearance = appearance
        }
    }
    
    private func setupSubView (_ subView: UIView) {
        view.addSubview(subView)
        subView.snp.makeConstraints { make in
            make.center.equalTo(view.snp.center)
            make.width.equalTo (view.snp.width)
            make.height.equalTo(view.snp.height)
        }
    }
    // show/hide download views
    private func showDownloadButton() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if self?.viewModel.file.value == nil
                && self?.viewModel.fileIsDownloading.value == false {
                self?.setupDownloadButton(status: true)
            }
        }
    }
    private func setupDownloadButton (status: Bool) {
        if status {
            view.addSubview(downloadStartButton)
            downloadStartButton.snp.makeConstraints { make in
                make.center.equalTo(view.snp.center)
                make.width.height.equalTo(100)
            }
        } else {
            downloadStartButton.removeFromSuperview()
        }
    }
    private func setupDownloadViews (status: Bool) {
        if status {
            view.addSubview(downloadProgressLabel)
            downloadProgressLabel.snp.makeConstraints { make in
                make.centerY.equalTo(view.snp.centerY)
                make.centerX.equalTo(view.snp.centerX).offset(-35)
            }
            view.addSubview(downloadProgressCountLabel)
            downloadProgressCountLabel.snp.makeConstraints { make in
                make.centerY.equalTo (downloadProgressLabel.snp.centerY)
                make.trailing.equalTo(downloadProgressLabel.snp.trailing).offset(70)
            }
            view.addSubview(progressView)
            progressView.snp.makeConstraints { make in
                make.centerX.equalTo(view.snp.centerX)
                make.bottom.equalTo(downloadProgressLabel.snp.top).offset(-20)
                make.width.equalTo (downloadProgressLabel.snp.width).offset(70)
            }
            view.addSubview(downloadCancelButton)
            downloadCancelButton.snp.makeConstraints { make in
                make.centerX.equalTo(view.snp.centerX)
                make.top.equalTo(downloadProgressLabel.snp.bottom).offset(20)
                make.width.equalTo (downloadProgressLabel.snp.width).offset(70)
            }
        } else {
            downloadCancelButton.removeFromSuperview()
            progressView.removeFromSuperview()
            downloadProgressCountLabel.removeFromSuperview()
            downloadProgressLabel.removeFromSuperview()
        }
    }
    
    private func setupConstraints () {
        /*
        fileInfoLabel.snp.makeConstraints { make in
            make.centerX.equalTo(view.snp.centerX)
            make.top.equalTo(view.snp_topMargin)
        }
         */
    }
    
    // MARK: Actions
    private var onAction: Bool = false {
        didSet {
            enableButtons(toState: !onAction)
        }
    }
    // Rename
    private func rename (to: String) {
        onAction = true
        var to = to.trimmingCharacters(in: CharacterSet(charactersIn: " "))
        guard let temp = to.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
              !temp.isEmpty else { return }
        to += self.fileExtension
        if to == navTitle { return }
        viewModel.rename(to: to) { [weak self] result in
            guard let self = self, result else { return }
            self.onAction = false
            self.navTitle = to
        }
    }
    // Delete
    private func delete (permanently: String = "false") {
        onAction = true
        enableButtons(toState: false)
        viewModel.delete (permanently: permanently) { [weak self] result in
            guard let self = self, result else { return }
            self.onAction = false
            self.navigationController?.popViewController(animated: true)
        }
    }
    // Publish
    private func share(url: URL)
    {
        let activityVC = UIActivityViewController(activityItems: [url],
                                                  applicationActivities: nil)
        activityVC.excludedActivityTypes = [UIActivity.ActivityType.airDrop,
                                            UIActivity.ActivityType.addToReadingList]
        present(activityVC, animated: true, completion: nil)
    }
    private func publish () {
        onAction = true
        viewModel.publish { [weak self] result in
            guard let self = self,
                  let result = result
            else { return }
            self.onAction = false
            guard let url = URL(string: result) else { return }
            self.share(url: url)
        }
    }
    // Enable/disable barButtons
    private func enableButtons (toState: Bool) {
        rBarButton.isEnabled     = toState
        lToolBarButton.isEnabled = toState
        rToolBarButton.isEnabled = toState
    }
    
    // MARK: onButtonClicks
    // Download
    @objc private func download() {
        viewModel.startDownload(manualStart: true)
    }
    // Cancel download
    @objc private func cancelDownload() {
        viewModel.progress.value?.cancel()
    }
    // Rename
    @objc private func rBarButtonClicked() {
        guard !onAction else { return }
        present(renameAlert, animated: true, completion: nil)
    }
    // Publish
    @objc private func lToolBarButtonClicked() {
        guard !onAction else { return }
        // AlertSheet
        let alertSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertSheet.addAction(UIAlertAction(
            title: NSLocalizedString("Cancel", comment: "Action.cancel"),
            style: .cancel, handler: nil))
        alertSheet.addAction(UIAlertAction(
            title: NSLocalizedString("Share link", comment: "Action.shareLink"),
            style: .default, handler: {
                [weak self] _ in
                self?.publish()
            }))
        alertSheet.addAction(UIAlertAction(
            title: NSLocalizedString("Share file (pre-downloaded)", comment: "Action.shareFile"),
            style: .default, handler: {
                [weak self] _ in
                guard let url = self?.viewModel.file.value else { return }
                self?.share(url: url)
            }))
        if viewModel.file.value == nil {
            alertSheet.actions.last?.isEnabled = false
        }
        present(alertSheet, animated: true)
    }
    // Delete
    @objc private func rToolBarButtonClicked() {
        guard !onAction else { return }
        // AlertSheet
        let alertSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertSheet.addAction(UIAlertAction(
            title: NSLocalizedString("Cancel", comment: "Action.cancel"),
            style: .cancel, handler: nil))
        alertSheet.addAction(UIAlertAction(
            title: NSLocalizedString("Delete", comment: "Action.delete"),
            style: .destructive, handler: {
                [weak self] _ in
                self?.delete()
            }))
        // permanently delete with confirmation
        let errorStruct = ErrorStruct(
            title: "",
            message: NSLocalizedString("Do you really want to delete this file permanently?",
                                       comment: "Confirm.permanentlyDeleteMessage"),
            decisionNeeded: true,
            actionHandler: {[weak self] action in
                self?.delete(permanently: "true")
            },
            completion: nil)
        let permDelAction = UIAlertAction(
            title: NSLocalizedString("Delete permanently",
                                     comment: "Action.deletePermanently"),
            style: .default, handler: {
                [weak self] _ in
                self?.showError(errorStruct: errorStruct)
            })
        alertSheet.addAction(permDelAction)
        present(alertSheet, animated: true, completion: nil)
    }
    // show/hide top, bottom Bars for imageView
    @objc private func imageViewClicked () {
        let hide = !(navigationController?.isNavigationBarHidden ?? true
                     || navigationController?.isToolbarHidden ?? true)
        navigationController?.setToolbarHidden      (hide, animated: true)
        navigationController?.setNavigationBarHidden(hide, animated: true)
//        fileInfoLabel.isHidden = hide
        view.backgroundColor = hide ? Const.Colors.detVCFullScrnColor :
                                      Const.Colors.detVCScrnWBarsColor
    }
    
    deinit {
        viewModel.progress.value = nil
        // return real device orientation after manual configuration
        UIDevice.current.setValue(lastOrientation.rawValue, forKey: "orientation")
        print("Deinit: ", self)
    }
}
