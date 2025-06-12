//
//  HomeSection.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/6/25.
//

import Foundation

enum HomeSection: Hashable, CaseIterable {
    case ranking
    case receivedMission
    case sendedMission
}

extension HomeSection {
    var placeholderText: String? {
        switch self {
        case .ranking:
            return nil
        case .receivedMission:
            return "아직 부여된 미션이 없어요!"
        case .sendedMission:
            return "아직 전달한 미션이 없어요!"
        }
    }
}

enum HomeItem: Hashable {
    case member(HomeMember)
    case received(HomeReceivedMission)
    case sended(HomeSendedMission)
    case placeholder(HomeSection)

    var member: HomeMember? {
        if case .member(let member) = self {
            return member
        } else {
            return nil
        }
    }

    var received: HomeReceivedMission? {
        if case .received(let mission) = self {
            return mission
        } else {
            return nil
        }
    }

    var sended: HomeSendedMission? {
        if case .sended(let mission) = self {
            return mission
        } else {
            return nil
        }
    }
}

struct HomeMember: Hashable {
    let memberID: String
    let nickname: String
    let stickerCount: String
    let rank: Int
    let profileImageURL: String?
}

struct HomeReceivedMission: Hashable {
    let missionID: String
    let title: String
    let category: MissionCategory
    let dueDate: String
    let assigner: String
    let isNew: Bool
}

struct HomeSendedMission: Hashable {
    let missionID: String
    let title: String
    let category: MissionCategory
    let dueDate: String
    let assignee: String
    let status: MissionStatus
    let isOverdue: Bool
    let daysLeft: String
}

// 더미데이터
extension HomeItem {
    static let homeMembers: [HomeItem] = [
        .member(HomeMember(memberID: "user1",  nickname: "ChinoFan",     stickerCount: "12", rank: 1,  profileImageURL: "")),
        .member(HomeMember(memberID: "user2",  nickname: "CapuLover",    stickerCount: "8",  rank: 2,  profileImageURL: "")),
        .member(HomeMember(memberID: "user3",  nickname: "StampMaster",  stickerCount: "5",  rank: 3,  profileImageURL: "")),
        .member(HomeMember(memberID: "user4",  nickname: "BusyBee",      stickerCount: "20", rank: 4,  profileImageURL: "")),
        .member(HomeMember(memberID: "user5",  nickname: "NightOwl",     stickerCount: "3",  rank: 5,  profileImageURL: nil)),
        .member(HomeMember(memberID: "user6",  nickname: "EarlyBird",    stickerCount: "15", rank: 6,  profileImageURL: "")),
        .member(HomeMember(memberID: "user7",  nickname: "CodeNinja",    stickerCount: "7",  rank: 7,  profileImageURL: "")),
        .member(HomeMember(memberID: "user8",  nickname: "SwiftWizard",  stickerCount: "10", rank: 8,  profileImageURL: nil)),
        .member(HomeMember(memberID: "user9",  nickname: "DesignGuru",   stickerCount: "0",  rank: 9,  profileImageURL: "")),
        .member(HomeMember(memberID: "user10", nickname: "ProjectKing", stickerCount: "2",  rank: 10, profileImageURL: "")),

    ]

    static let receivedMissions: [HomeItem] = [
        .received(HomeReceivedMission(missionID: "recv1",  title: "방 청소하기",       category: .chore,          dueDate: "2025-06-13", assigner: "다은",    isNew: true)),
        .received(HomeReceivedMission(missionID: "recv2",  title: "Groceries 사오기",  category: .learning,       dueDate: "2025-06-14", assigner: "Alice",   isNew: false)),
        .received(HomeReceivedMission(missionID: "recv3",  title: "운동 30분",         category: .communication,  dueDate: "2025-06-15", assigner: "Bob",     isNew: true)),
        .received(HomeReceivedMission(missionID: "recv4",  title: "독서 1시간",        category: .health,         dueDate: "2025-06-16", assigner: "Charlie", isNew: false)),
        .received(HomeReceivedMission(missionID: "recv5",  title: "코드 리뷰",         category: .chore,          dueDate: "2025-06-17", assigner: "Eve",     isNew: true)),
        .received(HomeReceivedMission(missionID: "recv6",  title: "디자인 피드백 받기", category: .health,         dueDate: "2025-06-18", assigner: "Frank",   isNew: false)),
        .received(HomeReceivedMission(missionID: "recv7",  title: "테스트 작성",       category: .communication,  dueDate: "2025-06-19", assigner: "Grace",   isNew: true)),
        .received(HomeReceivedMission(missionID: "recv8",  title: "팀 미팅 참여",     category: .health,         dueDate: "2025-06-20", assigner: "Hannah",  isNew: false)),
        .received(HomeReceivedMission(missionID: "recv9",  title: "새 기능 조사",     category: .learning,       dueDate: "2025-06-21", assigner: "Ian",     isNew: true)),
        .received(HomeReceivedMission(missionID: "recv10", title: "문서 업데이트",     category: .chore,          dueDate: "2025-06-22", assigner: "Judy",    isNew: false)),

    ]

    static let sendedMissions: [HomeItem] = [
        .sended(HomeSendedMission(missionID: "send1",  title: "보고서 작성",        category: .chore,          dueDate: "2025-06-12", assignee: "다은",    status: .completed,  isOverdue: false, daysLeft: "완료")),
        .sended(HomeSendedMission(missionID: "send2",  title: "UI 디자인 리뷰",     category: .communication,  dueDate: "2025-06-14", assignee: "Charlie", status: .failed,     isOverdue: false, daysLeft: "2일 전")),
        .sended(HomeSendedMission(missionID: "send3",  title: "테스트 케이스 작성", category: .health,         dueDate: "2025-06-10", assignee: "Eve",     status: .failed,     isOverdue: true,  daysLeft: "-2일")),
        .sended(HomeSendedMission(missionID: "send4",  title: "디버깅 모듈 개선",    category: .learning,       dueDate: "2025-06-15", assignee: "Frank",   status: .assigned,   isOverdue: false, daysLeft: "3일 전")),
    ]

}
