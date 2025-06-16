//
//  SendInviteUseCase.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/13/25.
//

import Foundation
import RxSwift

protocol SendInviteUseCase {
    func getCurrentUser() -> Observable<StampIt_Project.User?>
}
