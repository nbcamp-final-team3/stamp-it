//
//  ExportLogicServicing.swift
//  StampIt-Project
//
//  Created by 윤주형 on 10/7/25.
//

import RxSwift

protocol ExportLogicServicingProtocol {
    func exportMember(_ user: User) -> Observable<User>
    func validateGroupLeaving(currentUser: User) -> Observable<Void>
}
