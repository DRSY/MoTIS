//
//  StoreManager.swift
//  Gallery
//
//  Created by Alex on 17.02.2021.
//

import Foundation
import CoreData


protocol StoreServiceProtocol {
    func addPhotos(_ photos: [Photo])
    func getPhotos(complete: ([Photo]) -> Void)
    func deleteAllPhotos()
}

class StoreService {
    
    lazy var context = persistentContainer.viewContext

    //MARK: - Metods
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Gallery")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    private func saveContext () {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
}

// MARK: - StoreServiceProtocol

extension StoreService: StoreServiceProtocol {
    
    func addPhotos(_ photos: [Photo]) {
        photos.forEach {
            let photoEntity = PhotoEntity(context: context)
            photoEntity.photographer = $0.photographer
            photoEntity.date = $0.date
            photoEntity.urlString = $0.links.medium
        }
        saveContext()
    }
    

    
    func getPhotos(complete: ([Photo]) -> Void) {
        
        let request: NSFetchRequest = PhotoEntity.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: #keyPath(PhotoEntity.date), ascending: true)
        request.sortDescriptors = [sortDescriptor]
        do {
            let photoEntities = try context.fetch(request)
            let photos = photoEntities.map {
                Photo(photographer: $0.photographer, links: Links(medium: $0.urlString), date: $0.date)
            }
            complete(photos)
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    func deleteAllPhotos() {
        let request: NSFetchRequest = PhotoEntity.fetchRequest()
        do {
            let photoEntities = try context.fetch(request)
            photoEntities.forEach { context.delete($0) }
            saveContext()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
}
