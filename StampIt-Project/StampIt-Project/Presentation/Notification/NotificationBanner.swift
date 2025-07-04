//
//  NotificationBanner.swift
//  StampIt-Project
//
//  Created by iOS study on 6/27/25.
//

import SwiftUI

// MARK: 인앱 알림 배너 구현 (UIKit으로는 코드가 너무 복잡혀져서 SwiftUI 사용했습니다!
struct NotificationBanner: View {
    let notification: MissionNotification
    @State private var isVisible = false
    @State private var offset: CGFloat = -100
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.orange)
                        Text("새로운 미션")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(timeAgoString(from: notification.receivedAt))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(notification.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text("from \(notification.assignedBy)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("확인") {
                    dismissBanner()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .padding(.horizontal)
        }
        .offset(y: offset)
        .onAppear {
            showBanner()
            
            // 5초 후 자동 사라짐
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                dismissBanner()
            }
        }
    }
    
    private func showBanner() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            offset = 0
            isVisible = true
        }
    }
    
    private func dismissBanner() {
        withAnimation(.easeInOut(duration: 0.3)) {
            offset = -100
            isVisible = false
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
