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

final class GroupManager: GroupManagerProtocol {
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    
    // MARK: - Collection Reference
    private var groupsCollection: CollectionReference {
        return db.collection("groups")
    }
    
    // MARK: - Init
    init() {}
    
    // MARK: - Group Operations
    
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
    
    /// 그룹 정보 일회성 조회
    func fetchGroupOnce(groupId: String) -> Observable<GroupFirestore> {
        return Observable.create { observer in
            self.groupsCollection.document(groupId)
                .getDocument(source: .server) { documentSnapshot, error in
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
                        observer.onCompleted()
                    } catch {
                        observer.onError(GroupError.decodingFailed(error.localizedDescription))
                    }
                }
            
            return Disposables.create()
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
    
    /// 그룹 삭제
    func deleteGroup(groupId: String) -> Observable<Void> {
        return Observable.create { observer in
            self.groupsCollection.document(groupId).delete { error in
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
    
    /// 그룹명 업데이트
    func updateGroupName(groupId: String, name: String, changedAt: Date) -> Observable<Void> {
        return Observable.create { observer in
            self.groupsCollection.document(groupId).updateData([
                "name": name,
                "nameChangedAt": Timestamp(date: changedAt)
            ]) { error in
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
    
    /// 그룹 리더 변경
    func updateGroupLeader(groupId: String, newLeaderId: String) -> Observable<Void> {
        return Observable.create { observer in
            self.groupsCollection.document(groupId).updateData([
                "leaderId": newLeaderId
            ]) { error in
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
    
    /// 멤버 수 업데이트
    func updateMemberCount(groupId: String, count: Int) -> Observable<Void> {
        return Observable.create { observer in
            self.groupsCollection.document(groupId).updateData([
                "memberCount": count
            ]) { error in
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
    
    /// 초대 코드 업데이트
    func updateInviteCode(groupId: String, newInviteCode: String) -> Observable<Void> {
        return Observable.create { observer in
            self.groupsCollection.document(groupId).updateData([
                "inviteCode": newInviteCode,
                "inviteCreatedAt": Timestamp(date: Date())
            ]) { error in
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
    
    /// 초대 코드로 그룹 정보 조회
    func fetchGroupByInviteCode(inviteCode: String) -> Observable<GroupFirestore> {
        return Observable.create { observer in
            self.groupsCollection
                .whereField("inviteCode", isEqualTo: inviteCode)
                .limit(to: 1)
                .getDocuments { querySnapshot, error in
                    if let error = error {
                        observer.onError(GroupError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents,
                          let document = documents.first else {
                        observer.onError(GroupError.groupNotFound)
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
    
    /// 그룹의 현재 초대 코드 조회
    func fetchGroupInviteCode(groupId: String) -> Observable<String> {
        return fetchGroupOnce(groupId: groupId)
            .map { group in
                return group.inviteCode
            }
    }
}
