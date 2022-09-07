//
//  ProfileModel.swift
//  YaDisk
//
//  Created by Devel on 17.08.2022.
//

import UIKit
import YaAPI
import Shared

struct ProfileData {
    let segments: [Segment]
    let capacity: Int64
    let used:     Int64
    let trash:    Int64
    let free:     Int64
}
class ProfileModel {
    private let input: UserInfo
    
    init(userInfo: UserInfo) {
        input = userInfo
    }
    
    func getProfileData () -> ProfileData {
        let capacity = input.total_space
        let used     = input.used_space
        let trash    = input.trash_size
        let free     = capacity - used - trash
        let segments = [
            Segment(color: Const.Colors.uInfoFreeColor,  value: CGFloat(free)),
            Segment(color: Const.Colors.uInfoUsedColor,  value: CGFloat(used)),
            Segment(color: Const.Colors.uInfoTrashColor, value: CGFloat(trash)),
        ]
        return ProfileData(segments: segments, capacity: capacity, used: used, trash: trash, free: free)
    }
}
