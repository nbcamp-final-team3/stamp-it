//
//  HomeViewController.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/9/25.
//

import UIKit
import SnapKit
import Then

final class HomeViewController: UIViewController {

    // MARK: - UI Components

    private let homeView = HomeView()

    // MARK: - Life Cycles

    override func loadView() {
        view = homeView
    }

}
