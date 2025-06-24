//
//  FirestoreManager.swift
//  StampIt-Project
//
//  Created by iOS study on 6/5/25.
//

import Foundation
import FirebaseFirestore
import Firebase
import RxSwift
import Network

// MARK: - FirestoreManager Protocol
protocol FirestoreManagerProtocol {
    // 네트워크 관련
    func checkNetworkConnection() -> Observable<Bool>
    func monitorNetworkStatus() -> Observable<Bool>
    
    // Firestore 인스턴스 제공
    var db: Firestore { get }
    
    // 공통 에러 처리
    func handleFirestoreError(_ error: Error) -> FirestoreError
    func executeWithNetworkCheck<T>(_ operation: @escaping () -> Observable<T>) -> Observable<T>
    func executeWithRetry<T>(_ operation: @escaping () -> Observable<T>, maxRetries: Int) -> Observable<T>
}

// MARK: - FirestoreManager Implementation
final class FirestoreManager: FirestoreManagerProtocol {
    
    // MARK: - Properties
    let db = Firestore.firestore()
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "NetworkMonitor")
    private let networkStatusSubject = BehaviorSubject<Bool>(value: true)
    
    // MARK: - Init
    init() {
        setupNetworkMonitoring()
        configureFirestore()
    }
    
    deinit {
        networkMonitor.cancel()
    }
}

// MARK: - Network Operations
extension FirestoreManager {
    
    /// 네트워크 연결 상태 실시간 모니터링
    func monitorNetworkStatus() -> Observable<Bool> {
        return networkStatusSubject.asObservable()
            .distinctUntilChanged()
    }
    
    /// 일회성 네트워크 연결 체크
    func checkNetworkConnection() -> Observable<Bool> {
        return Observable.create { observer in
            // 타임아웃 설정 (5초)
            let timeoutTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                observer.onNext(false)
                observer.onCompleted()
            }
            
            // Firestore 연결 테스트
            self.db.collection("connection_test").limit(to: 1).getDocuments(source: .server) { _, error in
                timeoutTimer.invalidate()
                
                if let error = error as NSError? {
                    // 네트워크 관련 에러만 체크
                    switch error.code {
                    case FirestoreErrorCode.unavailable.rawValue,
                         FirestoreErrorCode.deadlineExceeded.rawValue:
                        observer.onNext(false)
                    default:
                        observer.onNext(true) // 다른 에러는 연결은 되어있다고 판단
                    }
                } else {
                    observer.onNext(true)
                }
                observer.onCompleted()
            }
            
            return Disposables.create {
                timeoutTimer.invalidate()
            }
        }
    }
    
    /// 네트워크 상태 확인 후 작업 실행
    func executeWithNetworkCheck<T>(_ operation: @escaping () -> Observable<T>) -> Observable<T> {
        return checkNetworkConnection()
            .flatMap { isConnected -> Observable<T> in
                if isConnected {
                    return operation()
                } else {
                    return Observable.error(FirestoreError.networkUnavailable("네트워크 연결을 확인해주세요"))
                }
            }
    }
    
    /// 재시도 로직과 함께 작업 실행
    func executeWithRetry<T>(_ operation: @escaping () -> Observable<T>, maxRetries: Int = 3) -> Observable<T> {
        return operation()
            .retry { (errors: Observable<Error>) -> Observable<Int> in
                return errors
                    .enumerated()
                    .flatMap { (index: Int, error: Error) -> Observable<Int> in
                        let firestoreError = self.handleFirestoreError(error)
                        
                        // 재시도 가능한 에러이고 최대 재시도 횟수를 넘지 않은 경우
                        if firestoreError.isRetryable && index < maxRetries {
                            let delay = min(pow(2.0, Double(index)), 10.0) // 지수 백오프 (최대 10초)
                            return Observable<Int>.timer(
                                .milliseconds(Int(delay * 1000)),
                                scheduler: MainScheduler.instance
                            )
                            .map { _ in index }
                        } else {
                            return Observable<Int>.error(error)
                        }
                    }
            }
    }
}

// MARK: - Error Handling
extension FirestoreManager {
    
    /// Firestore 에러를 앱 에러로 변환 (네트워크 관련만)
    func handleFirestoreError(_ error: Error) -> FirestoreError {
        if let firestoreError = error as? FirestoreError {
            return firestoreError
        }
        
        // Firebase 에러 코드별 처리 (네트워크 관련만)
        if let nsError = error as NSError? {
            switch nsError.code {
            case FirestoreErrorCode.unavailable.rawValue:
                return .serverUnavailable("서버에 일시적으로 연결할 수 없습니다")
            case FirestoreErrorCode.deadlineExceeded.rawValue:
                return .connectionTimeout("요청 시간이 초과되었습니다")
            case FirestoreErrorCode.notFound.rawValue:
                return .documentNotFound
            case FirestoreErrorCode.permissionDenied.rawValue:
                return .permissionDenied("데이터 접근 권한이 없습니다")
            case FirestoreErrorCode.unauthenticated.rawValue:
                return .unauthenticated("사용자 인증이 필요합니다")
            default:
                return .unknownNetworkError
            }
        }
        
        return .unknownNetworkError
    }
}

// MARK: - Private Methods
private extension FirestoreManager {
    
    /// 네트워크 모니터링 설정
    func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            let isConnected = path.status == .satisfied
            self?.networkStatusSubject.onNext(isConnected)
        }
        networkMonitor.start(queue: networkQueue)
    }
    
    /// Firestore 설정 (deprecated 해결)
    func configureFirestore() {
        let settings = FirestoreSettings()
        
        // 캐시 설정 (더 안전한 방식)
        if #available(iOS 15.0, *) {
            // iOS 15+ 새로운 캐시 설정
            let cacheSize = NSNumber(value: FirestoreCacheSizeUnlimited)
            settings.cacheSettings = PersistentCacheSettings(sizeBytes: cacheSize)
        } else {
            // iOS 14 이하 - 기본 설정만 사용
            // deprecated 경고를 피하기 위해 기본값 사용
            print("iOS 14 이하에서는 기본 캐시 설정을 사용합니다.")
        }
        
        db.settings = settings
    }
}
