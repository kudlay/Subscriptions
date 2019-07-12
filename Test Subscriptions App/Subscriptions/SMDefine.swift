//
//  SMDefine.swift
//  Test Subscriptions App
//
//  Created by mac on 5/31/19.
//  Copyright © 2019 VRGSoft. All rights reserved.
//

import Foundation

class SMDefine: NSObject {
    
    class var isSimulatorOrTestFlight: Bool {
        guard let path = Bundle.main.appStoreReceiptURL?.path else {
            return false
        }
        return path.contains("CoreSimulator") || path.contains("sandboxReceipt")
    }
}
