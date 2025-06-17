//
//  MemberMissionUseCase.swift
//  StampIt-Project
//
//  Created by daeun on 6/17/25.
//

import Foundation
import RxSwift

protocol MemberMissionUseCaseProtocol {
    func fetchSendedMissions(ofUser userID: String, fromGroup groupID: String) -> Observable<[Mission]>
}
