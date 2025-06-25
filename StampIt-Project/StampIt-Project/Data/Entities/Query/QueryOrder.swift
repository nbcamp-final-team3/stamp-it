//
//  QueryOrder.swift
//  StampIt-Project
//
//  Created by iOS study on 6/24/25.
//

import Foundation

struct QueryOrder {
    let field: String
    let descending: Bool

    init(field: String, descending: Bool = false) {
        self.field = field
        self.descending = descending
    }
}
