//
// Created by 김범수 on 2018. 2. 2..
// Copyright (c) 2018 piano. All rights reserved.
//

import RealmSwift


class RealmCategoryModel: Object {

    static let recordTypeString = "Category"

    @objc dynamic var id = ""
    @objc dynamic var name = ""

    @objc dynamic var recordName = ""
    @objc dynamic var isCreated = Date()
    @objc dynamic var isModified = Date()

    let notes = List<RealmNoteModel>()

    override static func primaryKey() -> String? {
        return "id"
    }

    override static func ignoredProperties() -> [String] {
        return ["recordTypeString"]
    }
}


class RealmNoteModel: Object {

    static let recordTypeString = "Note"

    @objc dynamic var id = ""
    @objc dynamic var title = ""
    @objc dynamic var content = String()

    @objc dynamic var recordName = ""
    @objc dynamic var isCreated = Date()
    @objc dynamic var isModified = Date()

    @objc dynamic var shareOwner: String? = nil //TODO: consider more if it really is required

    let images = List<RealmImageModel>()

    let category = LinkingObjects(fromType: RealmCategoryModel.self, property: "notes")

    override static func primaryKey() -> String? {
        return "id"
    }

    override static func ignoredProperties() -> [String] {
        return ["recordTypeString"]
    }
}

class RealmImageModel: Object {

    static let recordTypeString = "Image"

    @objc dynamic var id = ""
    @objc dynamic var original = Data()
    @objc dynamic var thumbnail = Data()

    @objc dynamic var recordName = ""
    @objc dynamic var isCreated = Date()
    @objc dynamic var isModified = Date()

    let note = LinkingObjects(fromType: RealmNoteModel.self, property: "images")

    override static func primaryKey() -> String? {
        return "id"
    }

    override static func ignoredProperties() -> [String] {
        return ["recordTypeString"]
    }
}

