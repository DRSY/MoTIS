//
//  PhotoEntity+CoreDataProperties.swift
//  Gallery
//
//  Created by Alex on 17.02.2021.
//
//

import Foundation
import CoreData


extension PhotoEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PhotoEntity> {
        return NSFetchRequest<PhotoEntity>(entityName: "PhotoEntity")
    }

    @NSManaged public var photographer: String
    @NSManaged public var date: Date
    @NSManaged public var urlString: String

}

extension PhotoEntity : Identifiable {

}
