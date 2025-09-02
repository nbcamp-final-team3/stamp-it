//
//  DateFormatterUtil.swift
//  StampIt-Project
//
//  Created by kingj on 7/3/25.
//

import Foundation

// TODO: Date+Extension으로 마이그레이션
struct DateFormatterUtil {
    static func formattedString(with date: Date) -> String {
        let format = DateFormatter()
        format.dateFormat = "yyyy년 M월 d일"
        
        let dateString = format.string(from: date)
        return dateString
    }
}
