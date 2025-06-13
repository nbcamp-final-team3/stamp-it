//
//  FirestoreManager.swift
//  StampIt-Project
//
//  Created by iOS study on 6/5/25.
//

import Foundation
import FirebaseFirestore
import Firebase
import RxSwift

// MARK: - FirestoreManager Protocol
protocol FirestoreManagerProtocol {
    
    // Network 관련
    func checkNetworkConnection() -> Observable<Bool>
    
    // User 관련
    func fetchUserOnce(userId: String) -> Observable<UserFirestore>
    func fetchUser(userId: String) -> Observable<UserFirestore>
    func createUser(_ user: UserFirestore) -> Observable<Void>
    func updateUser(_ user: UserFirestore) -> Observable<Void>
    func deleteUser(userId: String) -> Observable<Void>
    func updateUserNickname(userId: String, nickname: String, changedAt: Date) -> Observable<Void>

    // Group 관련
    func fetchGroup(groupId: String) -> Observable<GroupFirestore>
    func createGroup(_ group: GroupFirestore) -> Observable<Void>
    func updateGroup(_ group: GroupFirestore) -> Observable<Void>
    func deleteGroup(groupId: String) -> Observable<Void>
    func updateGroupName(groupId: String, name: String, changedAt: Date) -> Observable<Void>

    // Member 관련
    func fetchMembers(groupId: String) -> Observable<[MemberFirestore]>
    func addMember(groupId: String, member: MemberFirestore) -> Observable<Void>
    func removeMember(groupId: String, userId: String) -> Observable<Void>
    
    // Mission 관련
    func fetchMissions(groupId: String) -> Observable<[MissionFirestore]>
    func createMission(groupId: String, mission: MissionFirestore) -> Observable<Void>
    func updateMission(groupId: String, mission: MissionFirestore) -> Observable<Void>
    func deleteMission(groupId: String, missionId: String) -> Observable<Void>
    
    // Sticker 관련
    func fetchStickers(userId: String, month: String) -> Observable<[StickerFirestore]>
    func addSticker(_ sticker: StickerFirestore) -> Observable<Void>
    
    // Invite 관련
    func fetchInvite(inviteCode: String) -> Observable<InviteFirestore>
    func createInvite(_ invite: InviteFirestore) -> Observable<Void>
    func deleteInvite(inviteCode: String) -> Observable<Void>
    
    // AppMission 관련
    func fetchAppMissions() -> Observable<[AppMissionFirestore]>
}

// MARK: - FirestoreManager Implementation
final class FirestoreManager: FirestoreManagerProtocol {
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    private let disposeBag = DisposeBag()
    
    // MARK: - Collection References (각 컬렉션 참조)
    private var usersCollection: CollectionReference {
        return db.collection("users")
    }
    
    private var groupsCollection: CollectionReference {
        return db.collection("groups")
    }
    
    private var stickersCollection: CollectionReference {
        return db.collection("stickers")
    }
    
    private var invitesCollection: CollectionReference {
        return db.collection("invites")
    }
    
    private var appMissionsCollection: CollectionReference {
        return db.collection("appMissions")
    }
    
    private func membersCollection(groupId: String) -> CollectionReference {
        return groupsCollection.document(groupId).collection("members")
    }
    
    private func missionsCollection(groupId: String) -> CollectionReference {
        return groupsCollection.document(groupId).collection("missions")
    }
    
    // MARK: - Init
    // ✅ Singleton 제거, 일반 init으로 변경
    init() {}
    
    // MARK: - 네트워크 모니터링 설정
    func checkNetworkConnection() -> Observable<Bool> {
        return Observable.create { observer in
            // 타임아웃 설정
            let timeoutTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                observer.onNext(false)
                observer.onCompleted()
            }
            
            self.db.collection("connection_test").limit(to: 1).getDocuments(source: .server) { _, error in
                timeoutTimer.invalidate()
                
                if error != nil {
                    observer.onNext(false)
                } else {
                    observer.onNext(true)
                }
                observer.onCompleted()
            }
            
            return Disposables.create {
                timeoutTimer.invalidate()
            }
        }
    }
}

// MARK: - User Operations
extension FirestoreManager {
    
