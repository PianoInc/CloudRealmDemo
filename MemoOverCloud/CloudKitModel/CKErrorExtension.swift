//
// Created by 김범수 on 2018. 2. 7..
// Copyright (c) 2018 piano. All rights reserved.
//

import CloudKit

extension CKError {

    /*
     * Incates whether item or zone is not present
     */
    public func isRecordNotFound() -> Bool {
        return isZoneNotFound() || isUnknownItem()
    }

    public func isZoneNotFound() -> Bool {
        return isSpecificErrorCode(code: .zoneNotFound)
    }

    public func isUnknownItem() -> Bool {
        return isSpecificErrorCode(code: .unknownItem)
    }

    public func isConflict() -> Bool {
        return isSpecificErrorCode(code: .serverRecordChanged)
    }

    /*
     * Identify CKError by matching code.
     * If the error code is partial failure which implies multiple errors have occured,
     * Iterate through the errors if the matching error exists
     */
    public func isSpecificErrorCode(code: CKError.Code) -> Bool {
        var match = false

        if self.code == code { match = true }
        else if self.code == .partialFailure {
           guard let errors = partialErrorsByItemID else { return false }

            for (_, error) in errors {
                if let cloudError = error as? CKError {
                    if cloudError.code == code {
                        match = true
                        break
                    }
                }
            }
        }

        return match
    }

    /*
     * See if error is occured by conflict between server and client
     * In case of partial error, iterate over to check if one of the errors is occured by conflict
     */

    public func getMergeRecords() -> (CKRecord?, CKRecord?, CKRecord?) {
        if code == .serverRecordChanged {
            return (ancestorRecord, clientRecord, serverRecord)
        }

        guard code == .partialFailure,
                let errors = partialErrorsByItemID else {return (nil, nil, nil)}

        for (_, error) in errors {
            if let cloudError = error as? CKError {
                if cloudError.code == .serverRecordChanged {
                    return cloudError.getMergeRecords()
                }
            }
        }

        return (nil, nil, nil)
    }
}
