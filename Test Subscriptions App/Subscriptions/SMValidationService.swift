//
//  SMValidationService.swift
//  Test Subscriptions App
//
//  Created by mac on 5/31/19.
//  Copyright © 2019 VRGSoft. All rights reserved.
//

import Foundation

private let itcAccountSecret = "4f526ac74146470baf2dt5bf28f7e2c2"

enum SMValidationServiceResult<T> {
    case failure(Error)
    case success(T)
    
    static var missingParseDataError: SMValidationServiceResult {
        return .failure(NSError(domain: "Missing Parse Data", code: 0, userInfo: nil))
    }
    
    static var missingResponseDataError: SMValidationServiceResult {
        return .failure(NSError(domain: "Missing Response Data", code: 0, userInfo: nil))
    }
}

typealias SMPaidSubscriptionsCompletion = (_ subscriptions: SMValidationServiceResult<[SMPaidSubscription]>) -> Void
typealias SMUploadReceiptCompletion = (_ result: SMValidationServiceResult<([SMPaidSubscription])>) -> Void

class SMValidationService {
    
    static let shared = SMValidationService()
    
    private var task: URLSessionDataTask?
    private var isSandbox: Bool = false
    
    func upload(receipt data: Data, completion: @escaping SMUploadReceiptCompletion) {
        task?.cancel()
        
        let urlString: String = {
            if isSandbox {
                return "https://sandbox.itunes.apple.com/verifyReceipt"
            } else {
                return "https://buy.itunes.apple.com/verifyReceipt"
            }
        }()
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: " ", code: 0, userInfo: nil)))
            return
        }
        
        let body = ["receipt-data": data.base64EncodedString(), "password": itcAccountSecret]
        let bodyData = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        
        task = URLSession.shared.dataTask(with: request) { [weak self] responseData, response, error in
            self?.dataTaskCompletionHandler(receipt: data,
                                            responseData: responseData,
                                            response: response,
                                            error: error,
                                            completion: completion)
        }
        task?.resume()
    }
    
    private func dataTaskCompletionHandler(receipt data: Data,
                                           responseData: Data?,
                                           response: URLResponse?,
                                           error: Error?,
                                           completion: @escaping SMUploadReceiptCompletion) -> Void {
        if let error = error {
            
            if (error as NSError).code == 100500 {
                
                isSandbox = true
                upload(receipt: data, completion: completion)
                
            } else {
                completion(.failure(error))
            }
            
        } else if let responseData = responseData {
            
            do {
                let json = try JSONSerialization.jsonObject(with: responseData, options: [])
                
                if let parsedReceipt = json as? [String: Any] ,
                    let receipt = parsedReceipt["receipt"] as? [String: Any],
                    let purchases = receipt["in_app"] as? [[String: Any]] {
                    
                    let subscriptions: [SMPaidSubscription] = purchases.compactMap { SMPaidSubscription(json: $0) }
                    completion(.success(subscriptions))
                    
                } else {
                    completion(SMValidationServiceResult.missingParseDataError)
                }
            }
            catch let error {
                completion(.failure(error))
            }
            
        } else {
            completion(SMValidationServiceResult.missingResponseDataError)
        }
    }
}
