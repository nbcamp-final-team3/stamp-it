//
//  SampleMissionEntity+CoreDataProperties.swift
//  StampIt-Project
//
//  Created by 권순욱 on 7/19/25.
//
//

public import Foundation
public import CoreData


public typealias SampleMissionEntityCoreDataPropertiesSet = NSSet

extension SampleMissionEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SampleMissionEntity> {
        return NSFetchRequest<SampleMissionEntity>(entityName: SampleMissionEntity.entityName)
    }

    @NSManaged public var categoryRaw: String
    @NSManaged public var isFavorite: Bool
    @NSManaged public var missionId: String?
    @NSManaged public var title: String?

    var category: MissionCategory {
        get {
            MissionCategory(rawValue: categoryRaw) ?? .chore
        }
        set {
            categoryRaw = newValue.rawValue
        }
    }
}

extension SampleMissionEntity : Identifiable {

}
