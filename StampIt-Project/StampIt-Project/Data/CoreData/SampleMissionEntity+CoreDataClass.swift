//
//  SampleMissionEntity+CoreDataClass.swift
//  StampIt-Project
//
//  Created by 권순욱 on 7/19/25.
//
//

public import Foundation
public import CoreData

public typealias SampleMissionEntityCoreDataClassSet = NSSet

@objc(SampleMissionEntity)
public class SampleMissionEntity: NSManagedObject {
    static let entityName = "SampleMissionEntity"
}
