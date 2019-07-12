//
//  SMSubscriptionService+Observer.swift
//  Test Subscriptions App
//
//  Created by mac on 5/31/19.
//  Copyright © 2019 VRGSoft. All rights reserved.
//

import UIKit
import StoreKit

extension NSNotification.Name {
    static let kSmSubscriptionServicePurchaseSuccessfulNotification = Notification.Name("kSmSubscriptionServicePurchaseSuccessfulNotification")
}

extension SMSubscriptionService: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach { handlePurchasedState(for: $0, queue: queue) }
    }
    
    private func handlePurchasedState(for transaction: SKPaymentTransaction, queue: SKPaymentQueue) {
        SMSubscriptionService.shared.uploadReceipt { success in
            if success {
                queue.finishTransaction(transaction)
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .kSmSubscriptionServicePurchaseSuccessfulNotification, object: nil)
            }
        }
    }
}
