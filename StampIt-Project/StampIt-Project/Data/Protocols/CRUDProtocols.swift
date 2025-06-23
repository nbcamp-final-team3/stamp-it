//
//  CRUDProtocols.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import RxSwift
import Foundation
import FirebaseFirestore

/// 생성 기능만 필요한 클라이언트용
protocol Creatable {
    associatedtype Entity
    func create(_ entity: Entity) -> Observable<Void>
}

/// 일회성 조회만 필요한 클라이언트용
protocol Fetchable {
    associatedtype Entity
    associatedtype ID
    func fetch(id: ID) -> Observable<Entity?>
}

/// 실시간 관찰만 필요한 클라이언트용 (이름 변경!)
protocol Observing {
    associatedtype Entity
    associatedtype ID
    func observe(id: ID) -> Observable<Entity?>  // RxSwift.Observable 사용
}

/// 업데이트만 필요한 클라이언트용
protocol Updatable {
    associatedtype Entity
    associatedtype ID
    func update(id: ID, entity: Entity) -> Observable<Void>
    func updateFields(id: ID, fields: [String: Any]) -> Observable<Void>
}

/// 삭제만 필요한 클라이언트용
protocol Deletable {
    associatedtype ID
    func delete(id: ID) -> Observable<Void>
}

/// 쿼리 조회만 필요한 클라이언트용
protocol Queryable {
    associatedtype Entity
    associatedtype Query
    func fetchList(query: Query) -> Observable<[Entity]>
    func observeList(query: Query) -> Observable<[Entity]>
}

/// 트랜잭션이 필요한 클라이언트용
protocol Transactional {
    func runTransaction<T>(_ block: @escaping (Transaction) throws -> T) -> Observable<T>
}
