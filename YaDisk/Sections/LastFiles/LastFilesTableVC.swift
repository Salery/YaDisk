//
//  LastFilesTableVC.swift
//  YaDisk
//
//  Created by Devel on 19.07.2022.
//

import UIKit
import Shared

class LastFilesTableVC: UITableViewController, LastFilesViewProtocol {
    let viewModel: LastFilesTableVM
    let navTitle: String
    let navBarAppearanceConnectedColor:    UIColor = Const.Colors.navBarsBgColor
    let navBarAppearanceDisconnectedColor: UIColor = .red
    
    let cellID = "myCell"
    private lazy var refreshCntrl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        return control
    }()
    private lazy var emptyDataLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Empty", comment: "Messaage.emptyData")
        label.textAlignment = .center
        label.font = Const.Fonts.emptDataLblFnt
        label.textColor = Const.Colors.emptDataLblColor
        label.frame.size = CGSize(width: 100, height: 20)
        return label
    }()
    private let activityIndicator   = UIActivityIndicatorView()
    private let centralActIndicator = UIActivityIndicatorView()
    private var firstLoad = true
    private var tableDataOnChange = false
    
    init(viewModel: LastFilesTableVM? = nil, title: String? = nil) {
        self.viewModel = viewModel ?? LastFilesTableVM()
        self.navTitle = title ?? NSLocalizedString("Last files", comment: "Title.lastFiles")
        super.init(nibName: nil, bundle: nil)
        binder ()
        extraBinder()
        NotificationCenter.default.addObserver(
            self, selector: #selector(elementChanged),
            name: NSNotification.Name("com.file.changed"), object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.binder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        centralActIndicatorAnimation(value: true)
        if !viewModel.modifiedData.isEmpty {
            modifiedDataHandler()
        }
    }
    
    private func setupTableView () {
        navigationItem.backButtonTitle = ""
        tableView.register(FilesListCellV.self, forCellReuseIdentifier: cellID)
        tableView.refreshControl = refreshCntrl
        tableView.rowHeight = 50
        tableView.backgroundColor = Const.Colors.viewsMainBgColor
    }
    
    // opens the detailed view and subscribes to data updates
    private func pushVC (detailedInput: DetailedInput) {
        let dViewModel: DetailedVMProtocol = DetailedVM(from: detailedInput)
        let vc = DetailedVC(viewModel: dViewModel)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func modifiedDataHandler () {
        if viewModel.modifiedData.isEmpty { return }
        let deleteArrIndex = viewModel.modifiedData
            .filter({ $0.modifiedType == .deleted })
            .sorted(by: ({$0.index > $1.index}))
            .map { $0.index }
        tableDataOnChange = true
        deleteArrIndex.forEach { viewModel.delete($0) }
        tableDataOnChange = false
        let deleteArr = deleteArrIndex.map { IndexPath.init(row: $0, section: 0) }
        let renameArr = viewModel.modifiedData
            .filter({ $0.modifiedType == .renamed
                && !deleteArrIndex.contains($0.index) })
            .map { IndexPath.init(row: $0.index, section: 0) }
        tableView.beginUpdates()
        if !renameArr.isEmpty { rename(renameArr) }
        if !deleteArr.isEmpty { delete(deleteArr) }
        tableView.endUpdates()
        viewModel.removeModifiedData()
    }
    
    private func delete (_ indexes: [IndexPath]) {
        tableView.deleteRows(at: indexes, with: .automatic)
    }
    private func rename (_ indexes: [IndexPath]) {
        tableView.reloadRows(at: indexes, with: .automatic)
    }
    
    private func extraBinder () {
        viewModel.tableData.bind { [weak self] tableData in
            guard let self = self else { return }
            if (tableData ?? []).isEmpty { self.emptyDataLblShow(value: true)}
            else { self.emptyDataLblShow(value: false) }
            self.firstLoad = false
            self.centralActIndicatorAnimation(value: false)
            self.finishRefreshAnimation()
            if !self.tableDataOnChange { self.tableView.reloadData() }
        }
        viewModel.actIndicator.bind { [weak self] value in
            guard let self = self
            else { return }
            self.activityIndicatorAnimation(value: value)
        }
    }
    
    func finishRefreshAnimation () {
        if tableView.refreshControl?.isRefreshing == true {
            tableView.refreshControl?.endRefreshing()
        }
    }
    
    private func activityIndicatorAnimation (value: Bool) {
        if value {
            activityIndicator.frame.size = CGSize(width: 50, height: 50)
            tableView.tableFooterView = activityIndicator
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
            tableView.tableFooterView = nil
        }
    }
    private func centralActIndicatorAnimation (value: Bool) {
        if value && firstLoad {
            centralActIndicator.style = .large
            view.addSubview(centralActIndicator)
            centralActIndicator.center = getScreenCenter()
            centralActIndicator.startAnimating()
        } else if view.subviews.contains(centralActIndicator) {
            centralActIndicator.stopAnimating()
            centralActIndicator.removeFromSuperview()
        }
    }
    private func emptyDataLblShow (value: Bool) {
        if value {
            view.addSubview(emptyDataLabel)
            emptyDataLabel.center = getScreenCenter()
        } else if view.subviews.contains(emptyDataLabel) {
            emptyDataLabel.removeFromSuperview()
        }
    }
    
    private func getScreenCenter () -> CGPoint {
        let safeArea = view.safeAreaLayoutGuide
        return CGPoint(x: safeArea.layoutFrame.midX, y: safeArea.layoutFrame.midY)
    }
    
    @objc private func onRefresh () {
        if viewModel.canRqstData {
            viewModel.getData()
        } else {
            tableView.refreshControl?.endRefreshing()
        }
    }
    
    @objc private func elementChanged (_ notification: Notification) {
        tableDataOnChange = true
        viewModel.detailedDataModified()
        tableDataOnChange = false
        if view.window != nil {
            modifiedDataHandler()
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.tableData.value?.count ?? 0
    }
    
    private lazy var cellUnpublButton = viewModel.identify == "PublicFiles" ? true : false
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let filesListCellInput = viewModel.getDataForCell(index: indexPath.row)
        else  { return UITableViewCell() }
        let vModel: FileListCellVMProtocol = FileListCellVM(from: filesListCellInput)
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID,
                                                 for: indexPath) as? FilesListCellV
        cell?.config(viewModel: vModel, unpublButton: cellUnpublButton)
        cell?.cellDelegate = self
        return cell ?? UITableViewCell()
    }
    
    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let detailedInput = viewModel.getDetailes(index: indexPath.row)
        else  { return }
        if detailedInput.type == .dir {
            let vc = AllFilesTableVC(path: detailedInput.path, title: detailedInput.name)
            navigationController?.pushViewController(vc, animated: true)
        } else {
            pushVC(detailedInput: detailedInput)
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = viewModel.tableData.value?.count ?? 0
        guard !viewModel.actIndicator.value && offset > 0
        else { return }
        let height = scrollView.frame.size.height
        let contentYoffset = scrollView.contentOffset.y
        let distanceFromBottom = scrollView.contentSize.height - contentYoffset
        if distanceFromBottom < height {
            if !viewModel.canRqstData { viewModel.actIndicator.value = true }
            DispatchQueue.global(qos: .background).async { [weak self] in
                if let self = self {
                    while !self.viewModel.canRqstData {
                        // Do nothing
                    }
                    DispatchQueue.main.sync {
                        self.viewModel.getNextPage()
                    }
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(
            self, name: NSNotification.Name("com.file.changed"), object: nil)
    }
}

extension LastFilesTableVC: CellDelegate {
    func unpublButtonClick(cell: FilesListCellV) {
        if let indexPath = tableView.indexPath(for: cell) {
            // AlertSheet
            let alertSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alertSheet.addAction(UIAlertAction(
                title: NSLocalizedString("Cancel", comment: "Action.cancel"),
                style: .cancel, handler: nil))
            alertSheet.addAction(UIAlertAction(
                title: NSLocalizedString("Unpublish", comment: "Action.unpubl"),
                style: .destructive, handler: {
                    [weak self] _ in
                    self?.viewModel.unpublResource(indexPath.row)
                }))
            present(alertSheet, animated: true, completion: nil)
        }
    }
}
