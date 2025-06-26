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

    /// 오늘부터 days일 이내에 포함되는지 검증
    func isWithinNext(days: Int, calendar: Calendar = .current) -> Bool {
        let start = calendar.startOfDay(for: Date())
        guard let end = calendar.date(byAdding: .day, value: days, to: start) else { return false }
        return (start ... end).contains(self)
    }
}
