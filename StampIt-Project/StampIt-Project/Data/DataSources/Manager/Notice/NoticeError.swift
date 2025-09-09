//
//  NoticeError.swift
//  StampIt-Project
//
//  Created by iOS study on 7/11/25.
//

import Foundation

enum NoticeError: Error {
    case fetchFailed(String)
    case decodingFailed(String)
    case updateFailed(String)
    case unknownError(String)
}
