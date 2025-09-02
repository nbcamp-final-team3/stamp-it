//
//  MissionDataEntity+CoreDataClass.swift
//  StampIt-Project
//
//  Created by 권순욱 on 8/3/25.
//
//

public import Foundation
public import CoreData

public typealias MissionDataEntityCoreDataClassSet = NSSet

@objc(MissionDataEntity)
public class MissionDataEntity: NSManagedObject {
    static let entityName = "MissionDataEntity"
}
