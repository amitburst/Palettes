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
        // Get index of selected color
        let colorWidth = ceil(colorView.bounds.width / CGFloat(colorView.subviews.count))
        let colorStartX = colorView.frame.origin.x
        let colorIndex = Int(floor((theEvent.locationInWindow.x - colorStartX) / colorWidth))
        
        // Copy color to clipboard
        let pasteboard = NSPasteboard.generalPasteboard()
        pasteboard.clearContents()
        pasteboard.writeObjects([colors[colorIndex]])
        
        // Show copy view
        let viewController = nextResponder?.nextResponder?.nextResponder?.nextResponder?.nextResponder?.nextResponder! as ViewController
        viewController.copyView.layer?.pop_addAnimation(viewController.copyViewPositionAnim, forKey: nil)
    }
    
}
