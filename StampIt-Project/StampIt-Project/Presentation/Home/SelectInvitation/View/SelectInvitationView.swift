//
//  SelectInvitationView.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/9/25.
//

import UIKit
import RxSwift
import RxRelay

final class SelectInvitationView: UIView {

    // MARK: - Actions


    // MARK: - Properties

    private let disposeBag = DisposeBag()

    // MARK: - UI Components


    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setStyles()
        setHierarchy()
        setConstraints()
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Set Styles

    private func setStyles() {
        backgroundColor = .FFFFFF
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
