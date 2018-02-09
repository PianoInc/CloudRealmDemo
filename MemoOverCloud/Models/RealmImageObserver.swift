//
// Created by 김범수 on 2018. 2. 6..
// Copyright (c) 2018 piano. All rights reserved.
//

import Foundation
import RealmSwift


/*
 * There are several cases that image is not present in database when user
 * requests for the non-present image.
 * Since the user only wants to be notified when the image has updated to cache
 * and cache don't want to bother any messy job,
 * this class will observe realm and provide handler service to cache
 */

class RealmImageObserver {

    private var notificationToken: NotificationToken?
    private var handlerDic:[String: ((ThreadSafeReference<RealmImageModel>) -> Void)]  = [:]


    deinit {
        notificationToken?.invalidate()
    }

    init() {
        guard let realm = try? Realm() else {/* fatal error! */ return }

        notificationToken = realm.objects(RealmImageModel.self).observe { [weak self] (change) in
            switch change {
            case .initial: break
            case .update(let results,_,let inserts,_):
                inserts.forEach{
                    guard let strongHandlerDic = self?.handlerDic else {return}

                    let id = results[$0].id
                    let ref = ThreadSafeReference(to: results[$0])
                    if let handler = strongHandlerDic[id] {
                        self?.handlerDic.removeValue(forKey: id)
                        handler(ref)
                    }
                }
            case .error: fatalError()
            }
        }
    }

    func setHandler(for id: String, handler: @escaping ((ThreadSafeReference<RealmImageModel>) -> Void)) {
        handlerDic[id] = handler
    }
}