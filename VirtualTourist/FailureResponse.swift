//
//  FailureResponse.swift
//  VirtualTourist
//
//  Created by Gerry Low on 2020-06-10.
//  Copyright © 2020 Gerry Low. All rights reserved.
//

import Foundation

struct FailureResponse: Codable {
    let stat: String
    let code: Int
    let message: String
}

extension FailureResponse: LocalizedError {
    var errorDescription: String? {
        return message
    }
}
