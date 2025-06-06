//
//  ViewModelProtocol.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/6/25.
//

import Foundation
import RxSwift
import RxRelay

protocol ViewModelProtocol {
    associatedtype Action
    associatedtype State

    var disposeBag: DisposeBag { get }
    var action: PublishRelay<Action> { get }
    var state: State { get }
}
