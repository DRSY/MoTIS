//
//  Response.swift
//  Gallery
//
//  Created by Alex on 16.02.2021.
//

import Foundation

struct Response: Decodable {
    var photos: [Photo]
    let nextPageUrl: String?
    
    init?(data: Data) {
        if let jsonData = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions()) as? [String: Any],
           let nextPageUrl = jsonData["next_page"] as? String,
           let photosDict = jsonData["photos"] as? [[String: Any]] {
            let photos: [Photo] = photosDict.compactMap { item in
                var photo: Photo?
                if let photographer = item["photographer"] as? String, let src = item["src"] as? [String: Any], let medium = src["medium"] as? String {
                    photo = Photo(photographer: photographer, links: Links(medium: medium), date: Date())
                }
                return photo
            }
            self.photos = photos
            self.nextPageUrl = nextPageUrl
        } else {
            return nil
        }
    }
}

struct Photo: Decodable {
    let photographer: String
    let links: Links
    var date: Date
}

struct Links: Decodable {
    let medium: String
}
