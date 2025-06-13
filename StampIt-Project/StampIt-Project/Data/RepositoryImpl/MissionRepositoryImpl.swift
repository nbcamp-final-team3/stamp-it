//
//  MissionRepositoryImpl.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/11/25.
//

import Foundation
import RxSwift
import FirebaseCore

final class MissionRepositoryImpl: MissionRepository {
    private let firestoreManager: FirestoreManagerProtocol
    private let authRepository: AuthRepositoryProtocol
    
    init(firestoreManager: FirestoreManagerProtocol = FirestoreManager(),
         authRepository: AuthRepositoryProtocol = AuthRepository(authManager: AuthManager(), firestoreManager: FirestoreManager())) {
        self.firestoreManager = firestoreManager
        self.authRepository = authRepository
    }
    
    // 샘플 미션 데이터 로드
    func loadSampleMission() -> Single<[SampleMission]> {
        return Single.create { [weak self] single in
            guard let self else { return Disposables.create() }
            
            do {
                let houses: [SampleMission] = try load("house+category.json")
                let families: [SampleMission] = try load("family+category.json")
                single(.success(houses + families))
            } catch {
                single(.failure(error))
            }
            return Disposables.create()
        }
    }
    
    // 멤버 데이터 패치
    func fetchMembers(ofGroup groupID: String) -> Observable<[Member]> {
        return firestoreManager.fetchMembers(groupId: groupID)
            .map { $0.map { $0.toDomainModel() } }
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
            }
        }()
        
        // 도메인 레이어 Mission 모델 -> 데이터 레이어 MissionFirestore 모델
        let missionFirestore = MissionFirestore(
            missionId: mission.missionID,
            title: mission.title,
            assignedBy: mission.assignedBy,
            assignedTo: mission.assignedTo,
            createDate: Timestamp(date: mission.createDate),
            dueDate: Timestamp(date: mission.dueDate),
            category: category,
            status: MissionFirestore.Status.assigned.rawValue,
            missionType: MissionFirestore.MissionType.app.rawValue,
            createdAt: Timestamp(date: mission.createDate))
        
        return firestoreManager.createMission(groupId: groupId, mission: missionFirestore)
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
}
