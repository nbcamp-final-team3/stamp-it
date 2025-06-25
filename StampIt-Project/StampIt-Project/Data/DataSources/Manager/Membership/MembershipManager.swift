//
//  MembershipManager.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import Foundation
import FirebaseFirestore
import Firebase
import RxSwift

// MARK: - MembershipManager Implementation (쿼리 사용 리팩토링)
final class MembershipManager: MembershipManagerProtocol {
    typealias Entity = GroupMembershipFirestore
    typealias ID = String
    typealias Query = MembershipQuery
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    
    // MARK: - Collection Reference
    var membershipCollection: CollectionReference {
        return db.collection("memberships")
    }
    
    // MARK: - Init
    init() {}
    
    // MARK: - FullCRUDRepository 프로토콜 구현
    func fetch(id: String) -> Observable<GroupMembershipFirestore?> {
        return Observable.create { observer in
            self.membershipCollection.document(id)
                .getDocument(source: .server) { documentSnapshot, error in
                    if let error = error {
                        observer.onError(MembershipError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let document = documentSnapshot, document.exists else {
                        observer.onNext(nil)
                        observer.onCompleted()
                        return
                    }
                    
                    do {
                        let membership = try document.data(as: GroupMembershipFirestore.self)
                        observer.onNext(membership)
                        observer.onCompleted()
                    } catch {
                        observer.onError(MembershipError.decodingFailed(error.localizedDescription))
                    }
                }
            
            return Disposables.create()
        }
    }
    
    func observe(id: String) -> Observable<GroupMembershipFirestore?> {
        return Observable.create { observer in
            let listener = self.membershipCollection.document(id)
                .addSnapshotListener { documentSnapshot, error in
                    if let error = error {
                        observer.onError(MembershipError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let document = documentSnapshot, document.exists else {
                        observer.onNext(nil)
                        return
                    }
                    
                    do {
                        let membership = try document.data(as: GroupMembershipFirestore.self)
                        observer.onNext(membership)
                    } catch {
                        observer.onError(MembershipError.decodingFailed(error.localizedDescription))
                    }
                }
            
            return Disposables.create {
                listener.remove()
            }
        }
    }
    
    func create(_ entity: GroupMembershipFirestore) -> Observable<Void> {
        return Observable.create { observer in
            do {
                try self.membershipCollection.document(entity.documentID)
                    .setData(from: entity) { error in
                        if let error = error {
                            observer.onError(MembershipError.createFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
            } catch {
                observer.onError(MembershipError.encodingFailed(error.localizedDescription))
            }
            
            return Disposables.create()
        }
    }
    
    func update(id: String, entity: GroupMembershipFirestore) -> Observable<Void> {
        guard id == entity.documentID else {
            return Observable.error(MembershipError.invalidInput("ID 불일치"))
        }
        
        return Observable.create { observer in
            do {
                try self.membershipCollection.document(entity.documentID)
                    .setData(from: entity, merge: true) { error in
                        if let error = error {
                            observer.onError(MembershipError.updateFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
            } catch {
                observer.onError(MembershipError.encodingFailed(error.localizedDescription))
            }
            
            return Disposables.create()
        }
    }
    
    func updateFields(id: String, fields: [String: Any]) -> Observable<Void> {
        return Observable.create { observer in
            self.membershipCollection.document(id).updateData(fields) { error in
                if let error = error {
                    observer.onError(MembershipError.updateFailed(error.localizedDescription))
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
    
    func delete(id: String) -> Observable<Void> {
        return Observable.create { observer in
            self.membershipCollection.document(id).delete { error in
                if let error = error {
                    observer.onError(MembershipError.deleteFailed(error.localizedDescription))
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
    
    func fetchList(query: MembershipQuery) -> Observable<[GroupMembershipFirestore]> {
        return Observable.create { observer in
            var firestoreQuery: FirebaseFirestore.Query = self.membershipCollection
            
            // 쿼리 조건 적용
            firestoreQuery = self.applyQueryConditions(firestoreQuery, query: query)
            
            firestoreQuery.getDocuments { snapshot, error in
                if let error = error {
                    observer.onError(MembershipError.fetchFailed(error.localizedDescription))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    observer.onNext([])
                    observer.onCompleted()
                    return
                }
                
                do {
                    let memberships = try documents.compactMap { document in
                        try document.data(as: GroupMembershipFirestore.self)
                    }
                    observer.onNext(memberships)
                    observer.onCompleted()
                } catch {
                    observer.onError(MembershipError.decodingFailed(error.localizedDescription))
                }
            }
            return Disposables.create()
        }
    }
    
    func observeList(query: MembershipQuery) -> Observable<[GroupMembershipFirestore]> {
        return Observable.create { observer in
            var firestoreQuery: FirebaseFirestore.Query = self.membershipCollection
            
            // 쿼리 조건 적용
            firestoreQuery = self.applyQueryConditions(firestoreQuery, query: query)
            
            let listener = firestoreQuery.addSnapshotListener { snapshot, error in
                if let error = error {
                    observer.onError(MembershipError.fetchFailed(error.localizedDescription))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    observer.onNext([])
                    return
                }
                
                do {
                    let memberships = try documents.compactMap { document in
                        try document.data(as: GroupMembershipFirestore.self)
                    }
                    observer.onNext(memberships)
                } catch {
                    observer.onError(MembershipError.decodingFailed(error.localizedDescription))
                }
            }
            
            return Disposables.create {
                listener.remove()
            }
        }
    }
    
    // MARK: - Private Helper
    private func applyQueryConditions(_ query: FirebaseFirestore.Query, query membershipQuery: MembershipQuery) -> FirebaseFirestore.Query {
        var result = query
        
        if let membershipIds = membershipQuery.membershipIds, !membershipIds.isEmpty {
            result = result.whereField("membershipId", in: membershipIds)
        }
        
        if let groupIds = membershipQuery.groupIds, !groupIds.isEmpty {
            result = result.whereField("groupId", in: groupIds)
        }
        
        if let userIds = membershipQuery.userIds, !userIds.isEmpty {
            result = result.whereField("userId", in: userIds)
        }
        
        if let isLeaderOnly = membershipQuery.isLeaderOnly, isLeaderOnly {
            result = result.whereField("isLeader", isEqualTo: true)
        }
        
        if let joinedAfter = membershipQuery.joinedAfter {
            result = result.whereField("joinedAt", isGreaterThan: Timestamp(date: joinedAfter))
        }
        
        if let orderBy = membershipQuery.orderBy {
            result = result.order(by: orderBy.field, descending: orderBy.descending)
        }
        
        if let limit = membershipQuery.limit {
            result = result.limit(to: limit)
        }
        
        return result
    }
    
    // MARK: - 기존 FirestoreManager 메서드들 (하위 호환성)
    /// 그룹 멤버 목록 실시간 조회
    func fetchMembers(groupId: String) -> Observable<[GroupMembershipFirestore]> {
        return observeList(query: .byGroup(groupId))
    }
    
    /// 그룹에 새 멤버 추가
    func addMember(groupId: String, member: GroupMembershipFirestore) -> Observable<Void> {
        return create(member)
    }
    
    /// 그룹에서 멤버 제거(내보내기, 그룹 탈퇴)
    func removeMember(groupId: String, userId: String) -> Observable<Void> {
        let membershipId = "\(groupId)_\(userId)"
        return delete(id: membershipId)
    }
    
    /// 멤버 정보 업데이트
    func updateMember(groupId: String, userId: String, query: [String: String]) -> Observable<Void> {
        let membershipId = "\(groupId)_\(userId)"
        return updateFields(id: membershipId, fields: query)
    }
    
    /// 유저 닉네임 업데이트
    func updateMemberNickname(groupId: String, userId: String, nickname: String) -> Observable<Void> {
        let membershipId = "\(groupId)_\(userId)"
        return updateFields(id: membershipId, fields: [
                "nickname": nickname,
                "updatedAt": Timestamp(date: Date())
            ])
    }
    
    /// 유저 프로필 이미지 업데이트
    func updateMemberProfileImage(groupId: String, userId: String, profileImage: String) -> Observable<Void>{
        let membershipId = "\(groupId)_\(userId)"
        
        return updateFields(id: membershipId, fields: [
            "profileImage": profileImage,
            "updatedAt": Timestamp(date: Date())
        ])
    }
    
    
    /// 멤버 리더 상태 업데이트 (그룹 탈퇴 시 사용)
    func updateMemberLeaderStatus(groupId: String, userId: String, isLeader: Bool) -> Observable<Void> {
        let membershipId = "\(groupId)_\(userId)"
        return updateFields(id: membershipId, fields: ["isLeader": isLeader])
    }
    
    func deleteGroupMemberships(groupId: String) -> Observable<Void> {
        return fetchList(query: .byGroup(groupId))
            .flatMap { [weak self] memberships -> Observable<Void> in
                guard let self = self else {
                    return Observable.error(MembershipError.fetchFailed("MembershipManager 인스턴스가 없습니다"))
                }
                let deleteObservables = memberships.map { membership in
                    self.delete(id: membership.documentID)
                }
                return Observable.zip(deleteObservables).map { _ in () }
            }
    }
    
    /// 가장 오래된 멤버 조회 (특정 유저 제외)
    func fetchOldestMember(groupId: String, excludeUserId: String) -> Observable<GroupMembershipFirestore> {
        return fetchList(query: MembershipQuery(
            membershipIds: nil,
            groupIds: [groupId],
            userIds: nil,
            isLeaderOnly: nil,
            joinedAfter: nil,
            orderBy: QueryOrder(field: "joinedAt", descending: false),
            limit: 10
        ))
        .map { memberships -> GroupMembershipFirestore in
            let candidates = memberships.filter { $0.userId != excludeUserId }
            guard let oldest = candidates.first else {
                throw MembershipError.memberNotFound
            }
            return oldest
        }
    }
    
    /// 그룹 멤버 수 조회 (가입 제한 확인용)
    func fetchGroupMemberCount(groupId: String) -> Observable<Int> {
        return fetchList(query: .byGroup(groupId))
            .map { $0.count }
    }
    
    /// 사용자 그룹 변경 (트랜잭션) -  기존 switchUserGroup 메서드 (추후 수정!!!!!!!!!!!!!)
    func switchUserGroup(
        userId: String,
        fromGroupId: String,
        toGroupId: String,
        userNickname: String,
        profileImage: String
    ) -> Observable<Void> {
        return Observable.create { observer in
            
            let batch = Firestore.firestore().batch()
            let userRef = self.db.collection("users").document(userId)
            
            // 1. 사용자 groupId 업데이트
            batch.updateData([
                "groupId": toGroupId,
                "nickname": userNickname,
                "profileImage": profileImage.isEmpty ? "profileImage1" : profileImage
                
            ], forDocument: userRef)
            
            // 2. 기존 그룹 멤버십 삭제
            let oldMembershipId = "\(fromGroupId)_\(userId)"
            let oldMemberRef = self.membershipCollection.document(oldMembershipId)
            batch.deleteDocument(oldMemberRef)
            
            // 3. 새 그룹 멤버십 추가
            let newMembershipId = "\(toGroupId)_\(userId)"
            let newMemberRef = self.membershipCollection.document(newMembershipId)
            let memberData: [String: Any] = [
                "membershipId": newMembershipId,
                "groupId": toGroupId,
                "userId": userId,
                "nickname": userNickname,
                "profileImage": profileImage.isEmpty ? "profileImage1" : profileImage,
                "isLeader": false,
                "joinedAt": Timestamp(date: Date())
            ]
            
            batch.setData(memberData, forDocument: newMemberRef)
            
            // 4. 커밋
            batch.commit { error in
                if let error = error {
                    observer.onError(MembershipError.updateFailed(error.localizedDescription))
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
}
