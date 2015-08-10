//
//  StringExtension.swift
//  Palettes
//
//  Created by Amit Burstein on 1/25/15.
//  Copyright (c) 2015 Amit Burstein. All rights reserved.
//

// Support range indexing for strings.
extension String {
    subscript(integerIndex: Int) -> Character {
        let index = advance(startIndex, integerIndex)
        return self[index]
    }
    
    subscript(integerRange: Range<Int>) -> String {
        let start = advance(startIndex, integerRange.startIndex)
        let end = advance(startIndex, integerRange.endIndex)
        let range = start..<end
        return self[range]
    }
}
