//
//  MissionRepositoryImpl.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/11/25.
//

import Foundation
import RxSwift

final class MissionRepositoryImpl: MissionRepository {
    private let firestoreManager: FirestoreManagerProtocol
    private let authRepository: AuthRepository // 타입 지정을 프로토콜로 못함: 필요한 메서드가 프로토콜에 없음
    
    init(firestoreManager: FirestoreManagerProtocol = FirestoreManager(), authRepository: AuthRepository = AuthRepository(authManager: AuthManager(), firestoreManager: FirestoreManager())) {
        self.firestoreManager = firestoreManager
        self.authRepository = authRepository
    }
    
    /// 샘플 미션 데이터 로드
    /// - Returns: 샘플 미션 JSON 데이터(총 100개)
    func loadSampleMission() -> Single<[SampleMission]> {
        return Single.create { [weak self] single in
            guard let self else {
                return Disposables.create()
            }
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
    
    /// 멤버 데이터 패치
    /// - Parameter groupID: getCurrentGroupID()를 호출하여 groupID를 얻을 수 있음
    /// - Returns: 도메인 레이어 멤버 모델
    func fetchMembers(ofGroup groupID: String) -> Observable<[Member]> {
//        return firestoreManager.fetchMembers(groupId: groupID)
//            .map { $0.map { $0.toDomainModel() } }
        
        // 테스트: 위 주석 다시 살리고, 아래는 나중에 지우세요!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
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
    
    /// 현재 사용자의 그룹 ID 반환
    /// - Returns: 그룹 ID String
    func getCurrentGroupID() -> Observable<String> {
        // authRepository.getCurrentGroupID()
        
        // 테스트: 위 주석 다시 살리고, 아래는 나중에 지우세요!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        return Observable.create { observer in
            observer.onNext("dummyID")
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
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
