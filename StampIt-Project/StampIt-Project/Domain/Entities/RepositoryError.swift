//
//  RepositoryError.swift
//  StampIt-Project
//
//  Created by iOS study on 6/8/25.
//  Repository에서 오류가 추가로 발생하는 경우 enum에 더 정의하셔도 됩니다

import Foundation

// MARK: - Repository Error
/// Repository 계층에서 발생하는 에러 정의
enum RepositoryError: Error {
    case authenticationFailed(String)  // 인증 실패
    case userNotFound                  // 사용자 없음
    case userNotInGroup                  // 그룹 없음
    case dataError(String)             // 데이터 처리 오류
    case networkError(String)          // 네트워크 오류
    case uiError(String)              // UI 관련 오류
    case unknownError                  // 알 수 없는 오류
    case groupIsFull                   // 그룹 정원이 가득 찬 오류
    case onlyOneGroup                   //유저는 그룹을 하나만 가질 수 있음
    case noInviteCode                   //초대 코드가 없는 오류
    case expiredInviteCode              //만료 코드 오류
    case alreadyInGroup                 //이미 그룹에 있는 경우


    var localizedDescription: String {
        switch self {
        case .authenticationFailed(let message):
            return "인증 실패: \(message)"
        case .userNotFound:
            return "사용자를 찾을 수 없습니다"
        case .userNotInGroup:
            return "사용자가 그룹에 속해 있지 않습니다"
        case .dataError(let message):
            return "데이터 오류: \(message)"
        case .networkError(let message):
            return "네트워크 오류: \(message)"
        case .uiError(let message):
            return "화면 오류: \(message)"
        case .unknownError:
            return "알 수 없는 오류가 발생했습니다"
        case .groupIsFull:
            return "그룹 정원이 가득 찼습니다."
        case .onlyOneGroup:
            return "기존 그룹을 탈퇴해 주세요."
        case .noInviteCode:
            return "초대 코드를 확인 할 수 없습니다."
        case .expiredInviteCode:
            return "만료된 코드입니다."
        case .alreadyInGroup:
            return "이미 그룹에 존재합니다."
        }
    }
}
