//
//  SMSubscription.swift
///  Test Subscriptions App
//
//  Created by mac on 5/31/19.
//  Copyright © 2019 VRGSoft. All rights reserved.
//

import Foundation
import StoreKit

private var formatter: NumberFormatter = {
  let formatter = NumberFormatter()
  formatter.numberStyle = .currency
  formatter.formatterBehavior = .behavior10_4
  
  return formatter
}()

struct SMSubscription {
    
    let product: SKProduct
    let formattedPrice: String
    let title: String
    let description: String
    let period: SMSubscriptionPeriod
    
    var formattedDescription: String {
        return formattedPrice + " per " + period.periodDescription
    }
    
    init(product: SKProduct) {
        
        self.product = product
    
        if formatter.locale != product.priceLocale {
            formatter.locale = product.priceLocale
        }
    
        formattedPrice = formatter.string(from: product.price) ?? "\(product.price)"
        period = SMSubscriptionPeriod(productId: product.productIdentifier)
        title = product.localizedTitle
        description = product.localizedDescription
    }
}
