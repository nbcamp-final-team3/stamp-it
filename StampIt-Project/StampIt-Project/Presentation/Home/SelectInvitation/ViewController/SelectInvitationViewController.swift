//
//  SelectInvitationViewController.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/9/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class SelectInvitationViewController: UIViewController {

    // MARK: - Properties

    private let disposeBag = DisposeBag()

    // MARK: - UI Components

    private let selectInvitationView = SelectInvitationView()

    // MARK: - Life Cycles

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = selectInvitationView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }

    // MARK: - Bind

    private func bind() {
    }

    // MARK: - Methods

}
