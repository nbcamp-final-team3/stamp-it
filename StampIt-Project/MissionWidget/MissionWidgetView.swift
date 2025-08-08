//
//  MissionWidgetView.swift
//  StampIt-Project
//
//  Created by 이부용 on 8/8/25.
//

import SwiftUI
import WidgetKit

struct MissionWidgetEntryView: View {
    var entry: MissionTimelineProvider.Entry
    
    var body: some View {
        ZStack {
            Color.white
            
            VStack(alignment: .leading, spacing: 0) {
                // 헤더
                headerView
                
                if entry.missions.isEmpty {
                    emptyStateView
                } else {
                    missionListView
                }
                
                Spacer()
            }
        }
        .widgetURL(URL(string: "stampIt://mission"))
    }
    
    // MARK: - Views
    private var headerView: some View {
        HStack {
            Text("내 미션")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 5)
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            Text("아직 받은 미션이 없어요!")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
            Spacer()
        }
    }
    
    private var missionListView: some View {
        VStack(spacing: 0) {
            ForEach(entry.missions.prefix(2), id: \.id) { mission in
                MissionRowView(mission: mission)
            }
        }
        .padding(.horizontal, 16)
    }
}

struct MissionRowView: View {
    let mission: MissionWidgetUI
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 미션 내용
            VStack(alignment: .leading, spacing: 4) {
                tagRow
                // 미션 제목
                missionTitle
            }
            
            Spacer()
            
            // 미션 아이콘
            missionIcon
        }
        .padding(.vertical, 6)
    }
    
    // MARK: - Components
    private var tagRow: some View {
        HStack(spacing: 6) {
            // new 태그
            if mission.isNew {
                TagView(text: "new", isHighlighted: true)
            }
            
            // from.label 태그
            TagView(text: mission.fromLabel, isHighlighted: false)
            
            // ~기간 태그
            TagView(text: mission.duration, isHighlighted: false)
            
            Spacer()
        }
    }
    
    private var missionTitle: some View {
        Text(mission.title)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.black)
            .lineLimit(1)
            .truncationMode(.tail)
    }
    
    private var missionIcon: some View {
        mission.category.widgetImage
            .resizable()
            .frame(width: 32, height: 32)
    }
}

struct TagView: View {
    let text: String
    let isHighlighted: Bool
    
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(isHighlighted ?
                Color(red: 1.0, green: 0.8, blue: 0.0) :
                Color.gray
            )
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isHighlighted ?
                        Color(red: 1.0, green: 0.8, blue: 0.0) :
                        Color.gray,
                        lineWidth: 1
                    )
            )
    }
}
