//
//  Diff.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 3. 9..
//  Copyright © 2018년 piano. All rights reserved.
//

import Foundation

enum DiffBlock: CustomStringConvertible {
    var description: String {
        switch self {
        case .empty : return "empty"
        case .add(let index, let range): return "add \(range) at \(index)"
        case .change(let aRange, let bRange): return "change \(aRange) with \(bRange)"
        case .delete(let range): return "delete \(range)"
        }
    }
    
    case empty // for diff3 merge
    case add(Int, NSRange)
    case change(NSRange, NSRange)
    case delete(NSRange, Int)

    func getARange() -> NSRange {
        switch self {
            case .add(let index, _): return NSMakeRange(index, 0)
            case .change(let range, _): return range
            case .delete(let range, _): return range
            default: return NSMakeRange(0, 0) // not called
        }
    }
    
    func getBRange() -> NSRange {
        switch self {
            case .add(_, let range): return range
            case .change(_, let range): return range
            case .delete(_, let index): return NSMakeRange(index, 0)
            default: return NSMakeRange(0, 0)
        }
    }
}

struct Pair {
    let x: Int
    let y: Int
    
    func isAdjacent(to pair: Pair) -> Bool {
        let absX = abs(x-pair.x)
        let absY = abs(y-pair.y)
        return absX + absY == 1
    }
}

extension Pair: Hashable {
    
    static func ==(lhs: Pair, rhs: Pair) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
    
    var hashValue: Int {
        return x.hashValue ^ y.hashValue &* 16777619
    }
    
    
}

class DiffMaker {
    
    let aChunks: [String]
    let bChunks: [String]
    private let separater = "\n"
    
    private var mapping: [Int: Int]
    private var v: [Int]
    private var path: [[Pair: Pair]] = []
    
    private var m: Int { return aChunks.count }
    private var n: Int { return bChunks.count }
    private var matchD = -1
    
    let aLineRanges: [NSRange]
    let bLineRanges: [NSRange]
    
    init(aString: String, bString: String) {
        self.aChunks = aString.components(separatedBy: separater)
        self.bChunks = bString.components(separatedBy: separater)
        
        var lowerBound = 0
        let aLastIndex = self.aChunks.count - 1
        
        self.aLineRanges = self.aChunks.enumerated().map{
            let length = $0.offset == aLastIndex ? $0.element.count : $0.element.count + 1
            let range = NSMakeRange(lowerBound, length)
            lowerBound += length
            
            return range
        }
        
        lowerBound = 0
        let bLastIndex = self.bChunks.count - 1
        
        self.bLineRanges = self.bChunks.enumerated().map {
            let length = $0.offset == bLastIndex ? $0.element.count : $0.element.count + 1
            let range = NSMakeRange(lowerBound, length)
            lowerBound += length
            
            return range
        }
        
        let max = aChunks.count+bChunks.count
        
        self.v = Array<Int>(repeating: 0, count: 2*(max)+1)
        
        self.mapping = stride(from: -(max), through: max, by: 1).enumerated().reduce([Int: Int]()) { (resultDic, enumerated) in
            var dict = resultDic
            dict[enumerated.element] = enumerated.offset
            return dict
        }
        
        path.append([:])
    }
    
    private func fillPath() {
        for d in 1...(m+n) {
            path.append([:])
            for k in stride(from: -d, through: d, by: 2) {
                
                let tk = mapping[k]!
                let prevK: Int
                let prevX: Int
                let prevY: Int
                
                var x: Int
                var y: Int
                if k == -d || k != d && v[tk-1] < v[tk+1] {
                    //vertical addition
                    x = v[tk+1]
                    y = x - k
                    prevK = k+1
                    prevX = x
                    prevY = prevX - prevK
                } else {
                    //horizontal deletion
                    x = v[tk-1] + 1
                    y = x - k
                    
                    prevK = k-1
                    prevX = x-1
                    prevY = prevX - prevK
                }
                
                while x-1 < m-1 && y-1 < n-1 && aChunks[x] == bChunks[y] {
                    x += 1
                    y += 1
                }
                
                path[d][Pair(x: x, y: y)] = Pair(x: prevX, y: prevY)
                v[tk] = x
                
                if x >= m && y >= n {
                    //break!!
                    
                    matchD = d
                    return
                }
            }
        }
    }
    
    private func getPath() -> [DiffBlock] {
        var currentPair = Pair(x: m, y: n)
        var edgePair = Pair(x: m, y: n)
        
        var paths: [DiffBlock] = []
        
        while matchD > 0 {
            guard let prevPath = path[matchD][currentPair] else {return []}
            
            if !currentPair.isAdjacent(to: prevPath) {
                
                let xOffset = edgePair.x - currentPair.x
                let yOffset = edgePair.y - currentPair.y
                
                if xOffset + yOffset > 0 {
                    if xOffset == 0 {
                        //add
                        paths.insert(.add(currentPair.x, NSMakeRange(currentPair.y, yOffset)), at: 0)
                    } else if yOffset == 0 {
                        //delete
                        paths.insert(.delete(NSMakeRange(currentPair.x, xOffset), currentPair.y), at: 0)
                    } else {
                        //change
                        paths.insert(.change(NSMakeRange(currentPair.x, xOffset), NSMakeRange(currentPair.y, yOffset)), at: 0)
                    }
                }
                
                edgePair = prevPath
                
                //get k
                //get hor or ver
                //insert path
                let currentK = currentPair.x - currentPair.y
                let previousK = prevPath.x - prevPath.y
                if currentK > previousK {
                    //horizontal
                    edgePair = Pair(x: prevPath.x + 1, y: prevPath.y)
                } else {
                    //vertical
                    edgePair = Pair(x: prevPath.x, y: prevPath.y + 1)
                }
            }
            
            currentPair = prevPath
            
            matchD -= 1
        }
        
        let xOffset = edgePair.x - 0
        let yOffset = edgePair.y - 0
        
        if xOffset + yOffset > 0 {
            if xOffset == 0 {
                //add
                paths.insert(.add(0, NSMakeRange(0, yOffset)), at: 0)
            } else if yOffset == 0 {
                //delete
                paths.insert(.delete(NSMakeRange(0, xOffset), 0), at: 0)
            }
        }
        
        return paths
    }
    
    
    func parseTwoStrings() -> [DiffBlock] {
        fillPath()
        
        //merge adjacent blocks
        return getPath()
    }
}
