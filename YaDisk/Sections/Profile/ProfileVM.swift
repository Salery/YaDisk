//
//  ProfileVM.swift
//  YaDisk
//
//  Created by Devel on 16.08.2022.
//

import Foundation
import Shared
import YaAPI

protocol ProfileVMProtocol: VMProtocol {
    var profileData: Box<ProfileData?> { get }
    func getData()
}

final class ProfileVM: VMClass, ProfileVMProtocol {
    let profileData: Box<ProfileData?> = Box(value: nil)
    
    func getData() {
        YaFileManager().getUserInfo {[weak self] userInfo, error in
            guard let self = self else { return }
            self.auth()
            if let userInfo = userInfo {
                self.profileData.value = ProfileModel(userInfo: userInfo).getProfileData()
            } else if let error = error,
                      error != .cantAuthWithToken
                        && error != .noConnectionToDisk {
                self.errorHandled.value = error.errorStruct
            }
        }
    }
    
    override init() {
        super.init()
        getData()
    }
}
