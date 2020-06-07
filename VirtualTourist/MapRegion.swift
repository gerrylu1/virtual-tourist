//
//  MapRegion.swift
//  VirtualTourist
//
//  Created by Gerry Low on 2020-06-07.
//  Copyright © 2020 Gerry Low. All rights reserved.
//

import Foundation

struct MapRegion: Codable {
    let latitude: Double
    let longitude: Double
    let latitudeDelta: Double
    let longitudeDelta: Double
}
