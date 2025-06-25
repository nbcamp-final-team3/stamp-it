//
//  MemberMapping.swift
//  StampIt-Project
//
//  Created by daeun on 6/24/25.
//

import Foundation

protocol MemberMapping {
    func map(members: [Member], userID: String) -> [HomeItem]
}
