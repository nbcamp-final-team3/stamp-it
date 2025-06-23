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
}

// MARK: - Invite 관련 DB 접근만 담당
extension GroupManager {

    private var invitesCollection: CollectionReference { db.collection("invites") }

    // 초대장 단건 조회
    func fetchInvite(inviteCode: String) -> Observable<InviteFirestore?> {
        Observable.create { observer in
            self.invitesCollection.document(inviteCode).getDocument { snapshot, error in
                if let error = error {
                    observer.onError(error)
                    return
                }
                guard let snapshot = snapshot, snapshot.exists else {
                    observer.onNext(nil)
                    observer.onCompleted()
                    return
                }
                do {
                    let invite = try snapshot.data(as: InviteFirestore.self)
                    observer.onNext(invite)
                    observer.onCompleted()
                } catch {
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }

    // 초대장 생성
    func createInvite(_ invite: InviteFirestore) -> Observable<Void> {
        Observable.create { observer in
            do {
                try self.invitesCollection.document(invite.inviteCode).setData(from: invite) { error in
                    if let error = error {
                        observer.onError(error)
                    } else {
                        observer.onNext(())
                        observer.onCompleted()
                    }
                }
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    // 초대 코드로 그룹 조회
    func fetchGroupByInviteCode(inviteCode: String) -> Observable<GroupFirestore?> {
        Observable.create { observer in
            self.groupsCollection.whereField("inviteCode", isEqualTo: inviteCode).limit(to: 1)
                .getDocuments { snapshot, error in
                    if let error = error {
                        observer.onError(error)
                        return
                    }
                    guard let documents = snapshot?.documents, let document = documents.first else {
                        observer.onNext(nil)
                        observer.onCompleted()
                        return
                    }
                    do {
                        let group = try document.data(as: GroupFirestore.self)
                        observer.onNext(group)
                        observer.onCompleted()
                    } catch {
                        observer.onError(error)
                    }
                }
            return Disposables.create()
        }
    }

    // 그룹의 모든 초대장 삭제
    func deleteGroupInvites(groupId: String) -> Observable<Void> {
        Observable.create { observer in
            self.invitesCollection.whereField("groupId", isEqualTo: groupId).getDocuments { snapshot, error in
                if let error = error {
                    observer.onError(error)
                    return
                }
                guard let documents = snapshot?.documents else {
                    observer.onNext(())
                    observer.onCompleted()
                    return
                }
                let batch = Firestore.firestore().batch()
                for doc in documents {
                    batch.deleteDocument(doc.reference)
                }
                batch.commit { error in
                    if let error = error {
                        observer.onError(error)
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
