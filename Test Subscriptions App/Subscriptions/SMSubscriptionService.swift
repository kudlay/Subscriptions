//
//  SMSubscriptionService.swift
//  Test Subscriptions App
//
//  Created by mac on 5/31/19.
//  Copyright © 2019 VRGSoft. All rights reserved.
//

import Foundation
import StoreKit
import Alamofire

extension NSNotification.Name {
    static let kSMSubscriptionServiceOptionsLoadedNotification = Notification.Name("kSMSubscriptionServiceOptionsLoadedNotification")
    static let kSMSubscriptionServicePaidSubscriptionsDidUpdate = Notification.Name("kSMSubscriptionServicePaidSubscriptionsDidUpdate")
}

let kSMPaidSubscriptionsUDKey = "kSMPaidSubscriptionsUDKey"

class SMSubscriptionService: NSObject, SKProductsRequestDelegate
{
    static let shared = SMSubscriptionService()
    
    private lazy var networkReachabilityManager: NetworkReachabilityManager? = {
        let networkReachabilityManager = NetworkReachabilityManager()
        return networkReachabilityManager
    }()
    
    private var waitingForFirstReceiptUpload: Bool = true
    private var isOfflineMode: Bool = false
    private var loadSubscriptionCompletion: (([SMSubscription]?) -> Void)?
    
    private var hasReceiptData: Bool {
        return loadReceipt() != nil
    }
    
    private var paidSubscriptions: [SMPaidSubscription] = [] {
        didSet {
            saveLastSubscriptionsDateIfCan()
            NotificationCenter.default.post(name: .kSMSubscriptionServicePaidSubscriptionsDidUpdate, object: nil, userInfo: nil)
        }
    }
  
    private var subscriptions: [SMSubscription]? {
        didSet {
            loadSubscriptionCompletion?(subscriptions)
            loadSubscriptionCompletion = nil
            NotificationCenter.default.post(name: .kSMSubscriptionServiceOptionsLoadedNotification, object: subscriptions)
        }
    }
    
    
    // MARK: - Life cycle methods
    
    override init() {
        super.init()
        setup()
    }
    
    private func setup() {
        uploadReceipt()
        networkReachabilityManager?.startListening()
        
        networkReachabilityManager?.listener = { [weak self] reachableStatus in
            if self?.waitingForFirstReceiptUpload != true,
                self?.networkReachabilityManager?.isReachable == true
            {
                self?.isOfflineMode = false
                self?.uploadReceipt()
            }
        }
    }
    
    
    // MARK: - SubscriptionOptions
    
    func getSubscriptionOptions(completion: @escaping ([SMSubscription]?) -> Void) {
        loadSubscriptionOptionsIfNeeded(completion: completion)
    }
  
    private func loadSubscriptionOptionsIfNeeded(completion: (([SMSubscription]?) -> Void)? = nil)
    {
        if let options = subscriptions,
            !options.isEmpty {
            completion?(options)
        } else {
            loadSubscriptionCompletion = completion
            
            let monthly = "auto_month_subscription_all"
            let annually  = "auto_year_subscription_all"
            
            let productIDs = Set([monthly, annually])
            
            let request = SKProductsRequest(productIdentifiers: productIDs)
            request.delegate = self
            request.start()
        }
    }
    
    
    // MARK: - Purchase
  
    func purchase(subscription: SMSubscription) {
        let payment = SKPayment(product: subscription.product)
        SKPaymentQueue.default().add(payment)
    }
  
    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
  
    
    // MARK: - Receipt
    
    func uploadReceipt(completion: ((_ success: Bool) -> Void)? = nil) {
        if let receiptData = loadReceipt() {
            SMValidationService.shared.upload(receipt: receiptData) { [weak self] result in
                self?.waitingForFirstReceiptUpload = false
                switch result {
                case .success(let paidSubscriptions):
                    self?.paidSubscriptions = paidSubscriptions
                    completion?(true)
                case .failure(let error):
                    self?.isOfflineMode = self?.networkReachabilityManager?.isReachable != true && (error as NSError).code == NSURLErrorNotConnectedToInternet
                    completion?(false)
                }
            }
        } else {
            /*
            let receiptRefreshRequest = SKReceiptRefreshRequest(receiptProperties: nil)
            receiptRefreshRequest.delegate = self
            receiptRefreshRequest.start()
             */
            completion?(false)
        }
    }
    
    private func loadReceipt() -> Data? {
        guard let url = Bundle.main.appStoreReceiptURL else { return nil }
        
        do {
            let data = try Data(contentsOf: url)
            return data
        } catch {
            return nil
        }
    }
    
    
    // MARK: Subscriptions
    
    func activeSubscriptionForLevel(_ level: SMPaidSubscription.Level) -> SMPaidSubscription? {
        let activePaidSubscriptionForLevel = activePaidSubscriptionsForLevel(level)
        let sortedByMostRecentPurchase = activePaidSubscriptionForLevel.sorted { $0.expiresDate > $1.expiresDate }
        return sortedByMostRecentPurchase.first
    }
    
    func activePaidSubscriptionsForLevel(_ level: SMPaidSubscription.Level) -> [SMPaidSubscription] {
        let activePaidSubscriptions = paidSubscriptions.filter { $0.isActive }
        let subscriptionForLevel = activePaidSubscriptions.filter { $0.level == level }
        return subscriptionForLevel
    }
    
    func isActiveSubscriptionForLevel(_ level: SMPaidSubscription.Level) -> Bool {
        var result: Bool = false
        
        if hasReceiptData {
            if !isOfflineMode,
                activeSubscriptionForLevel(level) != nil
            {
                result = true
            } else if let date = lastSubscriptionsDateForLevel(level) {
                result = date > Date()
            }
        }

        return result
    }
    
    private func saveLastSubscriptionsDateIfCan()
    {
        for level in SMPaidSubscription.Level.allCases {
            if let activeSubscriptionForLevel = activeSubscriptionForLevel(level) {
                UserDefaults.standard.set(activeSubscriptionForLevel.expiresDate, forKey: kSMPaidSubscriptionsUDKey + level.rawValue)
            }
        }
    }
    
    private func lastSubscriptionsDateForLevel(_ level: SMPaidSubscription.Level) -> Date? {
        return UserDefaults.standard.object(forKey: kSMPaidSubscriptionsUDKey + level.rawValue) as? Date
    }
    
    
    // MARK: - SKProductsRequestDelegate
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        subscriptions = response.products.map { SMSubscription(product: $0) }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        subscriptions = nil
    }
}
