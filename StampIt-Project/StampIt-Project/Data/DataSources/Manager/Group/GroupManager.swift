//
//  GroupManager.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import Foundation
import FirebaseFirestore
import Firebase
import RxSwift

// MARK: - GroupManager Implementation
final class GroupManager: GroupManagerProtocol {
    typealias Entity = GroupFirestore
    typealias ID = String
    typealias Query = GroupQuery
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    
    // MARK: - Collection References
    var groupsCollection: CollectionReference {
        return db.collection("groups")
    }
    
    var invitesCollection: CollectionReference {
        return db.collection("invites")
    }
    
    var appMissionsCollection: CollectionReference {
        return db.collection("appMissions")
    }
    
    // MARK: - Init
    init() {}
    
    // MARK: - FullCRUDRepository 프로토콜 구현
    func fetch(id: String) -> Observable<GroupFirestore?> {
        return Observable.create { observer in
            self.groupsCollection.document(id)
                .getDocument(source: .server) { documentSnapshot, error in
                    if let error = error {
                        observer.onError(GroupError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let document = documentSnapshot, document.exists else {
                        observer.onNext(nil)
                        observer.onCompleted()
                        return
                    }
                    
                    do {
                        let group = try document.data(as: GroupFirestore.self)
                        observer.onNext(group)
                        observer.onCompleted()
                    } catch {
                        observer.onError(GroupError.decodingFailed(error.localizedDescription))
                    }
                }
            
            return Disposables.create()
        }
    }
    
    func observe(id: String) -> Observable<GroupFirestore?> {
        return fetchGroup(groupId: id)
            .map { group -> GroupFirestore? in group }
            .catchAndReturn(nil)
    }
    
    func create(_ entity: GroupFirestore) -> Observable<Void> {
        return createGroup(entity)
    }
    
    func update(id: String, entity: GroupFirestore) -> Observable<Void> {
        guard id == entity.documentID else {
            return Observable.error(GroupError.invalidInput("ID 불일치"))
        }
        return updateGroup(entity)
    }
    
    func updateFields(id: String, fields: [String: Any]) -> Observable<Void> {
        return Observable.create { observer in
            self.groupsCollection.document(id).updateData(fields) { error in
                if let error = error {
                    observer.onError(GroupError.updateFailed(error.localizedDescription))
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
    
    func delete(id: String) -> Observable<Void> {
        return deleteGroup(groupId: id)
    }
    
    func fetchList(query: GroupQuery) -> Observable<[GroupFirestore]> {
        return Observable.create { observer in
            var firestoreQuery: FirebaseFirestore.Query = self.groupsCollection
            
            // 쿼리 조건 적용
            firestoreQuery = self.applyQueryConditions(firestoreQuery, query: query)
            
            firestoreQuery.getDocuments { snapshot, error in
                if let error = error {
                    observer.onError(GroupError.fetchFailed(error.localizedDescription))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    observer.onNext([])
                    observer.onCompleted()
                    return
                }
                
                do {
                    let groups = try documents.compactMap { document in
                        try document.data(as: GroupFirestore.self)
                    }
                    observer.onNext(groups)
                    observer.onCompleted()
                } catch {
                    observer.onError(GroupError.decodingFailed(error.localizedDescription))
                }
            }
            return Disposables.create()
        }
    }
    
    func observeList(query: GroupQuery) -> Observable<[GroupFirestore]> {
        return Observable.create { observer in
            var firestoreQuery: FirebaseFirestore.Query = self.groupsCollection
            
            // 쿼리 조건 적용
            firestoreQuery = self.applyQueryConditions(firestoreQuery, query: query)
            
            let listener = firestoreQuery.addSnapshotListener { snapshot, error in
                if let error = error {
                    observer.onError(GroupError.fetchFailed(error.localizedDescription))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    observer.onNext([])
                    return
                }
                
                do {
                    let groups = try documents.compactMap { document in
                        try document.data(as: GroupFirestore.self)
                    }
                    observer.onNext(groups)
                } catch {
                    observer.onError(GroupError.decodingFailed(error.localizedDescription))
                }
            }
            
            return Disposables.create {
                listener.remove()
            }
        }
    }
    
    // MARK: - Private Helper
    private func applyQueryConditions(_ query: FirebaseFirestore.Query, query groupQuery: GroupQuery) -> FirebaseFirestore.Query {
        var result = query
        
        if let groupIds = groupQuery.groupIds, !groupIds.isEmpty {
            result = result.whereField("groupId", in: groupIds)
        }
        
        if let leaderIds = groupQuery.leaderIds, !leaderIds.isEmpty {
            result = result.whereField("leaderId", in: leaderIds)
        }
        
        if let inviteCodes = groupQuery.inviteCodes, !inviteCodes.isEmpty {
            result = result.whereField("inviteCode", in: inviteCodes)
        }
        
        if let nameContains = groupQuery.nameContains, !nameContains.isEmpty {
            result = result.whereField("name", isGreaterThanOrEqualTo: nameContains)
                .whereField("name", isLessThan: nameContains + "\u{f8ff}")
        }
        
        if let createdAfter = groupQuery.createdAfter {
            result = result.whereField("createdAt", isGreaterThan: Timestamp(date: createdAfter))
        }
        
        if let orderBy = groupQuery.orderBy {
            result = result.order(by: orderBy.field, descending: orderBy.descending)
        }
        
        if let limit = groupQuery.limit {
            result = result.limit(to: limit)
        }
        
        return result
    }
    
    // MARK: - 기존 FirestoreManager 메서드들 (하위 호환성)
    
    /// 그룹 정보 실시간 조회
    func fetchGroup(groupId: String) -> Observable<GroupFirestore> {
        return Observable.create { observer in
            let listener = self.groupsCollection.document(groupId)
                .addSnapshotListener { documentSnapshot, error in
                    if let error = error {
                        observer.onError(GroupError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let document = documentSnapshot, document.exists else {
                        observer.onError(GroupError.groupNotFound)
                        return
                    }
                    
                    do {
                        let group = try document.data(as: GroupFirestore.self)
                        observer.onNext(group)
                    } catch {
                        observer.onError(GroupError.decodingFailed(error.localizedDescription))
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
                            observer.onError(GroupError.createFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
            } catch {
                observer.onError(GroupError.encodingFailed(error.localizedDescription))
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
                            observer.onError(GroupError.updateFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
            } catch {
                observer.onError(GroupError.encodingFailed(error.localizedDescription))
            }
            
            return Disposables.create()
        }
    }
    
    /// 그룹 삭제 (하위 컬렉션도 함께 삭제)
    func deleteGroup(groupId: String) -> Observable<Void> {
        return Observable.create { observer in
            let groupRef = self.groupsCollection.document(groupId)
            
            //  새로운 DB 구조에 맞게 수정: memberships, missions, stickers는 루트 컬렉션에서 관리
            let stickersQuery = self.db.collection("stickers").whereField("groupId", isEqualTo: groupId)
            let missionsQuery = self.db.collection("missions").whereField("groupId", isEqualTo: groupId)
            let membershipsQuery = self.db.collection("memberships").whereField("groupId", isEqualTo: groupId)
            let invitesQuery = self.invitesCollection.whereField("groupId", isEqualTo: groupId)
            
            let batch = Firestore.firestore().batch()
            
            // 1. 스티커 삭제
            stickersQuery.getDocuments { stickersSnapshot, error in
                if let error = error {
                    observer.onError(GroupError.deleteFailed(error.localizedDescription))
                    return
                }
                stickersSnapshot?.documents.forEach { doc in
                    batch.deleteDocument(doc.reference)
                }
                
                // 2. 미션 삭제
                missionsQuery.getDocuments { missionsSnapshot, error in
                    if let error = error {
                        observer.onError(GroupError.deleteFailed(error.localizedDescription))
                        return
                    }
                    missionsSnapshot?.documents.forEach { doc in
                        batch.deleteDocument(doc.reference)
                    }
                    
                    // 3. 멤버십 삭제
                    membershipsQuery.getDocuments { membershipsSnapshot, error in
                        if let error = error {
                            observer.onError(GroupError.deleteFailed(error.localizedDescription))
                            return
                        }
                        membershipsSnapshot?.documents.forEach { doc in
                            batch.deleteDocument(doc.reference)
                        }
                        
                        // 4. 초대 코드 삭제
                        invitesQuery.getDocuments { invitesSnapshot, error in
                            if let error = error {
                                observer.onError(GroupError.deleteFailed(error.localizedDescription))
                                return
                            }
                            invitesSnapshot?.documents.forEach { doc in
                                batch.deleteDocument(doc.reference)
                            }
                            
                            // 5. 그룹 문서 삭제
                            batch.deleteDocument(groupRef)
                            
                            // 배치 커밋
                            batch.commit { error in
                                if let error = error {
                                    observer.onError(GroupError.deleteFailed(error.localizedDescription))
                                } else {
                                    observer.onNext(())
                                    observer.onCompleted()
                                }
                            }
                        }
                    }
                }
            }
            
            return Disposables.create()
        }
    }
    
    /// 그룹명 업데이트
    func updateGroupName(groupId: String, name: String, changedAt: Date) -> Observable<Void> {
        return updateFields(id: groupId, fields: [
            "name": name,
            "nameChangedAt": Timestamp(date: changedAt)
        ])
    }
    
    /// 그룹 리더 변경 (그룹탈퇴, 리더위임)
    func updateGroupLeader(groupId: String, newLeaderId: String) -> Observable<Void> {
        return updateFields(id: groupId, fields: ["leaderId": newLeaderId])
    }
    
    /// 그룹의 현재 초대 코드 조회 (그룹 설정용)
    func fetchGroupInviteCode(groupId: String) -> Observable<String> {
        return fetchGroup(groupId: groupId)
            .map { group in
                return group.inviteCode
            }
    }
    
    /// 초대 코드로 그룹 정보 조회 (초대 검증용)
    func fetchGroupByInviteCode(inviteCode: String) -> Observable<GroupFirestore> {
        return fetchList(query: .byInviteCode(inviteCode))
            .map { groups -> GroupFirestore in
                guard let group = groups.first else {
                    throw GroupError.groupNotFound
                }
                return group
            }
    }
    
    // MARK: - 초대 코드 관리
    
    /// 초대 코드로 초대 정보 조회 (일회성)
    func fetchInvite(inviteCode: String) -> Observable<InviteFirestore> {
        return Observable.create { observer in
            self.invitesCollection.document(inviteCode)
                .getDocument { documentSnapshot, error in
                    if let error = error {
                        observer.onError(GroupError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let document = documentSnapshot, document.exists else {
                        observer.onError(GroupError.inviteNotFound)
                        return
                    }
                    
                    do {
                        let invite = try document.data(as: InviteFirestore.self)
                        observer.onNext(invite)
                        observer.onCompleted()
                    } catch {
                        observer.onError(GroupError.decodingFailed(error.localizedDescription))
                    }
                }
            
            return Disposables.create()
        }
    }
    
    /// 새 초대 코드 생성
    func createInvite(_ invite: InviteFirestore) -> Observable<Void> {
        return Observable.create { observer in
            do {
                try self.invitesCollection.document(invite.documentID)
                    .setData(from: invite) { error in
                        if let error = error {
                            observer.onError(GroupError.createFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
            } catch {
                observer.onError(GroupError.encodingFailed(error.localizedDescription))
            }
            
            return Disposables.create()
        }
    }
    
    /// 초대 코드 삭제 (만료, 사용 완료 시)
    func deleteInvite(inviteCode: String) -> Observable<Void> {
        return Observable.create { observer in
            self.invitesCollection.document(inviteCode).delete { error in
                if let error = error {
                    observer.onError(GroupError.deleteFailed(error.localizedDescription))
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
    
    /// 특정 사용자가 생성한 모든 초대 코드 삭제 (유저 탈퇴 시)
    func deleteUserInvites(userId: String) -> Observable<Void> {
        return Observable.create { observer in
            self.invitesCollection.whereField("invitedBy", isEqualTo: userId)
                .getDocuments { snapshot, error in
                    if let error = error {
                        observer.onError(GroupError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        observer.onNext(())
                        observer.onCompleted()
                        return
                    }
                    
                    let batch = Firestore.firestore().batch()
                    documents.forEach { doc in
                        batch.deleteDocument(doc.reference)
                    }
                    
                    batch.commit { error in
                        if let error = error {
                            observer.onError(GroupError.deleteFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
                }
            
            return Disposables.create()
        }
    }
    
    /// 특정 그룹의 모든 초대 코드 삭제 (그룹 삭제 시)
    func deleteGroupInvites(groupId: String) -> Observable<Void> {
        return Observable.create { observer in
            self.invitesCollection.whereField("groupId", isEqualTo: groupId)
                .getDocuments { snapshot, error in
                    if let error = error {
                        observer.onError(GroupError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        observer.onNext(())
                        observer.onCompleted()
                        return
                    }
                    
                    let batch = Firestore.firestore().batch()
                    documents.forEach { doc in
                        batch.deleteDocument(doc.reference)
                    }
                    
                    batch.commit { error in
                        if let error = error {
                            observer.onError(GroupError.deleteFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
                }
            
            return Disposables.create()
        }
    }
    
    // MARK: - 앱 미션 관리
    
    /// 앱 미션 목록 조회 (미션 생성 시 템플릿용)
    func fetchAppMissions() -> Observable<[AppMissionFirestore]> {
        return Observable.create { observer in
            self.appMissionsCollection.getDocuments { snapshot, error in
                if let error = error {
                    observer.onError(GroupError.fetchFailed(error.localizedDescription))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    observer.onNext([])
                    observer.onCompleted()
                    return
                }
                
                do {
                    let appMissions = try documents.compactMap { document in
                        try document.data(as: AppMissionFirestore.self)
                    }
                    observer.onNext(appMissions)
                    observer.onCompleted()
                } catch {
                    observer.onError(GroupError.decodingFailed(error.localizedDescription))
                }
            }
            
            return Disposables.create()
        }
    }
}
