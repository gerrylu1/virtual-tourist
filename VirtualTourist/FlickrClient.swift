//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Gerry Low on 2020-06-09.
//  Copyright © 2020 Gerry Low. All rights reserved.
//

import Foundation

class FlickrClient {
    
    static let apiKey = "<<API_KEY>>"
    
    enum EndPoint {
        static let base = "https://www.flickr.com/services/rest"
        static let search = "&method=flickr.photos.search"
        static let apiKeyParam = "?api_key=\(apiKey)"
        
        case searchPhotosByCoordinate(lat: Double, lon: Double)
        case getPhotoSourceURL(id: String, farmId: String, serverId: String, secret: String)
        
        var stringValue: String {
            switch self {
            case let .searchPhotosByCoordinate(lat, lon): return EndPoint.base + EndPoint.apiKeyParam + EndPoint.search + "&lat=\(lat)&lon=\(lon)"
            case let .getPhotoSourceURL(id, farmId, serverId, secret): return "https://farm\(farmId).staticflickr.com/\(serverId)/\(id)_\(secret).jpg"
            }
        }
    }
    
}
