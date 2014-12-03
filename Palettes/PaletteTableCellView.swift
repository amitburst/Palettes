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
    @IBOutlet weak var paletteView: NSView!
    
    // MARK: NSResponder
    
    override func mouseDown(theEvent: NSEvent) {
        // Get index of selected color
        let colorWidth = ceil(paletteView.bounds.width / CGFloat(paletteView.subviews.count))
        let colorStartX = paletteView.frame.origin.x
        let colorIndex = Int(floor((theEvent.locationInWindow.x - colorStartX) / colorWidth))
        
        // Copy color to clipboard
        let pasteboard = NSPasteboard.generalPasteboard()
        pasteboard.clearContents()
        pasteboard.writeObjects([colors[colorIndex]])
        
        // Show copy view
        let viewController = nextResponder?.nextResponder?.nextResponder?.nextResponder?.nextResponder?.nextResponder! as ViewController
        viewController.copiedView.layer?.pop_addAnimation(viewController.copiedViewAnimation, forKey: nil)

        // Hide copy view after 2 seconds
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
            viewController.copiedView.layer!.pop_addAnimation(viewController.copiedViewReverseAnimation, forKey: nil)
        })
    }
    
    override func cursorUpdate(event: NSEvent) {
        NSCursor.pointingHandCursor().set()
    }
    
}
