//
//  CompositeProtocols.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import Foundation

// MARK: - 복합 프로토콜

protocol ReadOnlyRepository: Fetchable, Observing, Queryable {}
protocol FullCRUDRepository: Creatable, Fetchable, Observing, Updatable, Deletable, Queryable {}
