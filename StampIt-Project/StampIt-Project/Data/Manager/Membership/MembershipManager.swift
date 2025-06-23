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

final class MembershipManager: MembershipManagerProtocol {
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    
    // MARK: - Collection Reference
    private var membershipCollection: CollectionReference {
        return db.collection("groupMemberships")
    }
    
    // MARK: - Init
    init() {}
    
    // MARK: - Membership Operations
    
    /// 그룹 멤버십 목록 실시간 조회
    func fetchMemberships(groupId: String) -> Observable<[GroupMembershipFirestore]> {
        return Observable.create { observer in
            let listener = self.membershipCollection
                .whereField("groupId", isEqualTo: groupId)
                .order(by: "joinedAt", descending: false)
                .addSnapshotListener { querySnapshot, error in
                    if let error = error {
                        observer.onError(MembershipError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        observer.onNext([])
                        return
                    }
                    
                    do {
                        let memberships = try documents.compactMap { document -> GroupMembershipFirestore? in
                            return try document.data(as: GroupMembershipFirestore.self)
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
    
    /// 특정 멤버십 조회
    func fetchMembership(membershipId: String) -> Observable<GroupMembershipFirestore?> {
        return Observable.create { observer in
            self.membershipCollection.document(membershipId)
                .getDocument { documentSnapshot, error in
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
    
    /// 사용자의 모든 멤버십 조회
    func fetchUserMemberships(userId: String) -> Observable<[GroupMembershipFirestore]> {
        return Observable.create { observer in
            let listener = self.membershipCollection
                .whereField("userId", isEqualTo: userId)
                .order(by: "joinedAt", descending: false)
                .addSnapshotListener { querySnapshot, error in
                    if let error = error {
                        observer.onError(MembershipError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        observer.onNext([])
                        return
                    }
                    
                    do {
                        let memberships = try documents.compactMap { document -> GroupMembershipFirestore? in
                            return try document.data(as: GroupMembershipFirestore.self)
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
    
    /// 새 멤버십 생성
    func createMembership(_ membership: GroupMembershipFirestore) -> Observable<Void> {
        return Observable.create { observer in
            do {
                try self.membershipCollection.document(membership.documentID)
                    .setData(from: membership) { error in
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
    
    /// 멤버십 정보 업데이트
    func updateMembership(_ membership: GroupMembershipFirestore) -> Observable<Void> {
        return Observable.create { observer in
            do {
                try self.membershipCollection.document(membership.documentID)
                    .setData(from: membership, merge: true) { error in
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
    
    /// 멤버십 삭제
    func deleteMembership(membershipId: String) -> Observable<Void> {
        return Observable.create { observer in
            self.membershipCollection.document(membershipId)
                .delete { error in
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
    
    /// 사용자를 그룹에 추가
    func addUserToGroup(userId: String, groupId: String, nickname: String, profileImage: String?) -> Observable<Void> {
        let membershipId = "\(groupId)_\(userId)"
        let membership = GroupMembershipFirestore(
            membershipId: membershipId,
            groupId: groupId,
            userId: userId,
            nickname: nickname,
            profileImage: profileImage,
            isLeader: false,
            joinedAt: Timestamp(date: Date())
        )
        
        return createMembership(membership)
    }
    
    /// 사용자를 그룹에서 제거
    func removeUserFromGroup(userId: String, groupId: String) -> Observable<Void> {
        let membershipId = "\(groupId)_\(userId)"
        return deleteMembership(membershipId: membershipId)
    }
    
    /// 멤버십 닉네임 업데이트
    func updateMembershipNickname(membershipId: String, nickname: String) -> Observable<Void> {
        return Observable.create { observer in
            self.membershipCollection.document(membershipId).updateData([
                "nickname": nickname
            ]) { error in
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
    
    /// 멤버십 프로필 이미지 업데이트
    func updateMembershipProfileImage(membershipId: String, profileImage: String) -> Observable<Void> {
        return Observable.create { observer in
            self.membershipCollection.document(membershipId).updateData([
                "profileImage": profileImage
            ]) { error in
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
    
    /// 리더 상태 업데이트
    func updateLeaderStatus(membershipId: String, isLeader: Bool) -> Observable<Void> {
        return Observable.create { observer in
            self.membershipCollection.document(membershipId).updateData([
                "isLeader": isLeader
            ]) { error in
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
    
    /// 그룹 멤버 수 조회
    func fetchGroupMemberCount(groupId: String) -> Observable<Int> {
        return Observable.create { observer in
            self.membershipCollection
                .whereField("groupId", isEqualTo: groupId)
                .getDocuments { querySnapshot, error in
                    if let error = error {
                        observer.onError(MembershipError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    let count = querySnapshot?.documents.count ?? 0
                    observer.onNext(count)
                    observer.onCompleted()
                }
            
            return Disposables.create()
        }
    }
    
    /// 그룹 리더 조회
    func fetchGroupLeader(groupId: String) -> Observable<GroupMembershipFirestore?> {
        return Observable.create { observer in
            self.membershipCollection
                .whereField("groupId", isEqualTo: groupId)
                .whereField("isLeader", isEqualTo: true)
                .limit(to: 1)
                .getDocuments { querySnapshot, error in
                    if let error = error {
                        observer.onError(MembershipError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents,
                          let document = documents.first else {
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
    
    /// 가장 오래된 멤버 조회 (특정 유저 제외)
    func fetchOldestMember(groupId: String, excludeUserId: String) -> Observable<GroupMembershipFirestore?> {
        return Observable.create { observer in
            self.membershipCollection
                .whereField("groupId", isEqualTo: groupId)
                .whereField("userId", isNotEqualTo: excludeUserId)
                .order(by: "joinedAt", descending: false)
                .limit(to: 1)
                .getDocuments { querySnapshot, error in
                    if let error = error {
                        observer.onError(MembershipError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents,
                          let document = documents.first else {
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
    
    /// 특정 사용자의 모든 멤버십 삭제 (유저 탈퇴 시 사용)
    func deleteUserMemberships(userId: String) -> Observable<Void> {
        return Observable.create { observer in
            self.membershipCollection
                .whereField("userId", isEqualTo: userId)
                .getDocuments { querySnapshot, error in
                    if let error = error {
                        observer.onError(MembershipError.deleteFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        observer.onNext(())
                        observer.onCompleted()
                        return
                    }
                    
                    let batch = Firestore.firestore().batch()
                    documents.forEach { document in
                        batch.deleteDocument(document.reference)
                    }
                    
                    batch.commit { error in
                        if let error = error {
                            observer.onError(MembershipError.deleteFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
                }
            return Disposables.create()
        }
    }
    
    /// 특정 그룹의 모든 멤버십 삭제 (그룹 삭제 시 사용)
    func deleteGroupMemberships(groupId: String) -> Observable<Void> {
        return Observable.create { observer in
            self.membershipCollection
                .whereField("groupId", isEqualTo: groupId)
                .getDocuments { querySnapshot, error in
                    if let error = error {
                        observer.onError(MembershipError.deleteFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        observer.onNext(())
                        observer.onCompleted()
                        return
                    }
                    
                    let batch = Firestore.firestore().batch()
                    documents.forEach { document in
                        batch.deleteDocument(document.reference)
                    }
                    
                    batch.commit { error in
                        if let error = error {
                            observer.onError(MembershipError.deleteFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
                }
            return Disposables.create()
        }
    }
}
