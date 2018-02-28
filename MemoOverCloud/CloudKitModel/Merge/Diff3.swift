//
// Created by 김범수 on 2018. 2. 28..
// Copyright (c) 2018 piano. All rights reserved.
//

import Foundation

enum DiffStatus: CustomStringConvertible {
    case stable(String)
    case conflict(String,String,String)

    var description: String {
        switch self {
        case .stable(let s): return "stable: \(s)"
        case .conflict(let an, let a, let b): return "conflicted \nancestor: \(an)\na: \(a)\nb: \(b)"
        }
    }
}

class ReferenceArray<T>: CustomStringConvertible {
    var description: String {
        return array.description
    }

    var count: Int {
        return array.count
    }

    private var array:[T] = []


    func append(_ newElement: T) {
        array.append(newElement)
    }

    subscript(_ index: Int) -> T {
        get {
            return array[index]
        } set {
            array[index] = newValue
        }
    }

}

extension ReferenceArray where T == Int {
    func getFirstElement(largerThan value: Int) -> Int? {
        guard let index = array.index(where: { (element) -> Bool in
            return element >= value
        }) else {return nil}
        let result = array[index]

        array.removeSubrange(index..<array.endIndex)

        return result
    }
}


extension Array where Element == String {
    func combineChunks() -> String {
        return String(self.reduce("") { (resultString, element) -> String in
            resultString+element+"\n"
        }.dropLast())
    }
}

extension Array where Element == DiffStatus {
    func getResolvedString() -> String {
        return self.reduce("") { (resultString, diffStatus) -> String in
            var diffString = ""
            switch diffStatus {
            case .stable(let stableString): diffString = stableString
            case .conflict(let ancestor, let myString, let serverString):
                if ancestor == myString {
                    diffString = serverString
                } else if ancestor == serverString || myString == serverString {
                    diffString = myString
                } else {
                    //serious conflict!
                    diffString = """
                    Serious Conflict!!!

                    my
                    ---------------------
                    \(myString)
                    ---------------------
                    server
                    \(serverString)
                    ---------------------
                    """
                }
            }
            return resultString + diffString + "\n"
        }
    }
}



class Diff3 {

    static func merge(ancestor: String, a: String, b: String) -> String {
        let seperator = "\n"
        var Lo = 0
        var La = 0
        var Lb = 0
        var commonLength = 0
        var oLineIndices: [String: ReferenceArray<Int>] = [:]
        var aLineIndices: [String: ReferenceArray<Int>] = [:]
        var bLineIndices: [String: ReferenceArray<Int>] = [:]

        //chunk it up & make indice lists

        let oChunks = ancestor.components(separatedBy: seperator)
        let aChunks = a.components(separatedBy: seperator)
        let bChunks = b.components(separatedBy: seperator)
        var finalChunks:[DiffStatus] = []

        for (index, string) in oChunks.enumerated() {
            let array = oLineIndices[string] ?? ReferenceArray<Int>()

            if oLineIndices[string] == nil { oLineIndices[string] = array }

            array.append(index)
        }

        for (index, string) in aChunks.enumerated() {
            let array = aLineIndices[string] ?? ReferenceArray<Int>()

            if aLineIndices[string] == nil { aLineIndices[string] = array }

            array.append(index)
        }

        for (index, string) in bChunks.enumerated() {
            let array = bLineIndices[string] ?? ReferenceArray<Int>()

            if bLineIndices[string] == nil { bLineIndices[string] = array }

            array.append(index)
        }

        while(Lo+commonLength<oChunks.count && La+commonLength<aChunks.count
                && Lb+commonLength<bChunks.count) {
            // whole loop -> add finite conditions!

            //first step - find longest stable chunk
            if oChunks[Lo+commonLength] == aChunks[La+commonLength] &&
                       oChunks[Lo+commonLength] == bChunks[Lb+commonLength] {
                commonLength += 1
                continue
            }


            //second step
            if commonLength == 0 {
                // conflict occured!
                var o = Lo
                var a: Int? = nil
                var b: Int? = nil

                while(o<oChunks.count) {
                    let currentOWord = oChunks[o]

                    if let aWordIndex = aLineIndices[currentOWord], let bWordIndex = bLineIndices[currentOWord] {

                        a = aWordIndex.getFirstElement(largerThan: La)
                        b = bWordIndex.getFirstElement(largerThan: Lb)

                        if aWordIndex.count == 0 {
                            aLineIndices[currentOWord] = nil
                        }
                        if bWordIndex.count == 0 {
                            bLineIndices[currentOWord] = nil
                        }

                        break
                    }
                    o += 1
                }


                guard let a1 = a, let b1 = b else {break}

                let originalChunk = oChunks[Lo..<o].joined(separator: seperator)
                let aChunk = aChunks[La..<a1].joined(separator: seperator)
                let bChunk = bChunks[Lb..<b1].joined(separator: seperator)

                Lo = o
                La = a1
                Lb = b1

                finalChunks.append(.conflict(originalChunk, aChunk, bChunk))
                //first match o with a&b, then pop them
                //l+offset -> o-1, l+offset -> a-1, l+offset -> b-1 conflict!!!
                //l = o, a, b
                //if no o then break
            } else {
                // common block add
                //l -> l+offset common block
                //l = l+offset+1

                let commonChunks = oChunks[Lo..<Lo+commonLength]

                Lo += commonLength
                La += commonLength
                Lb += commonLength

                finalChunks.append(.stable(commonChunks.joined(separator: seperator)))
                commonLength = 0
            }
        }

        //third step
        //add final chunks

        let originalChunk = oChunks[Lo..<oChunks.count].joined(separator: seperator)
        let aChunk = aChunks[La..<aChunks.count].joined(separator: seperator)
        let bChunk = bChunks[Lb..<bChunks.count].joined(separator: seperator)

        finalChunks.append(.conflict(originalChunk, aChunk, bChunk))

        //TODO: resolve attribute conflicts also
        //get each chunks range to pull out the attributes!!
        //How should i pass attributes???
        //1. Cover a String with attributes
        //2. make Insert & deletion blocks



        return finalChunks.getResolvedString()
    }
}