//
//  TestViewController.swift
//  StampIt-Project
//
//  Created by iOS study on 6/9/25.
//

//TODO: 현재 데이터베이스 연결 확인을 위해 디버깅용 print문과 데이터가 들어가는지 확인하는 TestVC가 남아있습니다. 로그인 및 주기적으로 데이터를 주고 받는 데이터를 해당 코드에서 작업하고 테스트할 예정이라 삭제하지 않고 남겨두었습니다. 해당 코드들은 Manager 최종 수정하거나 리팩토링 단계에서 삭제해두겠습니다!

import UIKit
import SnapKit
import RxSwift
import FirebaseFirestore

class TestViewController: UIViewController {
    
    private let firestoreManager = FirestoreManager.shared
    private let disposeBag = DisposeBag()
    private let testUserId = "test_user_123"
    private let testGroupId = "test_group_456"
    
    private lazy var logTextView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .systemGray6
        textView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.isEditable = false
        textView.layer.cornerRadius = 8
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad called!")
        setupUI()
        runTests()
    }
    
    private func setupUI() {
        title = "Firestore 테스트"
        view.backgroundColor = .systemBackground
        
        view.addSubview(logTextView)
        
        logTextView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
            make.bottom.trailing.equalToSuperview().offset(-16)
        }
        
        // 우상단에 테스트 실행 버튼
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "테스트 실행",
            style: .plain,
            target: self,
            action: #selector(runTestsTapped)
        )
    }
    
    @objc private func runTestsTapped() {
        logTextView.text = ""
        runTests()
    }
    
    private func runTests() {
        log("🚀 Firestore 연결 테스트 시작")
        log("📝 Test User ID: \(testUserId)")
        log("📝 Test Group ID: \(testGroupId)")
        
        // 순차적으로 테스트 실행
        testUserOperations()
    }
    
    private func testUserOperations() {
        log("\n👤 === 사용자 테스트 시작 ===")
        
        // 1. 사용자 생성
        let testUser = UserFirestore(
            userId: testUserId,
            nickname: "테스트유저",
            email: "test@example.com",
            profileImage: nil,
            groupId: "",
            nicknameChangedAt: Timestamp(),
            createdAt: Timestamp()
        )
        
        firestoreManager.createUser(testUser)
            .delay(.seconds(1), scheduler: MainScheduler.instance)
            .flatMap { [weak self] _ -> Observable<UserFirestore> in
                self?.log("✅ 사용자 생성 성공")
                return self?.firestoreManager.fetchUser(userId: self?.testUserId ?? "") ?? Observable.empty()
            }
            .take(1)
            .subscribe(
                onNext: { [weak self] user in
                    self?.log("✅ 사용자 조회 성공: \(user.nickname)")
                    self?.testGroupOperations()
                },
                onError: { [weak self] error in
                    self?.log("❌ 사용자 테스트 실패: \(error.localizedDescription)")
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func testGroupOperations() {
        log("\n👥 === 그룹 테스트 시작 ===")
        
        let testGroup = GroupFirestore(
            groupId: testGroupId,
            name: "테스트 그룹",
            leaderId: testUserId,
            inviteCode: "123080",
            nameChangedAt: Timestamp(),
            createdAt: Timestamp()
        )
        
        firestoreManager.createGroup(testGroup)
            .delay(.seconds(1), scheduler: MainScheduler.instance)
            .flatMap { [weak self] _ -> Observable<GroupFirestore> in
                self?.log("✅ 그룹 생성 성공")
                return self?.firestoreManager.fetchGroup(groupId: self?.testGroupId ?? "") ?? Observable.empty()
            }
            .take(1)
            .subscribe(
                onNext: { [weak self] group in
                    self?.log("✅ 그룹 조회 성공: \(group.name)")
                    self?.testMemberOperations()
                },
                onError: { [weak self] error in
                    self?.log("❌ 그룹 테스트 실패: \(error.localizedDescription)")
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func testMemberOperations() {
        log("\n👤 === 멤버 테스트 시작 ===")
        
        let testMember = MemberFirestore(
            userId: testUserId,
            nickname: "테스트유저",
            joinedAt: Timestamp(),
            isLeader: true
        )
        
        firestoreManager.addMember(groupId: testGroupId, member: testMember)
            .delay(.seconds(1), scheduler: MainScheduler.instance)
            .flatMap { [weak self] _ -> Observable<[MemberFirestore]> in
                self?.log("✅ 멤버 추가 성공")
                return self?.firestoreManager.fetchMembers(groupId: self?.testGroupId ?? "") ?? Observable.empty()
            }
            .take(1)
            .subscribe(
                onNext: { [weak self] members in
                    self?.log("✅ 멤버 조회 성공: \(members.count)명")
                    self?.log("\n🎉 모든 테스트 완료!")
                    self?.log("📊 결과: Firestore 연결 및 CRUD 작업 정상 동작")
                },
                onError: { [weak self] error in
                    self?.log("❌ 멤버 테스트 실패: \(error.localizedDescription)")
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func log(_ message: String) {
        DispatchQueue.main.async {
            let formatter = DateFormatter().apply { (df: DateFormatter) in
                df.dateFormat = "HH:mm:ss"
            }
            let timestamp = formatter.string(from: Date())
            
            let logMessage = "[\(timestamp)] \(message)\n"
            self.logTextView.text += logMessage
            
            // 자동 스크롤
            let range = NSMakeRange(self.logTextView.text.count - 1, 0)
            self.logTextView.scrollRangeToVisible(range)
        }
    }
}

extension NSObject {
    @discardableResult
    func apply<T>(_ closure: (T) -> Void) -> T where T: NSObject {
        closure(self as! T)
        return self as! T
    }
}
