//
//  MissionRepositoryImpl.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/11/25.
//

import Foundation
import RxSwift
import FirebaseCore
import CoreData

final class MissionRepositoryImpl: MissionRepository {
    private let missionManager: any MissionManagerProtocol
    private let membershipManager: any MembershipManagerProtocol
    private let authRepository: any AuthRepositoryProtocol
    private let context: NSManagedObjectContext
    
    init(
        missionManager: any MissionManagerProtocol,
        membershipManager: any MembershipManagerProtocol,
        authRepository: any AuthRepositoryProtocol,
        context: NSManagedObjectContext
    ) {
        self.missionManager = missionManager
        self.membershipManager = membershipManager
        self.authRepository = authRepository
        self.context = context
    }
    
    // 샘플 미션 데이터 로드
    func loadSampleMission() -> Single<[SampleMission]> {
        return Single.create { [weak self] single in
            guard let self else { return Disposables.create() }
            
            do {
                let houses: [SampleMission] = try load("house+category.json")
                let families: [SampleMission] = try load("family+category.json")
                let healthAndLearning: [SampleMission] = try load("health+learning+category.json")
                single(.success(houses + families + healthAndLearning))
            } catch {
                single(.failure(error))
            }
            return Disposables.create()
        }
    }
    
    // 멤버 데이터 패치
    func fetchMembers(ofGroup groupID: String) -> Observable<[Member]> {
        return membershipManager.fetchMembers(groupId: groupID)
            .map { memberships in
                memberships.map { $0.toDomainModel() }
            }
    }
    
    // 현재 로그인된 사용자의 정보 가져오기
    func getCurrentUser() -> Observable<User?> {
        authRepository.getCurrentUser()
    }
    
    // 새 미션 생성
    func createMission(groupId: String, mission: Mission) -> Observable<Void> {
        // 카테고리 String 타입 변환
        let category: String = {
            switch mission.category {
            case .chore:
                return "chore"
            case .communication:
                return "communication"
            case .health:
                return "health"
            case .learning:
                return "learning"
            case .custom:
                return "custom"
            }
        }()
        
        // 도메인 레이어 Mission 모델 -> 데이터 레이어 MissionFirestore 모델
        let missionFirestore = MissionFirestore(
            missionId: mission.missionID,
            groupId: groupId,
            title: mission.title,
            assignedBy: mission.assignedBy,
            assignedTo: mission.assignedTo,
            createDate: Timestamp(date: mission.createDate),
            dueDate: Timestamp(date: mission.dueDate),
            category: category,
            status: MissionFirestore.Status.assigned.rawValue,
            missionType: MissionFirestore.MissionType.app.rawValue
        )
        
        return missionManager.createMission(groupId: groupId, mission: missionFirestore)
    }
    
    // 샘플 미션 JSON 로드 헬퍼
    private func load<T: Decodable>(_ filename: String) throws -> T {
        let data: Data
        
        guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
        else {
            throw NSError(
                domain: "loadSampleMission",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Couldn't find \(filename) in main bundle."]
            )
        }
        
        do {
            data = try Data(contentsOf: file)
        } catch {
            throw NSError(
                domain: "loadSampleMission",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Couldn't load \(filename) from main bundle:\n\(error)"]
            )
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NSError(
                domain: "loadSampleMission",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Couldn't parse \(filename) as \(T.self):\n\(error)"]
            )
        }
    }
    
    // 미션 1개 패치
    func fetchMission(widh id: String) -> Observable<Mission?> {
        missionManager.fetch(id: id).map { $0?.toDomainModel() }
    }
    
    // 샘플 미션 전체를 코어데이터에 저장
    func saveAllSampleMissions(missions: [SampleMission]) {
        missions.forEach {
            saveSampleMission(missionId: $0.missionId,
                              title: $0.title,
                              category: $0.category,
                              isFavorite: $0.isFavorite,
                              score: $0.score,
                              timestamp: $0.timestamp)
        }
    }
    
