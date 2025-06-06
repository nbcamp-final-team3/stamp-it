//
//  HomeSection.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/6/25.
//

import Foundation


enum HomeItem {
    case member(HomeMember)
    case received(HomeReceivedMission)
    case sended(HomeSendedMission)

    struct HomeMember {
        let nickname: String
        let stickerCount: Int
        let profileImageURL: String
    }

    struct HomeReceivedMission {
        let title: String
        let dueDate: String
        let assigner: String
        let profileImageURL: String
    }

    struct HomeSendedMission {
        let title: String
        let dueDate: String
        let assigneeImageURL: String
        let status: String
    }
}
