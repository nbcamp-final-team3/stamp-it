//
//  NoticeItem.swift
//  StampIt-Project
//
//  Created by daeun on 7/23/25.
//

import UIKit

enum NoticeSection: CaseIterable, Hashable {
    case list
}

struct HomeNotice: Hashable {
    let noticeId: String
    let title: String
    let description: String
    let date: String
    let backgroundColor: UIColor
    let iconImage: UIImage?
}
