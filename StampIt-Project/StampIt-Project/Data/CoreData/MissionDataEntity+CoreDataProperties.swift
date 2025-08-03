//
//  MissionDataEntity+CoreDataProperties.swift
//  StampIt-Project
//
//  Created by 권순욱 on 8/3/25.
//
//

public import Foundation
public import CoreData


public typealias MissionDataEntityCoreDataPropertiesSet = NSSet

extension MissionDataEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MissionDataEntity> {
        return NSFetchRequest<MissionDataEntity>(entityName: MissionDataEntity.entityName)
    }

    @NSManaged public var title: String?
    @NSManaged public var assigneeId: String?
    @NSManaged public var assigneeNickname: String?
    @NSManaged public var createDate: Date?
    @NSManaged public var dueDate: Date?
    @NSManaged public var categoryRaw: String
    
    var category: MissionCategory {
        get {
            MissionCategory(rawValue: categoryRaw) ?? .chore
        }
        set {
            categoryRaw = newValue.rawValue
        }
    }
}

extension MissionDataEntity : Identifiable {

}
