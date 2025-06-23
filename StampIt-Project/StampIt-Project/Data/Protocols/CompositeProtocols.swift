//
//  CompositeProtocols.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import Foundation

// MARK: - 복합 프로토콜

/// 읽기 전용 (일회성 + 쿼리)
typealias ReadOnlyRepository = Fetchable & Queryable

/// 실시간 읽기 전용 (실시간 + 쿼리)
typealias RealtimeReadOnlyRepository = Observing & Queryable

/// 쓰기 전용 (생성 + 수정 + 삭제)
typealias WriteOnlyRepository = Creatable & Updatable & Deletable

/// 완전한 CRUD (모든 기능)
typealias FullCRUDRepository = Creatable & Fetchable & Observing & Updatable & Deletable & Queryable

/// 트랜잭션 지원 CRUD
typealias TransactionalRepository = FullCRUDRepository & Transactional
