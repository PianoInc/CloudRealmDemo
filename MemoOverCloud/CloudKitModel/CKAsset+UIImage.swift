//
// Created by 김범수 on 2018. 2. 8..
// Copyright (c) 2018 piano. All rights reserved.
//

import UIKit
import CloudKit


enum ImageFileType {
    case JPG(compressionQuality: CGFloat)
    case PNG

    var fileExtension: String {
        switch self {
        case .JPG(_):
            return ".jpg"
        case .PNG:
            return ".png"
        }
    }
}

enum ImageError: Error {
    case UnableToConvertImageToData
}

extension CKAsset {
    convenience init(image: UIImage, fileType: ImageFileType = .JPG(compressionQuality: 70)) throws {
        let url = try image.saveImageToTempLocationWithFileType(fileType: fileType)
        self.init(fileURL: url)
    }

    convenience init(data: Data) throws {
        let url = try data.saveDataToTempLocation(fileType: .JPG(compressionQuality: 70))
        self.init(fileURL: url)
    }

    var image: UIImage? {
        guard let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) else { return nil }
        return image
    }
}

extension UIImage {
    func saveImageToTempLocationWithFileType(fileType: ImageFileType) throws -> URL {
        let imageData: Data?

        switch fileType {
        case .JPG(let quality):
            imageData = UIImageJPEGRepresentation(self, quality)
        case .PNG:
            imageData = UIImagePNGRepresentation(self)
        }
        guard let data = imageData else {
            throw ImageError.UnableToConvertImageToData
        }



        return try data.saveDataToTempLocation(fileType: fileType)
    }


}

extension Data {

    func saveDataToTempLocation(fileType: ImageFileType) throws -> URL {

        let filename = ProcessInfo.processInfo.globallyUniqueString + fileType.fileExtension
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
        try self.write(to: url, options: .atomicWrite)

        return url
    }
}