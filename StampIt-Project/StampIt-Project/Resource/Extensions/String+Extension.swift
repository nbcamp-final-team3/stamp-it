//
//  String+Extension.swift
//  StampIt-Project
//
//  Created by iOS study on 6/11/25.
//
import CryptoKit
import Foundation

extension String {
    var sha256: String {
        let inputData = Data(self.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
