//
//  MemberMissionUseCase.swift
//  StampIt-Project
//
//  Created by daeun on 6/17/25.
//

import Foundation
import RxSwift

protocol MemberMissionUseCaseProtocol {
    func fetchMissions(by userID: String, ofGroup groupID: String) -> Observable<[Mission]>
}
