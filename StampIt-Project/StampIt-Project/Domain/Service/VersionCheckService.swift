//
//  VersionCheckService.swift
//  StampIt-Project
//
//  Created by iOS study on 7/1/25.
//

import FirebaseFirestore

final class VersionCheckService {
    func fetchLatestVersion(completion: @escaping (String?, String?) -> Void) {
        let db = Firestore.firestore()
        db.collection("config").document("appConfig").getDocument { snapshot, error in
            let data = snapshot?.data()
            let version = data?["latestVersion"] as? String
            let message = data?["forceUpdateMessage"] as? String
            completion(version, message)
        }
    }
}
