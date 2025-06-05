//
//  FirestoreManager.swift
//  StampIt-Project
//
//  Created by iOS study on 6/5/25.
//

import Foundation
import FirebaseFirestore
import RxSwift

// MARK: - FirestoreManager Protocol
protocol FirestoreManagerProtocol {
    // User 관련
    func fetchUser(userId: String) -> Observable<UserFirestore>
    func createUser(_ user: UserFirestore) -> Observable<Void>
    func updateUser(_ user: UserFirestore) -> Observable<Void>
    
    // Group 관련
    func fetchGroup(groupId: String) -> Observable<GroupFirestore>
    func createGroup(_ group: GroupFirestore) -> Observable<Void>
    func updateGroup(_ group: GroupFirestore) -> Observable<Void>
    
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
    
    // MARK: - Collection References
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
    
    // MARK: - Singleton
    static let shared = FirestoreManager()
    private init() {}
}

// MARK: - User Operations
extension FirestoreManager {
    func fetchUser(userId: String) -> Observable<UserFirestore> { }
    func createUser(_ user: UserFirestore) -> Observable<Void> { }
    func updateUser(_ user: UserFirestore) -> Observable<Void> { }
}

// MARK: - Group Operations
extension FirestoreManager {
    func fetchGroup(groupId: String) -> RxSwift.Observable<GroupFirestore> {
        <#code#>
}
    func createGroup(_ group: GroupFirestore) -> Observable<Void> { }
    func updateGroup(_ group: GroupFirestore) -> Observable<Void> { }
}

// MARK: - Member Operations
extension FirestoreManager {
    func fetchMembers(groupId: String) -> Observable<[MemberFirestore]> { }
    func addMember(groupId: String, member: MemberFirestore) -> Observable<Void> { }
    func removeMember(groupId: String, userId: String) -> Observable<Void> { }
}

// MARK: - Mission Operations
extension FirestoreManager {
    func fetchMissions(groupId: String) -> Observable<[MissionFirestore]> { }
    func createMission(groupId: String, mission: MissionFirestore) -> Observable<Void> { }
    func updateMission(groupId: String, mission: MissionFirestore) -> Observable<Void> { }
    func deleteMission(groupId: String, missionId: String) -> Observable<Void> { }
}

// MARK: - Sticker Operations
extension FirestoreManager {
    func fetchStickers(userId: String, month: String) -> Observable<[StickerFirestore]> { }
    func addSticker(_ sticker: StickerFirestore) -> Observable<Void> { }
}

// MARK: - Invite Operations
extension FirestoreManager {
    func fetchInvite(inviteCode: String) -> Observable<InviteFirestore> { }
    func createInvite(_ invite: InviteFirestore) -> Observable<Void> { }
    func deleteInvite(inviteCode: String) -> Observable<Void> { }
}

// MARK: - AppMission Operations
extension FirestoreManager {
    func fetchAppMissions() -> Observable<[AppMissionFirestore]> { }
}
