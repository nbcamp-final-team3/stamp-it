//
//  PageControlFooterView.swift
//  StampIt-Project
//
//  Created by kingj on 6/29/25.
//

import UIKit
import SnapKit

final class PageControlFooterView: UICollectionReusableView {
    
    // MARK: - Properties
    
    static let identifier = "PageControlFooterView"
    
    // MARK: - UI Components

    private let pageControl = CustomPageControl()
    
    // MARK: - Initializer, Deinit, requiered
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setHierarchy()
        setLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Hierarchy Helper
    
    private func setHierarchy() {
        [
            pageControl
        ]
            .forEach { addSubview($0) }
    }
    
    // MARK: - Layout Helper
    
    private func setLayout() {
        pageControl.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.height.equalTo(10)
        }
    }
    
    // MARK: - Methods

    func configure(numberOfPages: Int, currentPage: Int) {
        pageControl.configure(
            numberOfPages: numberOfPages,
            currentPage: currentPage,
            isWithColor: false
        )
    }
    
    func setCurrentPage(_ page: Int, animated: Bool = true) {
        pageControl.setCurrentPage(page, isWithColor: false)
    }
}
