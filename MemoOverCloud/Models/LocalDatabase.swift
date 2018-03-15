//
//  LocalDatabase.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 2. 5..
//  Copyright © 2018년 piano. All rights reserved.
//

import RealmSwift

class LocalDatabase {
    static let shared = LocalDatabase()

    let databaseQueue = DispatchQueue.global(qos: .background)
    /*
     * This method is for creating object.
     */
    func saveObject (newObject: Object, completion handler: (() -> Void)? = nil) {

        databaseQueue.async {

            autoreleasepool {
                guard let realm = try? Realm() else {/* fatal error */return}

                try? realm.write {
                    realm.add(newObject, update: true)
                }
                handler?()
            }

        }

    }


    /*
     * This method is for updating object.
     */
    func updateObject<T> (ref: ThreadSafeReference<T>, kv: [String: Any], completion handler: (() -> Void)? = nil) where T: Object {

        databaseQueue.async {

            autoreleasepool {
                guard let realm = try? Realm(),
                        let object = realm.resolve(ref) else {/* fatal error */return}

                try? realm.write {
                    object.setValuesForKeys(kv)
                }
                handler?()
            }

        }

    }

    func updateObject(id: String, kv: [String: Any], type: Object.Type, completion handler: (() -> Void)? = nil) {
        databaseQueue.async {

            autoreleasepool {
                guard let realm = try? Realm(),
                        let object = realm.object(ofType: type.self, forPrimaryKey: id) else {return}

                try? realm.write {
                    object.setValuesForKeys(kv)
                }
                handler?()
            }
        }
    }

    /*
     * This method is for deleting objects.
     */
    func deleteObject<T> (ref: ThreadSafeReference<T>, completion handler: (() -> Void)? = nil) where T: Object {

        databaseQueue.async {

            autoreleasepool {
                guard let realm = try? Realm(),
                        let object = realm.resolve(ref) else {/* fatal error */ return}

                try? realm.write {
                    realm.delete(object)
                }
                handler?()
            }

        }

    }

    func deleteObject<T> (ref: ThreadSafeReference<Results<T>>, completion handler: (() -> Void)? = nil) where T: Object {

        databaseQueue.async {

            autoreleasepool {
                guard let realm = try? Realm(),
                        let object = realm.resolve(ref) else {/* fatal error */ return}

                try? realm.write {
                    realm.delete(object)
                }
                handler?()
            }

        }

    }
    /*
     * This method is for appending object to list.
     */

    func saveObjectWithAppend<T> (list: ThreadSafeReference<List<T>>, object: T, completion handler: (() -> Void)? = nil) where T: Object {

        databaseQueue.async {

            autoreleasepool {
                guard let realm = try? Realm(),
                        let list = realm.resolve(list) else {/* fatal error */ return}

                try? realm.write {
                    realm.add(object, update: true)
                    if !list.contains(object) { list.append(object) }
                }
                handler?()
            }

        }
     }
}
