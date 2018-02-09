//
// Created by 김범수 on 2018. 2. 6..
// Copyright (c) 2018 piano. All rights reserved.
//

import CryptoSwift

class UniqueIDGenerator {
    static func getUniqueID() -> String {
        
        let dateString = "\(Date().timeIntervalSinceReferenceDate)"
        let uuidString = UIDevice.current.identifierForVendor?.uuidString ?? "default_uuid"
        
        return (uuidString + dateString).sha256()
    }
}
