//
//  TabBarController.swift
//  YaDisk
//
//  Created by Devel on 21.07.2022.
//

import UIKit
import Shared

final class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let attrFontString = [NSAttributedString.Key.font: Const.Fonts.navTitleFont]
        
        let userInfoVC    = ProfileVC()
        let userInfoNav   = UINavigationController(rootViewController: userInfoVC)
        userInfoNav.tabBarItem = UITabBarItem(title: nil,
                                              image: Const.Images.userInfoTab,  tag: 1)
        userInfoNav.navigationBar.titleTextAttributes = attrFontString
        
        let lastFilesVC = LastFilesTableVC()
        let lastFilesNav = UINavigationController(rootViewController: lastFilesVC)
        lastFilesNav.tabBarItem = UITabBarItem(title: nil,
                                               image: Const.Images.lastFilesTab, tag: 2)
        lastFilesNav.navigationBar.titleTextAttributes = attrFontString
        
        let allFilesTitle = NSLocalizedString("All files", comment: "Title.allFiles")
        let allFilesVC = AllFilesTableVC(title: allFilesTitle)
        let allFilesNav  = UINavigationController(rootViewController: allFilesVC)
        allFilesNav.tabBarItem = UITabBarItem(title: nil,
                                              image: Const.Images.allFilesTab,  tag: 3)
        allFilesNav.navigationBar.titleTextAttributes = attrFontString
        
        self.viewControllers = [userInfoNav, lastFilesNav, allFilesNav]
        self.selectedViewController = lastFilesNav
    }
}
