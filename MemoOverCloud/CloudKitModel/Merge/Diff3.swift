//
// Created by 김범수 on 2018. 2. 28..
// Copyright (c) 2018 piano. All rights reserved.
//

import Foundation


struct Stack<Element> {
    
    private var items = [Element]()
    
    var count: Int {
        return items.count
    }
    
    mutating func push(_ item: Element) {
        items.append(item)
    }
    
    mutating func pop() -> Element? {
        return count == 0 ? nil : items.removeLast()
    }
    
    
    
    func isEmpty() -> Bool {
        return self.count == 0
    }
}

enum Diff3Block {
    case add(Int, NSRange)
    case delete(NSRange)
    case change(NSRange, NSRange)
    case conflict(NSRange, NSRange)
}


class Diff3 {
    
    static func merge(ancestor: String, a: String, b: String) -> [Diff3Block] {
        let aDiffMaker = DiffMaker(aString: ancestor, bString: a)
        let bDiffMaker = DiffMaker(aString: ancestor, bString: b)
        
        let oaDiffChunks = aDiffMaker.parseTwoStrings()
        let obDiffChunks = bDiffMaker.parseTwoStrings()
        
        var diff3Chunks: [Diff3Block] = []
        var conflictArray: [(bIndices: [Int], aIndices:[Int])] = []// bChunks, aChunks
        var offsetArray = [Int](repeating: 0, count: obDiffChunks.count)
        
        
        //do it by graph!!!
        //if number is larger than obCount than it's oa
        //
        var edges: Dictionary<Int,[Int]> = [:]
        
        for i in 0...oaDiffChunks.count+obDiffChunks.count {
            edges[i] = []
        }
        
        _ = obDiffChunks.enumerated().reduce(0) { index, diffChunk -> Int in
            let myRange = diffChunk.element.getARange()
            var currentAIndex = index
            
            while currentAIndex < oaDiffChunks.count && myRange.upperBound > oaDiffChunks[currentAIndex].getARange().lowerBound {
                
                if let _ = myRange.intersection(oaDiffChunks[currentAIndex].getARange()) {
                    
                    edges[diffChunk.offset]!.append(currentAIndex + obDiffChunks.count)
                    edges[currentAIndex + obDiffChunks.count]!.append(diffChunk.offset)
                    
                }
                
                currentAIndex += 1
            }
            
            //If add & add matches
            
            if currentAIndex < oaDiffChunks.count && myRange == oaDiffChunks[currentAIndex].getARange() {
                edges[diffChunk.offset]!.append(currentAIndex + obDiffChunks.count)
                edges[currentAIndex + obDiffChunks.count]!.append(diffChunk.offset)
            }
            
            return currentAIndex > 0 ? currentAIndex - 1 : currentAIndex
        }
        
        var visited = stride(from: 0, through: oaDiffChunks.count+obDiffChunks.count, by: 1).map{_ in return false}
        
        for i in 0..<obDiffChunks.count {
            if visited[i] {continue}
            
            //get conflicts
            var connectedBs: [Int] = []
            var connectedAs: [Int] = []
            
            
            var stack = Stack<Int>()
            stack.push(i)
            
            while !stack.isEmpty() {
                let currentPoint = stack.pop()!
                
                visited[currentPoint] = true
                
                if currentPoint >= obDiffChunks.count {
                    connectedAs.append(currentPoint - obDiffChunks.count)
                } else {
                    connectedBs.append(currentPoint)
                }
                
                if let myEdges = edges[currentPoint] {
                    myEdges.filter{!visited[$0]}.forEach {
                        stack.push($0)
                    }
                }
            }
            
            conflictArray.append((connectedBs.sorted(), connectedAs.sorted()))
        }
        
        
        _ = obDiffChunks.enumerated().reduce((0, 0)) { offsetTuple, diffblock -> (Int, Int) in
            var currentIndex = offsetTuple.0
            var currentOffset = offsetTuple.1
            
            let myRange = diffblock.element.getARange()
            
            while currentIndex < oaDiffChunks.count && oaDiffChunks[currentIndex].getARange().upperBound < myRange.lowerBound {
                
                switch oaDiffChunks[currentIndex] {
                case .add(_, let range) : currentOffset += range.length
                case .delete(let range, _) : currentOffset -= range.length
                case .change(let oldRange, let newRange) : currentOffset += newRange.length - oldRange.length
                default: break
                }
                
                currentIndex += 1
            }
            
            offsetArray[diffblock.offset] = currentOffset
            
            return (currentIndex, currentOffset)
        }
        
        
        for conflicts in conflictArray {
            
            let aBlock: DiffBlock
            let bBlock: DiffBlock
            
            if conflicts.aIndices.count == 0 {
                aBlock = .empty
            } else if conflicts.aIndices.count == 1 {
                aBlock = oaDiffChunks[conflicts.aIndices.first!]
            } else {
                let myFirstRange = oaDiffChunks[conflicts.aIndices.first!].getBRange()
                let myLastRange = oaDiffChunks[conflicts.aIndices.last!].getBRange()
                let oFirstRange = oaDiffChunks[conflicts.aIndices.first!].getARange()
                let oLastRange = oaDiffChunks[conflicts.aIndices.last!].getARange()
                
                aBlock = .change(oFirstRange.union(oLastRange), myFirstRange.union(myLastRange))
            }
            
            if conflicts.bIndices.count == 0 {
                bBlock = .empty
            } else if conflicts.bIndices.count == 1 {
                bBlock = obDiffChunks[conflicts.bIndices.first!]
            } else {
                let myFirstRange = obDiffChunks[conflicts.bIndices.first!].getBRange()
                let myLastRange = obDiffChunks[conflicts.bIndices.last!].getBRange()
                let oFirstRange = obDiffChunks[conflicts.bIndices.first!].getARange()
                let oLastRange = obDiffChunks[conflicts.bIndices.last!].getARange()
                
                bBlock = .change(oFirstRange.union(oLastRange), myFirstRange.union(myLastRange))
            }
            
            
            switch bBlock {
            case .add(let index, let bRange):
                let offset = offsetArray[conflicts.bIndices.first!]
                let start: Int
                switch aBlock {
                case .delete(_, let index): start = index
                case .change(_, let range) : start = range.location
                case .add(let oaIndex, let aRange):
                    if index == oaIndex {
                        let aSubString = aDiffMaker.bChunks[aRange.location..<aRange.upperBound].joined(separator: "\n")
                        let bSubString = bDiffMaker.bChunks[bRange.location..<bRange.upperBound].joined(separator: "\n")
                        
                        if aSubString.hashValue == bSubString.hashValue {
                            continue
                        }
                        
                    }
                    fallthrough
                default: start = index+offset
                }
                diff3Chunks.append(Diff3Block.add(start, bRange))
                
            case .delete(let oRange, _):
                let offset = offsetArray[conflicts.bIndices.first!]
                switch aBlock {
                case .add(let index, let aRange):
                    let firstRange = NSMakeRange(oRange.location+offset, index - oRange.location)
                    let secondRange = NSMakeRange(aRange.upperBound, oRange.length - firstRange.length)
                    if firstRange.length == 0 {
                        diff3Chunks.append(.delete(secondRange))
                    } else if secondRange.length == 0 {
                        diff3Chunks.append(.delete(firstRange))
                    } else {
                        diff3Chunks.append(.delete(firstRange))
                        diff3Chunks.append(.delete(secondRange))
                    }
                case .delete(let range, let aIndex):
                    if range == oRange {break}
                    let differences = oRange.difference(to: range)
                    
                    if differences.0 == nil && differences.1 == nil {break}
                    if differences.0 == nil {
                        diff3Chunks.append(.delete(NSMakeRange(aIndex, differences.1!.length)))
                    } else if differences.1 == nil {
                        diff3Chunks.append(.delete(NSMakeRange(aIndex - differences.0!.length, differences.0!.length)))
                    } else {
                        diff3Chunks.append(.delete(NSMakeRange(aIndex - differences.0!.length, differences.0!.length)))
                        diff3Chunks.append(.delete(NSMakeRange(aIndex, differences.1!.length)))
                    }
                case .change(let oaRange, let aaRange):
                    let differences = oRange.difference(to: oaRange)
                    
                    if differences.0 == nil && differences.1 == nil {break}
                    if differences.0 == nil {
                        diff3Chunks.append(.delete(NSMakeRange(aaRange.upperBound, differences.1!.length)))
                    } else if differences.1 == nil {
                        diff3Chunks.append(.delete(NSMakeRange(aaRange.location - differences.0!.length, differences.0!.length)))
                    } else {
                        diff3Chunks.append(.delete(NSMakeRange(aaRange.location - differences.0!.length, differences.0!.length)))
                        diff3Chunks.append(.delete(NSMakeRange(aaRange.upperBound, differences.1!.length)))
                    }
                case .empty:
                    diff3Chunks.append(.delete(NSMakeRange(oRange.location+offset, oRange.length)))
                    
                }
            case .change(let oRange, let bRange):
                let offset = offsetArray[conflicts.bIndices.first!]
                switch aBlock {
                case .add(let index, let aRange):
                    let firstRange = NSMakeRange(oRange.location, index - oRange.location)
                    let secondRange = NSMakeRange(index, oRange.length - firstRange.length)
                    diff3Chunks.append(.conflict(NSMakeRange(aRange.location - firstRange.length, aRange.length + firstRange.length + secondRange.length), bRange))
                case .delete(let oaRange, let index):
                    let differences = oRange.difference(to: oaRange)
                    
                    if differences.0 == nil && differences.1 == nil {
                        diff3Chunks.append(.add(index, bRange))
                    } else if differences.0 == nil {
                        diff3Chunks.append(.change(NSMakeRange(index, differences.1!.length), bRange))
                    } else if differences.1 == nil {
                        diff3Chunks.append(.change(NSMakeRange(index - differences.0!.length, differences.0!.length), bRange))
                    } else {
                        diff3Chunks.append(.change(NSMakeRange(index - differences.0!.length, differences.0!.length + differences.1!.length), bRange))
                    }
                case .change(let oaRange, let aaRange):
                    
                    let aSubString = aDiffMaker.bChunks[aaRange.location..<aaRange.upperBound].joined(separator: "\n")
                    let bSubString = bDiffMaker.bChunks[bRange.location..<bRange.upperBound].joined(separator: "\n")
                    
                    if aSubString.hashValue == bSubString.hashValue {
                        continue
                    }
                    
                    let differences = oRange.difference(to: oaRange)
                    
                    if differences.0 == nil && differences.1 == nil {
                        diff3Chunks.append(.conflict(aaRange, bRange))
                    } else if differences.0 == nil {
                        diff3Chunks.append(.conflict(NSMakeRange(aaRange.location, aaRange.length + differences.1!.length), bRange))
                    } else if differences.1 == nil {
                        diff3Chunks.append(.conflict(NSMakeRange(aaRange.location - differences.0!.length, aaRange.length + differences.0!.length), bRange))
                    } else {
                        diff3Chunks.append(.conflict(NSMakeRange(aaRange.location - differences.0!.length, aaRange.length + differences.0!.length + differences.1!.length), bRange))
                    }
                    
                case .empty:
                    diff3Chunks.append(.change(NSMakeRange(oRange.location+offset, oRange.length), bRange))
                }
                
            default: break
            }
        }
        
        let aLineRanges = aDiffMaker.bLineRanges
        let bLineRanges = bDiffMaker.bLineRanges
        
        return diff3Chunks.map {
            
            switch $0 {
            case .add(let index, let range):
                
                let indexFromLine = aLineRanges[index-1].upperBound
                let bLowerBound = bLineRanges[range.lowerBound].lowerBound
                let bUpperBound = bLineRanges[range.upperBound-1].upperBound
                
                
                return Diff3Block.add(indexFromLine, NSMakeRange(bLowerBound, bUpperBound - bLowerBound))
            case .delete(let range):
                let aLowerBound = aLineRanges[range.lowerBound].lowerBound
                let aUpperBound = aLineRanges[range.upperBound-1].upperBound
                
                return Diff3Block.delete(NSMakeRange(aLowerBound, aUpperBound - aLowerBound))
            case .change(let aRange, let bRange):
                let aLowerBound = aLineRanges[aRange.lowerBound].lowerBound
                let aUpperBound = aLineRanges[aRange.upperBound-1].upperBound
                
                let bLowerBound = bLineRanges[bRange.lowerBound].lowerBound
                let bUpperBound = bLineRanges[bRange.upperBound-1].upperBound
                
                return Diff3Block.change(NSMakeRange(aLowerBound, aUpperBound - aLowerBound), NSMakeRange(bLowerBound, bUpperBound - bLowerBound))
            case .conflict(let aRange, let bRange):
                let aLowerBound = aLineRanges[aRange.lowerBound].lowerBound
                let aUpperBound = aLineRanges[aRange.upperBound-1].upperBound
                
                let bLowerBound = bLineRanges[bRange.lowerBound].lowerBound
                let bUpperBound = bLineRanges[bRange.lowerBound-1].upperBound
                
                return Diff3Block.conflict(NSMakeRange(aLowerBound, aUpperBound - aLowerBound), NSMakeRange(bLowerBound, bUpperBound - bLowerBound))
            }
        }
    }
    
}

extension NSRange {


    func difference(to range: NSRange) -> (NSRange?, NSRange?) {
        if let intersection = self.intersection(range) {
            
            if intersection.location == self.location {
                return intersection.length == self.length ? (nil,nil): (nil,NSMakeRange(self.location + intersection.length, self.length - intersection.length))
            } else {
                let firstChunk = NSMakeRange(self.location, intersection.location - self.location)
                let secondChunk = NSMakeRange(intersection.upperBound, self.upperBound - intersection.upperBound)
                
                if secondChunk.length == 0 {
                    return (firstChunk, nil)
                } else {
                    return (firstChunk,secondChunk)
                }
            }
        }
        return (self, nil)
    }
}
