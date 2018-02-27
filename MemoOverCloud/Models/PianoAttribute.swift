//
//  PianoAttribute.swift
//  MemoOverCloud
//
//  Created by 김범수 on 2018. 2. 20..
//  Copyright © 2018년 piano. All rights reserved.
//

import Foundation
//TODO: make it Codable

struct PianoAttribute {
    let startIndex: Int
    let endIndex: Int
    
    let attribute: Style
    
}

enum Style {
    
    case backgroundColor(String)
    case foregroundColor(String)
    case strikethrough
    case underline
    case bold
    
    //
}
