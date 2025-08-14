//
//  MemberButton.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/14/25.
//

import UIKit

final class MemberButton: UIButton {
    private let member: Member
    
    init(member: Member) {
        self.member = member
        super.init(frame: .zero)
        
        setTitle(member.nickname, for: .normal)
        titleLabel?.font = .pretendard(size: 16, weight: .regular)
        setTitleColor(.black, for: .normal)
        backgroundColor = .white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func getMember() -> Member {
        member
    }
}
