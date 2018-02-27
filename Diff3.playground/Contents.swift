//: Playground - noun: a place where people can play

import UIKit

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
    
    static func makeItUP(ancestor: String, a: String, b: String) -> String {
        var Lo = 0
        var La = 0
        var Lb = 0
        var commonLength = 0
        var oWordIndices: [String: ReferenceArray<Int>] = [:]
        var aWordIndices: [String: ReferenceArray<Int>] = [:]
        var bWordIndices: [String: ReferenceArray<Int>] = [:]
        
        //chunk it up & make indice lists
        
        let oChunks = ancestor.components(separatedBy: "\n")
        let aChunks = a.components(separatedBy: "\n")
        let bChunks = b.components(separatedBy: "\n")
        var finalChunks:[DiffStatus] = []
        
        for (index, string) in oChunks.enumerated() {
            let array = oWordIndices[string] ?? ReferenceArray<Int>()
            
            if oWordIndices[string] == nil { oWordIndices[string] = array }
            
            array.append(index)
        }
        
        for (index, string) in aChunks.enumerated() {
            let array = aWordIndices[string] ?? ReferenceArray<Int>()
            
            if aWordIndices[string] == nil { aWordIndices[string] = array }
            
            array.append(index)
        }
        
        for (index, string) in bChunks.enumerated() {
            let array = bWordIndices[string] ?? ReferenceArray<Int>()
            
            if bWordIndices[string] == nil { bWordIndices[string] = array }
            
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
                    
                    if let aWordIndex = aWordIndices[currentOWord], let bWordIndex = bWordIndices[currentOWord] {
                        
                        a = aWordIndex.getFirstElement(largerThan: La)
                        b = bWordIndex.getFirstElement(largerThan: Lb)
                        
                        if aWordIndex.count == 0 {
                            aWordIndices[currentOWord] = nil
                        }
                        if bWordIndex.count == 0 {
                            bWordIndices[currentOWord] = nil
                        }
                        
                        break
                    }
                    o += 1
                }

                
                guard let a1 = a, let b1 = b else {break}
                
                let originalChunk = oChunks[Lo..<o].joined(separator: "\n")
                let aChunk = aChunks[La..<a1].joined(separator: "\n")
                let bChunk = bChunks[Lb..<b1].joined(separator: "\n")
                
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
                
                finalChunks.append(.stable(commonChunks.joined(separator: "\n")))
                commonLength = 0
            }
        }
        
        //third step
        //add final chunks
        
        let originalChunk = oChunks[Lo..<oChunks.count].joined(separator: " ")
        let aChunk = aChunks[La..<aChunks.count].joined(separator: " ")
        let bChunk = bChunks[Lb..<bChunks.count].joined(separator: " ")
        
        finalChunks.append(.conflict(originalChunk, aChunk, bChunk))
        
        return finalChunks.getResolvedString()
    }
}

let lala = """
class MyClass: CustomStringConvertible {
var string: String?


var description: String {
//return \"MyClass \\(string)\"
return \"\\(self.dynamicType)\"
}
}

var myClass = MyClass()  // this line outputs MyClass nil

// and of course
print(\"\\(myClass)\")

// Use this newer versions of Xcode
var description: String {
//return \"MyClass \\(string)\"
return \"\\(type(of: self))\"
}
"""

let lalaa = """
class MyClass: CustomStringConvertible {
var string: String?


var description: String {
//return \"MyClass \\(string)\"
It;s not my string you fool
return \"\\(self.dynamicType)\"
}
}

new Script = lalallanananan lowlow

var myClass = MyClass()  // this line outputs MyClass nil

// and of course
print(\"\\(myClass)\")

// Use this newer versions of Xcode
var description: String {
//return \"MyClass \\(string)\"
return \"\\(type(of: self))\"
}
"""

let lalab = """
class MyClass: CustomStringConvertible {
var string: String?


var description: String {
//return \"MyClass \\(string)\"
return \"\\(self.dynamicType)\"
}
}

struct newStruct {
    var lalala lilili
    new nono
}

var myClass = MyClass()  // this line outputs MyClass nil

// and of course
print(\"\\(myClass)\")

// Use this newer versions of Xcode
I don't want description
}
"""
print(Diff3.makeItUP(ancestor: lala, a: lalaa, b: lalab))
