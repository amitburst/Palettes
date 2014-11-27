//
//  PaletteTableCellView.swift
//  Palettes
//
//  Created by Amit Burstein on 11/26/14.
//  Copyright (c) 2014 Amit Burstein. All rights reserved.
//

import Cocoa

class PaletteTableCellView: NSTableCellView {
    
    // MARK: Properties
    
    var colors = [String]()
    @IBOutlet weak var colorView: NSView!
    
    // MARK: NSResponder
    
    override func mouseDown(theEvent: NSEvent) {
        let width = ceil(colorView.bounds.width / CGFloat(colorView.subviews.count))
        let startX = colorView.frame.origin.x
        let colorIndex = Int(floor((theEvent.locationInWindow.x - startX) / width))
        println(colors[colorIndex])
    }
    
}
