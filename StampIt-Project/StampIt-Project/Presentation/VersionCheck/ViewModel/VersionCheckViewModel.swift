//
//  VersionCheckViewModel.swift
//  StampIt-Project
//
//  Created by iOS study on 7/1/25.
//

import Foundation

final class VersionCheckViewModel {
    private let service = VersionCheckService()

    func checkForceUpdate(completion: @escaping (Bool, String?) -> Void) {
        service.fetchLatestVersion { latestVersion, message in
            guard let latest = latestVersion,
                  let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
                completion(false, nil)
                return
            }
            let needUpdate = current.compare(latest, options: .numeric) == .orderedAscending
            completion(needUpdate, message)
        }
    }
}
