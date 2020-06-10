//
//  PhotoResponse.swift
//  VirtualTourist
//
//  Created by Gerry Low on 2020-06-10.
//  Copyright © 2020 Gerry Low. All rights reserved.
//

import Foundation

struct PhotoInfo: Codable {
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: String
    let title: String
    let ispublic: Bool
    let isfriend: Bool
    let isfamily: Bool
}
