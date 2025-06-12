//
//  MissionViewModelProtocol.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/4/25.
//

import Foundation
import RxSwift

protocol MissionViewModelProtocol {
    associatedtype Input
    associatedtype Output
    
    var disposeBag: DisposeBag { get }
}
