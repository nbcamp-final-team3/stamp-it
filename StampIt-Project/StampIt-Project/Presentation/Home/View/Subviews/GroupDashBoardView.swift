//
//  GroupDashboardView.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/10/25.
//

import Foundation

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class GroupDashboardView: UIView {

    // MARK: - Actions


    // MARK: - Properties

    private let disposeBag = DisposeBag()

    // MARK: - UI Components

    

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setHierarchy()
        setConstraints()
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    // MARK: - Set Hierarchy

    private func setHierarchy() {
    }

    // MARK: - Set Constraints

    private func setConstraints() {
    }

    // MARK: - Bind

    private func bind() {
    }
}
