//
//  SampleMissionRepository.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/5/25.
//

import Foundation

protocol SampleMissionRepository {
    func loadData() -> [SampleMission]
}

final class SampleMissionRepositoryImpl: SampleMissionRepository {
    func loadData() -> [SampleMission] {
        let houses: [SampleMission] = load("house+category.json")
        let families: [SampleMission] = load("family+category.json")
        return houses + families
    }
    
    private func load<T: Decodable>(_ filename: String) -> T {
        let data: Data
        
        guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
        else {
            fatalError("Couldn't find \(filename) in main bundle.")
        }
        
        do {
            data = try Data(contentsOf: file)
        } catch {
            fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
        }
    }
}
