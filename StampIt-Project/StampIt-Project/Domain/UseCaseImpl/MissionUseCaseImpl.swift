//
//  MissionUseCaseImpl.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/5/25.
//

import Foundation
import RxSwift

struct MissionUseCaseImpl: MissionUseCase {
    private let authRepository: AuthRepositoryProtocol
    private let missionRepositoryImpl: MissionRepository
    private let noticeRepository: NoticeRepositoryProtocol

    init(
        authRepository: AuthRepositoryProtocol,
        missionRepositoryImpl: MissionRepository,
        noticeRepository: NoticeRepositoryProtocol
    ) {
        self.authRepository = authRepository
        self.missionRepositoryImpl = missionRepositoryImpl
        self.noticeRepository = noticeRepository
    }
    
    // 샘플 미션 데이터 로드
    func loadSampleMission() -> Single<[SampleMission]> {
        missionRepositoryImpl.loadSampleMission()
    }
    
    // 멤버 데이터 패치
    func fetchMembers(ofGroup groupID: String) -> Observable<[Member]> {
        missionRepositoryImpl.fetchMembers(ofGroup: groupID)
    }
    
    // 현재 로그인된 사용자의 정보 가져오기
    func getCurrentUser() -> Observable<User?> {
        missionRepositoryImpl.getCurrentUser()
    }
    
    // 새 미션 생성
    func createMission(groupId: String, mission: Mission) -> Observable<Void> {
        missionRepositoryImpl.createMission(groupId: groupId, mission: mission)
            .flatMap { _ -> Observable<String?> in
                // 미션을 전달하는 주체가 되는 유저의 닉네임 전달
                return authRepository.getCurrentUser()
                    .map { $0?.nickname }
            }
            .flatMap { nickname -> Observable<Void> in
                // 미션 받는 사람에게 보낼 알림 생성
                guard let nickname else { return .empty() }
                let notice = Notice(
                    noticeId: UUID().uuidString,
                    title: "새로운 미션 도착",
                    description: "\(nickname)님으로부터 새로운 미션이 도착했어요! 받은 미션을 확인해보세요",
                    category: .newMission,
                    createdAt: Date(),
                    isRead: false
                )
                return noticeRepository.createNotice(notice, receiverId: mission.assignedTo)
            }
    }
    
    // 미션 1개 패치
    func fetchMission(with id: String) -> Observable<StampBoardMission?> {
        missionRepositoryImpl.fetchMission(widh: id)
            .map { $0?.toPresentation() }
    }
    
    // 코어데이터 샘플 미션을 패치
    func fetchSampleMission() -> [SampleMission] {
        missionRepositoryImpl.fetchSampleMission()
    }
    
    // 코어데이터 특정 샘플 미션을 패치
    func fetchSampleMission(withId missionId: String) -> [SampleMission] {
        missionRepositoryImpl.fetchSampleMission(withId: missionId)
    }
    
    // 코어데이터 샘플 미션 업데이트
    func updateSampleMission(mission: SampleMission) {
        missionRepositoryImpl.updateSampleMission(mission: mission)
    }
    
    // 전달한 미션 정보를 코어데이터에 저장
    func saveMissionData(title: String, assigneeId: String, assigneeNickname: String, createDate: Date, dueDate: Date, category: MissionCategory) {
        missionRepositoryImpl.saveMissionData(title: title, assigneeId: assigneeId, assigneeNickname: assigneeNickname, createDate: createDate, dueDate: dueDate, category: category)
    }
    
    // 코어데이터 미션 데이터를 패치
    func fetchMissionData() -> [MissionData] {
        missionRepositoryImpl.fetchMissionData()
    }
}