    /// 사용자 정보 일회성 조회 (로그인용)
    func fetchUserOnce(userId: String) -> Observable<UserFirestore> {
        return Observable.create { observer in
            self.usersCollection.document(userId)
                .getDocument(source: .server) { documentSnapshot, error in
                    if let error = error {
                        observer.onError(FirestoreError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let document = documentSnapshot, document.exists else {
                        observer.onError(FirestoreError.documentNotFound)
                        return
                    }
                    
                    do {
                        let user = try document.data(as: UserFirestore.self)
                        observer.onNext(user)
                        observer.onCompleted()
                    } catch {
                        observer.onError(FirestoreError.decodingFailed(error.localizedDescription))
                    }
                }
            
            return Disposables.create()
        }
    }
    
    /// 사용자 정보 실시간 조회 (스냅샷 리스너)
    func fetchUser(userId: String) -> Observable<UserFirestore> {
        return Observable.create { observer in
            let listener = self.usersCollection.document(userId)
                .addSnapshotListener { documentSnapshot, error in
                    if let error = error {
                        observer.onError(FirestoreError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let document = documentSnapshot, document.exists else {
                        observer.onError(FirestoreError.documentNotFound)
                        return
                    }
                    
                    do {
                        let user = try document.data(as: UserFirestore.self)
                        observer.onNext(user)
                    } catch {
                        observer.onError(FirestoreError.decodingFailed(error.localizedDescription))
                    }
                }
            
            return Disposables.create {
                listener.remove()
            }
        }
    }
    
    /// 새 사용자 생성
    func createUser(_ user: UserFirestore) -> Observable<Void> {
        return Observable.create { observer in
            do {
                try self.usersCollection.document(user.documentID)
                    .setData(from: user) { error in
                        if let error = error {
                            observer.onError(FirestoreError.createFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
            } catch {
                observer.onError(FirestoreError.encodingFailed(error.localizedDescription))
            }
            
            return Disposables.create()
        }
    }
    
    /// 사용자 정보 업데이트
    func updateUser(_ user: UserFirestore) -> Observable<Void> {
        return Observable.create { observer in
            do {
                try self.usersCollection.document(user.documentID)
                    .setData(from: user, merge: true) { error in
                        if let error = error {
                            observer.onError(FirestoreError.updateFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
            } catch {
                observer.onError(FirestoreError.encodingFailed(error.localizedDescription))
            }
            
            return Disposables.create()
        }
    }
    
    /// 사용자 삭제 (연관 데이터도 함께 삭제)
    func deleteUser(userId: String) -> Observable<Void> {
        return Observable.create { observer in
            let userRef = self.usersCollection.document(userId)
            userRef.delete { error in
                if let error = error {
                    observer.onError(error)
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
    
    /// 닉네임 업데이트
    func updateUserNickname(userId: String, nickname: String, changedAt: Date) -> Observable<Void> {
        return Observable.create { observer in
            self.usersCollection.document(userId).updateData([
                "nickname": nickname,
                "nicknameChangedAt": Timestamp(date: changedAt)
            ]) { error in
                if let error = error {
                    observer.onError(error)
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
}

// MARK: - Group Operations
extension FirestoreManager {
    
    /// 그룹 정보 실시간 조회
    func fetchGroup(groupId: String) -> Observable<GroupFirestore> {
        return Observable.create { observer in
            let listener = self.groupsCollection.document(groupId)
                .addSnapshotListener { documentSnapshot, error in
                    if let error = error {
                        observer.onError(FirestoreError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let document = documentSnapshot, document.exists else {
                        observer.onError(FirestoreError.documentNotFound)
                        return
                    }
                    
                    do {
                        let group = try document.data(as: GroupFirestore.self)
                        observer.onNext(group)
                    } catch {
                        observer.onError(FirestoreError.decodingFailed(error.localizedDescription))
                    }
                }
            
            return Disposables.create {
                listener.remove()
            }
        }
    }
    
    /// 새 그룹 생성
    func createGroup(_ group: GroupFirestore) -> Observable<Void> {
        return Observable.create { observer in
            do {
                try self.groupsCollection.document(group.documentID)
                    .setData(from: group) { error in
                        if let error = error {
                            observer.onError(FirestoreError.createFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
            } catch {
                observer.onError(FirestoreError.encodingFailed(error.localizedDescription))
            }
            
            return Disposables.create()
        }
    }
    
    /// 그룹 정보 업데이트
    func updateGroup(_ group: GroupFirestore) -> Observable<Void> {
        return Observable.create { observer in
            do {
                try self.groupsCollection.document(group.documentID)
                    .setData(from: group, merge: true) { error in
                        if let error = error {
                            observer.onError(FirestoreError.updateFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
            } catch {
                observer.onError(FirestoreError.encodingFailed(error.localizedDescription))
            }
            
            return Disposables.create()
        }
    }
    
    /// 그룹 삭제 (하위 컬렉션도 함께 삭제)
    func deleteGroup(groupId: String) -> Observable<Void> {
        return Observable.create { observer in
            let groupRef = self.groupsCollection.document(groupId)
            let membersRef = groupRef.collection("members")
            let missionsRef = groupRef.collection("missions")
            
            // 1. 멤버 컬렉션 삭제
            membersRef.getDocuments { snapshot, error in
                if let error = error {
                    observer.onError(error)
                    return
                }
                let batch = Firestore.firestore().batch()
                snapshot?.documents.forEach { doc in
                    batch.deleteDocument(doc.reference)
                }
                // 2. 미션 컬렉션 삭제
                missionsRef.getDocuments { snapshot, error in
                    if let error = error {
                        observer.onError(error)
                        return
                    }
                    snapshot?.documents.forEach { doc in
                        batch.deleteDocument(doc.reference)
                    }
                    // 3. 그룹 문서 삭제
                    batch.deleteDocument(groupRef)
                    batch.commit { error in
                        if let error = error {
                            observer.onError(error)
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
                }
            }
            return Disposables.create()
        }
    }

    
    /// 그룹명 업데이트
    func updateGroupName(groupId: String, name: String, changedAt: Date) -> Observable<Void> {
        return Observable.create { observer in
            self.groupsCollection.document(groupId).updateData([
                "name": name,
                "nameChangedAt": Timestamp(date: changedAt)
            ]) { error in
                if let error = error {
                    observer.onError(error)
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
}

// MARK: - Member Operations
extension FirestoreManager {
    
    /// 그룹 멤버 목록 실시간 조회
    func fetchMembers(groupId: String) -> Observable<[MemberFirestore]> {
        return Observable.create { observer in
            let listener = self.membersCollection(groupId: groupId)
                .addSnapshotListener { querySnapshot, error in
                    if let error = error {
                        observer.onError(FirestoreError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        observer.onNext([])
                        return
                    }
                    
                    do {
                        let members = try documents.compactMap { document -> MemberFirestore? in
                            return try document.data(as: MemberFirestore.self)
                        }
                        observer.onNext(members)
                    } catch {
                        observer.onError(FirestoreError.decodingFailed(error.localizedDescription))
                    }
                }
            
            return Disposables.create {
                listener.remove()
            }
        }
    }
    
    /// 그룹에 새 멤버 추가
    func addMember(groupId: String, member: MemberFirestore) -> Observable<Void> {
        return Observable.create { observer in
            do {
                try self.membersCollection(groupId: groupId).document(member.documentID)
                    .setData(from: member) { error in
                        if let error = error {
                            observer.onError(FirestoreError.createFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
            } catch {
                observer.onError(FirestoreError.encodingFailed(error.localizedDescription))
            }
            
            return Disposables.create()
        }
    }
    
    /// 그룹에서 멤버 제거
    func removeMember(groupId: String, userId: String) -> Observable<Void> {
        return Observable.create { observer in
            self.membersCollection(groupId: groupId).document(userId)
                .delete { error in
                    if let error = error {
                        observer.onError(FirestoreError.deleteFailed(error.localizedDescription))
                    } else {
                        observer.onNext(())
                        observer.onCompleted()
                    }
                }
            
            return Disposables.create()
        }
    }
}

// MARK: - Mission Operations
extension FirestoreManager {
    
    /// 그룹 미션 목록 실시간 조회
    func fetchMissions(groupId: String) -> Observable<[MissionFirestore]> {
        return Observable.create { observer in
            let listener = self.missionsCollection(groupId: groupId)
                .addSnapshotListener { querySnapshot, error in
                    if let error = error {
                        observer.onError(FirestoreError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        observer.onNext([])
                        return
                    }
                    
                    do {
                        let missions = try documents.compactMap { document -> MissionFirestore? in
                            return try document.data(as: MissionFirestore.self)
                        }
                        observer.onNext(missions)
                    } catch {
                        observer.onError(FirestoreError.decodingFailed(error.localizedDescription))
                    }
                }
            
            return Disposables.create {
                listener.remove()
            }
        }
    }
    
    /// 새 미션 생성
    func createMission(groupId: String, mission: MissionFirestore) -> Observable<Void> {
        return Observable.create { observer in
            do {
                try self.missionsCollection(groupId: groupId).document(mission.documentID)
                    .setData(from: mission) { error in
                        if let error = error {
                            observer.onError(FirestoreError.createFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
            } catch {
                observer.onError(FirestoreError.encodingFailed(error.localizedDescription))
            }
            
            return Disposables.create()
        }
    }
    
    /// 미션 정보 업데이트
    func updateMission(groupId: String, mission: MissionFirestore) -> Observable<Void> {
        return Observable.create { observer in
            do {
                try self.missionsCollection(groupId: groupId).document(mission.documentID)
                    .setData(from: mission, merge: true) { error in
                        if let error = error {
                            observer.onError(FirestoreError.updateFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
            } catch {
                observer.onError(FirestoreError.encodingFailed(error.localizedDescription))
            }
            
            return Disposables.create()
        }
    }
    
    /// 미션 삭제
    func deleteMission(groupId: String, missionId: String) -> Observable<Void> {
        return Observable.create { observer in
            self.missionsCollection(groupId: groupId).document(missionId)
                .delete { error in
                    if let error = error {
                        observer.onError(FirestoreError.deleteFailed(error.localizedDescription))
                    } else {
                        observer.onNext(())
                        observer.onCompleted()
                    }
                }
            
            return Disposables.create()
        }
    }
}

// MARK: - Sticker Operations
extension FirestoreManager {
    
    /// 특정 사용자의 월별 스티커 조회
    func fetchStickers(userId: String, month: String) -> Observable<[StickerFirestore]> {
        return Observable.create { observer in
            let listener = self.stickersCollection
                .whereField("userId", isEqualTo: userId)
                .whereField("month", isEqualTo: month)
                .addSnapshotListener { querySnapshot, error in
                    if let error = error {
                        observer.onError(FirestoreError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        observer.onNext([])
                        return
                    }
                    
                    do {
                        let stickers = try documents.compactMap { document -> StickerFirestore? in
                            return try document.data(as: StickerFirestore.self)
                        }
                        observer.onNext(stickers)
                    } catch {
                        observer.onError(FirestoreError.decodingFailed(error.localizedDescription))
                    }
                }
            
            return Disposables.create {
                listener.remove()
            }
        }
    }
    
    /// 새 스티커 추가
    func addSticker(_ sticker: StickerFirestore) -> Observable<Void> {
        return Observable.create { observer in
            do {
                try self.stickersCollection.document(sticker.documentID)
                    .setData(from: sticker) { error in
                        if let error = error {
                            observer.onError(FirestoreError.createFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
            } catch {
                observer.onError(FirestoreError.encodingFailed(error.localizedDescription))
            }
            
            return Disposables.create()
        }
    }
}

// MARK: - Invite Operations
extension FirestoreManager {
    
    /// 초대 코드로 초대 정보 조회 (일회성)
    func fetchInvite(inviteCode: String) -> Observable<InviteFirestore> {
        return Observable.create { observer in
            self.invitesCollection.document(inviteCode)
                .getDocument { documentSnapshot, error in
                    if let error = error {
                        observer.onError(FirestoreError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let document = documentSnapshot, document.exists else {
                        observer.onError(FirestoreError.documentNotFound)
                        return
                    }
                    
                    do {
                        let invite = try document.data(as: InviteFirestore.self)
                        observer.onNext(invite)
                        observer.onCompleted()
                    } catch {
                        observer.onError(FirestoreError.decodingFailed(error.localizedDescription))
                    }
                }
            
            return Disposables.create()
        }
    }
    
    /// 새 초대 코드 생성
    func createInvite(_ invite: InviteFirestore) -> Observable<Void> {
        return Observable.create { observer in
            do {
                // ✅ Firestore 자동 Codable 인코딩
                try self.invitesCollection.document(invite.documentID)
                    .setData(from: invite) { error in
                        if let error = error {
                            observer.onError(FirestoreError.createFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
            } catch {
                observer.onError(FirestoreError.encodingFailed(error.localizedDescription))
            }
            
            return Disposables.create()
        }
    }
    
    /// 초대 코드 삭제
    func deleteInvite(inviteCode: String) -> Observable<Void> {
        return Observable.create { observer in
            self.invitesCollection.document(inviteCode)
                .delete { error in
                    if let error = error {
                        observer.onError(FirestoreError.deleteFailed(error.localizedDescription))
                    } else {
                        observer.onNext(())
                        observer.onCompleted()
                    }
                }
            
            return Disposables.create()
        }
    }
}

// MARK: - AppMission Operations
extension FirestoreManager {
    
    /// 앱에서 제공하는 기본 미션 목록 조회 (일회성)
    func fetchAppMissions() -> Observable<[AppMissionFirestore]> {
        return Observable.create { observer in
            self.appMissionsCollection
                .getDocuments { querySnapshot, error in
                    if let error = error {
                        observer.onError(FirestoreError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        observer.onNext([])
                        return
                    }
                    
                    do {
                        let appMissions = try documents.compactMap { document -> AppMissionFirestore? in
                            return try document.data(as: AppMissionFirestore.self)
                        }
                        observer.onNext(appMissions)
                        observer.onCompleted()
                    } catch {
                        observer.onError(FirestoreError.decodingFailed(error.localizedDescription))
                    }
                }
            
            return Disposables.create()
        }
    }
}
