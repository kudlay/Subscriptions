//
//  SMSubscriptionPeriod.swift
//  Test Subscriptions App
//
//  Created by mac on 5/31/19.
//  Copyright © 2019 VRGSoft. All rights reserved.
//

import Foundation

enum SMSubscriptionPeriod {
    
    case month, year, unknown
    
    init(productId: String) {
        if productId.contains("month") {
            self = .month
        } else if productId.contains("year") {
            self = .year
        } else {
            self = .unknown
        }
    }
    
    var periodDescription: String {
        switch self {
        case .month:
            return "month"
        case .year:
            return "year"
        case .unknown:
            return ""
        }
    }
}
