//
//  Date+Extension.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/6/25.
//

import Foundation

extension Date {
    func toMonthDayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"

        let formattedDate = formatter.string(from: self)

        return formattedDate
    }

    func toYearMonthString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"

        let formattedDate = formatter.string(from: self)

        return formattedDate
    }
}
