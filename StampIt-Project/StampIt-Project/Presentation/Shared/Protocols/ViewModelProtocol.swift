//
//  ViewModelProtocol.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/4/25.
//

import RxSwift

//MARK: viewModel이 준수하는 프로토콜
protocol ViewModelProtocol {

    associatedtype Action

    associatedtype State

    var disposeBag: DisposeBag { get }

    var action: AnyObserver<Action> { get }

    var state: State { get }
}
