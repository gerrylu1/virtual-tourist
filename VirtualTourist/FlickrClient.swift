//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Gerry Low on 2020-06-09.
//  Copyright © 2020 Gerry Low. All rights reserved.
//

import Foundation

class FlickrClient {
    
    static let apiKey = Secrets.apiKey
    
    enum EndPoint {
        static let base = "https://www.flickr.com/services/rest"
        static let apiKeyParam = "?api_key=\(apiKey)"
        static let search = "&method=flickr.photos.search"
        static let jsonFormat = "&format=json&nojsoncallback=1"
        
        case searchPhotosByCoordinate(lat: Double, lon: Double, page: Int, perPage: Int)
        case getPhotoSourceURL(id: String, farmId: String, serverId: String, secret: String)
        
        var stringValue: String {
            switch self {
            case let .searchPhotosByCoordinate(lat, lon, page, perPage): return EndPoint.base + EndPoint.apiKeyParam + EndPoint.search + EndPoint.jsonFormat + "&lat=\(lat)&lon=\(lon)&page=\(page)&per_page=\(perPage)"
            case let .getPhotoSourceURL(id, farmId, serverId, secret): return "https://farm\(farmId).staticflickr.com/\(serverId)/\(id)_\(secret).jpg"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func searchPhotosByCoordinate(latitude: Double, longitude: Double, page: Int, perPage: Int, completion: @escaping (PhotoList?, Error?) -> Void) {
        taskForGETRequest(url: EndPoint.searchPhotosByCoordinate(lat: latitude, lon: longitude, page: page, perPage: perPage).url, responseType: PhotoSearchResponse.self) { (responseObject, error) in
            guard let responseObject = responseObject else {
                completion(nil, error)
                return
            }
            completion(responseObject.photos, nil)
        }
    }
    
    class func taskForGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> Void {
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            parseData(responseType: ResponseType.self, data: data, error: error) { (responseObject, error) in
                DispatchQueue.main.async {
                    completion(responseObject, error)
                }
            }
        }
        task.resume()
    }
    
    class func parseData<ResponseType: Decodable>(responseType: ResponseType.Type, data: Data?, error: Error?, completion: @escaping (ResponseType?, Error?) -> Void) {
        guard let data = data else {
            completion(nil, error)
            return
        }
        do {
            let responseObject = try JSONDecoder().decode(ResponseType.self, from: data)
            completion(responseObject, nil)
        } catch {
            do {
                let errorResponse = try JSONDecoder().decode(FailureResponse.self, from: data)
                completion(nil, errorResponse)
            } catch {
                completion(nil, error)
            }
        }
    }
    
}