    // 샘플 미션을 코어데이터에 저장
    private func saveSampleMission(missionId: String, title: String, category: MissionCategory, isFavorite: Bool = false, score: Double = 0.0, timestamp: Date = .now) {
        let mission = SampleMissionEntity(context: context)
        mission.missionId = missionId
        mission.title = title
        mission.category = category
        mission.isFavorite = isFavorite
        mission.score = score
        mission.timestamp = timestamp
        
        do {
            try context.save()
        } catch {
            print("Failed to save Core Data changes: \(error)")
        }
    }
    
    // 코어데이터 샘플 미션을 패치
    func fetchSampleMission() -> [SampleMission] {
        let fetchRequest: NSFetchRequest<SampleMissionEntity> = SampleMissionEntity.fetchRequest()
        
        do {
            let missions = try context.fetch(fetchRequest)
            return missions.map { mission in
                return SampleMission(missionId: mission.missionId ?? "",
                                     title: mission.title ?? "",
                                     description: nil,
                                     category: mission.category,
                                     isFavorite: mission.isFavorite,
                                     score: mission.score,
                                     timestamp: mission.timestamp)
            }
        } catch {
            print("Failed to fetch Core Data: \(error)")
            return []
        }
    }
    
    // 코어데이터 특정 샘플 미션을 패치
    func fetchSampleMission(withId missionId: String) -> [SampleMission] {
        let fetchRequest: NSFetchRequest<SampleMissionEntity> = SampleMissionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "missionId == %@", missionId)
        
        do {
            let missions = try context.fetch(fetchRequest)
            guard !missions.isEmpty else { return [] }
            
            return missions.map { mission in
                return SampleMission(missionId: mission.missionId ?? "",
                                     title: mission.title ?? "",
                                     description: nil,
                                     category: mission.category,
                                     isFavorite: mission.isFavorite,
                                     score: mission.score,
                                     timestamp: mission.timestamp)
            }
        } catch {
            print("Failed to fetch Core Data: \(error)")
            return []
        }
    }
    
    // 코어데이터 샘플 미션 업데이트
    func updateSampleMission(mission: SampleMission) {
        let fetchRequest: NSFetchRequest<SampleMissionEntity> = SampleMissionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "missionId == %@", mission.missionId)
        
        do {
            let missions = try context.fetch(fetchRequest)
            guard !missions.isEmpty else { return }
            
            missions.forEach {
                $0.isFavorite = mission.isFavorite
                if $0.score != mission.score {
                    $0.score = mission.score
                    $0.timestamp = mission.timestamp // score가 변경되면 timestamp도 변경
                }
            }
            
            try context.save()
        } catch {
            print("Failed to fetch or save Core Data recentBook: \(error)")
        }
    }
    
    // 전달한 미션 정보를 코어데이터에 저장
    func saveMissionData(title: String, assigneeId: String, assigneeNickname: String, createDate: Date, dueDate: Date, category: MissionCategory) {
        let mission = MissionDataEntity(context: context)
        mission.title = title
        mission.assigneeId = assigneeId
        mission.assigneeNickname = assigneeNickname
        mission.createDate = createDate
        mission.dueDate = dueDate
        mission.category = category
        
        do {
            try context.save()
        } catch {
            print("Failed to save Core Data changes: \(error)")
        }
    }
    
    // 코어데이터 미션 데이터를 패치
    func fetchMissionData() -> [MissionData] {
        let fetchRequest: NSFetchRequest<MissionDataEntity> = MissionDataEntity.fetchRequest()
        
        do {
            let missions = try context.fetch(fetchRequest)
            return missions.map { mission in
                return MissionData(title: mission.title ?? "",
                                   assigneeId: mission.assigneeId ?? "",
                                   assigneeNickname: mission.assigneeNickname ?? "",
                                   createDate: mission.createDate ?? .now,
                                   dueDate: mission.dueDate ?? .now,
                                   category: mission.category)
            }
        } catch {
            print("Failed to fetch Core Data: \(error)")
            return []
        }
    }
}
