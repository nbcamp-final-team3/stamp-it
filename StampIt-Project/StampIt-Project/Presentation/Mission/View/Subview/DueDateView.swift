//
//  DueDateView.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/25/25.
//

import SwiftUI

struct DueDateView: View {
    @State private var showCalendar = false
    @State private var selectedDate = Date()
    
    let onChange: (Date) -> Void
    
    private var formattedDate: String {
        selectedDate.formatted(.dateTime.year().month().day().locale(Locale(identifier: "ko_KR")))
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("미션 기한")
                    .font(.custom("Pretendard", size: 16))
                    .foregroundColor(.gray800)
                Spacer()
                Button {
                    withAnimation {
                        showCalendar.toggle()
                    }
                } label: {
                    Text(formattedDate)
                        .font(.custom("Pretendard", size: 16))
                        .foregroundColor(.gray800)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 14)
                        .background(.gray25)
                        .cornerRadius(6)
                }
            }
            .padding(.bottom)
            
            DatePicker("", selection: $selectedDate, in: Date()..., displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .labelsHidden()
                .frame(minHeight: 320)
                .opacity(showCalendar ? 1 : 0)
        }
        .onChange(of: selectedDate) { newValue in
            onChange(newValue)
        }
    }
}

#Preview {
    DueDateView(onChange: { _ in })
}
