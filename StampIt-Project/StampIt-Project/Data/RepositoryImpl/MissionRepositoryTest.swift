//
//  MissionRepositoryTest.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/12/25.
//

import Foundation
import RxSwift
import FirebaseCore

// MissionRepositoryImpl 테스트 클래스
final class MissionRepositoryTest: MissionRepository {
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
    
    // 멤버 더미 데이터 패치
    func fetchMembers(ofGroup groupID: String) -> Observable<[Member]> {
        print("groupID into fetchMembers(): \(groupID)")
        return Observable.create { observer in
            let dummyMembers: [Member] = [
                Member(userID: "12345", nickname: "유진", joinedAt: Date(), isLeader: true),
                Member(userID: "67890", nickname: "엄마", joinedAt: Date(), isLeader: false),
                Member(userID: "112233", nickname: "파덜", joinedAt: Date(), isLeader: false),
                Member(userID: "112433", nickname: "삼동이", joinedAt: Date(), isLeader: false),
            ]
            observer.onNext(dummyMembers)
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    // 유저 더미 데이터 반환
    func getCurrentUser() -> Observable<User?> {
        return Observable.create { observer in
            let user = User(userID: "dummyUserID", nickname: "dummyNickname", profileImageURL: "www.dummyURL.com", boards: [], groupID: "dummyGroupID", groupName: "dummyGroupName", isLeader: false, joinedGroupAt: Date())
            
            observer.onNext(user)
            observer.onCompleted()
            return Disposables.create()
        }
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
        
        return Observable.create { _ in
            print("""
                  mission created.
                  --------------------------------------------
                  ID: \(missionFirestore.missionId)
                  title: \(missionFirestore.title)
                  assignedBy: \(missionFirestore.assignedBy)
                  assignedTo: \(missionFirestore.assignedTo)
                  createDate: \(missionFirestore.createDate)
                  dueDate: \(missionFirestore.dueDate)
                  category: \(missionFirestore.category)
                  status: \(missionFirestore.status)
                  missionType: \(missionFirestore.missionType)
                  createdAt: \(missionFirestore.createdAt)
                  """)
            return Disposables.create()
        }
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
