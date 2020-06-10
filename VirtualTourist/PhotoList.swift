//
//  PhotoListResponse.swift
//  VirtualTourist
//
//  Created by Gerry Low on 2020-06-10.
//  Copyright © 2020 Gerry Low. All rights reserved.
//

import Foundation

struct PhotoList: Codable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: String
    let photo: [PhotoInfo]
}
