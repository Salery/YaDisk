//
//  Const.swift
//  Shared
//
//  Created by Devel on 01.07.2022.
//

import UIKit
public enum Const {
    public enum Fonts {
        public static let navTitleFont   = UIFont.systemFont(ofSize: 17)
        public static let onboardingFont = UIFont.systemFont(ofSize: 17)
        public static let filesNameFont  = UIFont.systemFont(ofSize: 15)
        public static let filesInfFont   = UIFont.systemFont(ofSize: 13)
        public static let flsInfFontDet  = UIFont.systemFont(ofSize: 14)
        public static let downloadFont   = UIFont.systemFont(ofSize: 25)
        public static let dwnldCountFont = UIFont.systemFont(ofSize: 25, weight: .semibold)
        public static let withoutViewFnt = UIFont.systemFont(ofSize: 17)
        public static let emptDataLblFnt = UIFont.systemFont(ofSize: 17)
        public static let capacityLblFnt = UIFont.systemFont(ofSize: 24)
        public static let uInfoLblFnt    = UIFont.systemFont(ofSize: 17)
    }
    public enum Colors {
        public static let viewsMainBgColor   = UIColor.tertiarySystemBackground
        public static let navBarsBgColor     = UIColor.secondarySystemBackground
        public static let windowBgColor      = UIColor.systemBackground
        public static let filesNameFontColor = UIColor.label
        public static let filesInfColor      = UIColor.secondaryLabel
        public static let filesInfshdwColor  = UIColor.white
        public static let dateCreatedColor   = UIColor.tertiaryLabel
        public static let cellIconBgColor    = UIColor(red: 0.965, green: 0.965, blue: 0.965, alpha: 1)
        public static let rowSeparatorColor  = UIColor.separator.cgColor
        public static let downloadFontColor:   UIColor = .systemGray
        public static let dwnldCountFontColor: UIColor = .systemGreen
        public static let detVCFullScrnColor:  UIColor = .black
        public static let detVCScrnWBarsColor: UIColor = viewsMainBgColor
        public static let withoutViewFntColor: UIColor = .secondaryLabel
        public static let dwnlFlBShdwColor   = UIColor.systemGray.cgColor
        public static let emptDataLblColor   = filesInfColor
        public static let capacityLblColor:    UIColor = .secondaryLabel
        public static let uInfoFontColor:      UIColor = .secondaryLabel
        public static let uInfoFreeColor:      UIColor = .systemGreen
        public static let uInfoUsedColor:      UIColor = .systemRed
        public static let uInfoTrashColor:     UIColor = .black
        public static let profileButtonColor:  UIColor = .white
        public static let profileBtnFntColor:  UIColor = .darkGray
        public static let profileBShdwColor  = dwnlFlBShdwColor
        public static let unpublBShdwColor   = dwnlFlBShdwColor
        public static let unpublBHghLtColor:   UIColor = .systemOrange
    }
    public enum Images {
        public static let onboarding1  = UIImage(named: "Onboarding1")
        public static let onboarding2  = UIImage(named: "Onboarding2")
        public static let onboarding3  = UIImage(named: "Onboarding3")
        public static let drive        = UIImage(named: "drive")
        public static let userInfoTab  = UIImage(systemName: "person")
        public static let lastFilesTab = UIImage(systemName: "clock") // calendar, doc
        public static let allFilesTab  = UIImage(systemName: "folder")
        public static let editButton   = UIImage(systemName: "pencil")
        public static let delButton    = UIImage(systemName: "trash") //trash.circle
        public static let publButton   = UIImage(systemName: "link.icloud") // link.circle, link
        public static let logoffButton = UIImage(systemName: "person.badge.minus")
        public static let unpublButton = UIImage(systemName: "icloud.slash.fill")
    }
    public enum Texts {
        public static let onboarding1 = NSLocalizedString("Now all your documents\nare in one place", comment: "Texts.onboarding1") //"Теперь все ваши\nдокументы в одном месте"
        public static let onboarding2 = NSLocalizedString("Can access\nfiles offline", comment: "Texts.onboarding2") //"Доступ к файлам без\nинтернета"
        public static let onboarding3 = NSLocalizedString("Share your files", comment: "Texts.onboarding3") //"Делитесь вашими файлами\nс другими"
    }
    public enum Paths {
        // Save in cache!
        public static let documentDirectoryURL = (try? FileManager.default.url(for: .documentDirectory,
                                                                                  in: .userDomainMask,
                                                                                  appropriateFor: nil,
                                                                                  create: false)) ?? URL(fileURLWithPath: "")
        public static let libraryDirectoryURL =  (try? FileManager.default.url(for: .libraryDirectory,
                                                                                  in: .userDomainMask,
                                                                                  appropriateFor: nil,
                                                                                  create: false)) ?? URL(fileURLWithPath: "")
        public static let picturesDirectoryURL = (try? FileManager.default.url(for: .picturesDirectory,
                                                                                  in: .userDomainMask,
                                                                                  appropriateFor: nil,
                                                                                  create: false)) ?? URL(fileURLWithPath: "")
        public static let moviesDirectoryURL =   (try? FileManager.default.url(for: .moviesDirectory,
                                                                                  in: .userDomainMask,
                                                                                  appropriateFor: nil,
                                                                                  create: false)) ?? URL(fileURLWithPath: "")
        public static let cachesDirectoryURL =   (try? FileManager.default.url(for: .cachesDirectory,
                                                                                  in: .userDomainMask,
                                                                                  appropriateFor: nil,
                                                                                  create: false)) ?? URL(fileURLWithPath: "")
    }
    public enum Sizes {
        public static let delButtonWidth     = 25
        public static let delButtonHeight    = 25
        public static let publButtonWidth    = 34
        public static let publButtonHeight   = 34
        public static let filesInfshdwOffset = CGSize(width: 1, height: 1)
        public static let flAutoDownloadSize: Int64 = 1024*1024*5 // 5 MB
        // DetailedView download button
        public static let dwnlFlBSize        = CGSize(width: 100, height: 100)
        public static let dwnlFlBCrnerRadius = dwnlFlBSize.width / 2
        public static let dwnlFlBShdwOffset  = CGSize(width: dwnlFlBCrnerRadius/10,
                                                      height: dwnlFlBCrnerRadius/10)
        public static let dwnlFlBShdwRadius  = dwnlFlBCrnerRadius/5
        public static let dwnlFlBShdwOpacity:  Float = 0.8
        // Profile public files button
        public static let prflBtnShdwOffset  = CGSize(width: 2, height: 2)
        public static let prflBtnShdwRadius  = prflBtnShdwOffset.width * 2
        public static let prflBtnShdwOpacity:  Float = 0.8
        //
        public static let userInfoCircleSize = CGSize(width: 20, height: 20)
        // cell button
        public static let unpublButtonWidth  = 32.0
        public static let unpublButtonHeight = 32.0
        public static let unpublBShdwOffset  = CGSize(width: 2, height: 2)
        public static let unpublBShdwRadius  = unpublButtonWidth / 10
        public static let unpublBShdwOpacity:  Float = 0.8
    }
}
