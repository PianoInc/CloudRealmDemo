//
// Created by 김범수 on 2018. 2. 5..
// Copyright (c) 2018 piano. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift

class LocalCache {
    static let shared = LocalCache()

    private let imageCache = NSCache<NSString, UIImage>()
    private let observer = RealmImageObserver()

    init() {
        imageCache.countLimit = 100
    }

    func saveImage(image: UIImage, id: String) {
        imageCache.setObject(image, forKey: id.nsString)
    }

    func getImage(id: String) -> UIImage? {
        return imageCache.object(forKey: id.nsString)
    }
    

    func updateThumbnailCacheWithID(id: String, width: CGFloat, height: CGFloat, handler: @escaping ((UIImage) -> Void)) {

        guard let realm = try? Realm() else {return}
        //ID without suffix "thumb"
        let realID = String(id[..<id.index(id.endIndex, offsetBy: -5)])

        let refHandler: ((ThreadSafeReference<RealmImageModel>) -> Void) =
                { [weak self] (ref) in
                    DispatchQueue.global(qos: .background).async {
                        autoreleasepool {
                            guard let realm = try? Realm(),
                                  let imageModel = realm.resolve(ref) else {return}

                            if let thumbImage = UIImage(data: imageModel.image)?.resizeImage(size: CGSize(width: width, height: height)) {
                                self?.imageCache.setObject(thumbImage, forKey: id.nsString)
                                handler(thumbImage)
                            }
                        }
                    }
                }

        if let imageModel = realm.object(ofType: RealmImageModel.self, forPrimaryKey: realID) {
            //Model is present in realm

            let ref = ThreadSafeReference(to: imageModel)
            refHandler(ref)
        } else {
            //Model is not present in realm

            observer.setHandler(for: realID, handler: refHandler)
        }

    }
}
