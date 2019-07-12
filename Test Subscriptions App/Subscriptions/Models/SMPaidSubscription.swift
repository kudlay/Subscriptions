//
//  SMPaidSubscription.swift
///  Test Subscriptions App
//
//  Created by mac on 5/31/19.
//  Copyright © 2019 VRGSoft. All rights reserved.
//

import Foundation

struct SMPaidSubscription
{
    enum Level: String, CaseIterable {
        case all
        
        init(productId: String) {
            if productId.contains("all") {
                self = .all
            }
            
            self = .all
        }
    }
    
    let productId: String
    let purchaseDate: Date
    let level: Level
    let period: SMSubscriptionPeriod
    
    private let _expiresDate: Date?
    
    var expiresDate: Date {
        return _expiresDate ?? getExpiresDate()
    }
    
    var isActive: Bool {
        return (purchaseDate...expiresDate).contains(Date())
    }
    
    init?(json: [String: Any]) {
        
        guard let productId = json["product_id"] as? String,
            let purchaseDateMSString = json["purchase_date_ms"] as? String,
            let purchaseDateMS = Double(purchaseDateMSString) else {
                return nil
        }
        
        let purchaseDate = Date(timeIntervalSince1970: purchaseDateMS / 1000)
        
        if let expiresDateMSString = json["expires_date_ms"] as? String,
            let expiresDateMS = Double(expiresDateMSString) {
            
            _expiresDate = Date(timeIntervalSince1970: expiresDateMS / 1000)
            
        } else {
            
            _expiresDate = nil
        }
        
        self.productId = productId
        self.purchaseDate = purchaseDate
        level = Level(productId: productId)
        period = SMSubscriptionPeriod(productId: productId)
    }
    
    private func getExpiresDate() -> Date {
        var dateComponents = DateComponents()
        
        switch period {
        case .month:
            if SMDefine.isSimulatorOrTestFlight {
                dateComponents.minute = 5
            } else {
                dateComponents.month = 1
            }
        case .year:
            if SMDefine.isSimulatorOrTestFlight {
                dateComponents.hour = 1
            } else {
                dateComponents.year = 1
            }
        case .unknown:
            break
        }
        
        let date = Calendar.current.date(byAdding: dateComponents, to: purchaseDate)
        
        return date ?? purchaseDate
    }
}
