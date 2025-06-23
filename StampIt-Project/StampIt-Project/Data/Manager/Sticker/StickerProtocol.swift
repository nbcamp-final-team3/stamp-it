//
//  StickerManagerProtocol.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import RxSwift
import Foundation

protocol StickerManagerProtocol {
    // 기본 CRUD
    func fetchStickers(userId: String, month: String) -> Observable<[StickerFirestore]>
    func fetchStickersByPin(userId: String, pinNumber: Int) -> Observable<[StickerFirestore]>
    func fetchAllUserStickers(userId: String) -> Observable<[StickerFirestore]>
    func fetchGroupStickers(groupId: String, month: String) -> Observable<[StickerFirestore]>
    func addSticker(_ sticker: StickerFirestore) -> Observable<Void>
    func updateSticker(_ sticker: StickerFirestore) -> Observable<Void>
    
    // 조회 관련
    func fetchStickerCount(userId: String) -> Observable<Int>
    func fetchStickersByMission(missionId: String) -> Observable<[StickerFirestore]>
    
    // TODO: 미션 완료 시 스티커 생성 (CURD 리팩토링 중 Sticker 리팩토링 할 때 비즈니스 로직으로 레포에 내릴 예정)
    func createStickerFromMission(
        userId: String,
        groupId: String,
        missionId: String,
        stickerType: String,
        assignedBy: String
    ) -> Observable<Void>
    
    // 삭제 관련
    func deleteUserStickers(userId: String, groupId: String) -> Observable<Void>
    func deleteUserStickers(userId: String) -> Observable<Void>
    func deleteGroupStickers(groupId: String) -> Observable<Void>
}
