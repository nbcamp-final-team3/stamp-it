//
//  MissionGenerator.swift
//  StampIt-Project
//
//  Created by 권순욱 on 9/25/25.
//

import FoundationModels

@available(iOS 26.0, *)
final class MissionGenerator {
    private let session: LanguageModelSession
    private(set) var suggestions: [String] = []
    
    let userData: [MissionData]
    
    init(userData: [MissionData]) {
        self.userData = userData
        
        // instruction 설정
        session = LanguageModelSession {
            "Your job is to create a mission for the user."
            
            "The user wants to assign a mission to another member."
            
            """
            A mission means assigning one of the following categories to another member:
            household chores, communication, healthcare/workout, learning/reading
            """
            
            "Another member refers to people you live with, such as family and friends."
            
            // prompt와 중복인데, 테스트 시에는 두군데 모두 있는 경우가 더 품질이 좋았음(이유 모름)
            """
            Here are missions the user has used in the past.
            Refer to these when considering what missions to generate:
            """
            userData.map(\.title).joined(separator: ", ")
            
            "Always answer in Korean, and use noun forms rather than full sentences."
        }
    }
    
    func suggestMission(missionCount: Int) async {
        do {
            // prompt 설정
            let response = try await session.respond(generating: AISuggestion.self) {
                if missionCount == 1 {
                    "Generate a mission."
                } else {
                    "Generate \(missionCount) missions."
                }
                
                // 기존 데이터 그대로 추천하지 말라고 했는데, 말 잘 안들음(이유 모름)
                """
                Here are missions the user has used in the past.
                Refer to these when considering what missions to generate, but don't copy them. Always  make the new one:
                """
                userData.map(\.title).joined(separator: ", ")
                
            }
            suggestions = response.content.results.map { $0.title }
        } catch {
            print(error)
        }
    }
    
    func prewarm() {
        session.prewarm()
    }
}
