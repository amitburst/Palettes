//
//  PaletteTableCellView.swift
//  Palettes
//
//  Created by Amit Burstein on 11/26/14.
//  Copyright (c) 2014 Amit Burstein. All rights reserved.
//

import Cocoa

class PaletteTableCellView: NSTableCellView {
    
    // MARK: Constants
    
    let FadeAnimationDuration = 0.2
    
    // MARK: Properties
    
    var fadeAnimation = POPBasicAnimation()
    var fadeReverseAnimation = POPBasicAnimation()
    var colors = [String]()
    var url = ""
    @IBOutlet weak var paletteView: NSView!
    @IBOutlet weak var openButton: NSButton!
    
    // MARK: NSCoding
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        // Set up fade animation
        fadeAnimation.property = POPAnimatableProperty.propertyWithName(kPOPLayerOpacity) as POPAnimatableProperty
        fadeAnimation.fromValue = 0
        fadeAnimation.toValue = 1
        fadeAnimation.duration = FadeAnimationDuration
        
        // Set up fade reverse animation
        fadeReverseAnimation.property = POPAnimatableProperty.propertyWithName(kPOPLayerOpacity) as POPAnimatableProperty
        fadeReverseAnimation.fromValue = 1
        fadeReverseAnimation.toValue = 0
        fadeReverseAnimation.duration = FadeAnimationDuration
    }
    
    // MARK: NSResponder
    
    override func mouseDown(event: NSEvent) {
        // Get index of selected color
        let colorWidth = ceil(paletteView.bounds.width / CGFloat(paletteView.subviews.count))
        let colorStartX = paletteView.frame.origin.x
        let colorIndex = Int(floor((event.locationInWindow.x - colorStartX) / colorWidth))
        
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
    
    override func mouseEntered(theEvent: NSEvent) {
        openButton.layer?.pop_addAnimation(fadeAnimation, forKey: nil)
    }
    
    override func mouseExited(theEvent: NSEvent) {
        openButton.layer?.pop_addAnimation(fadeReverseAnimation, forKey: nil)
    }
    
    override func cursorUpdate(event: NSEvent) {
        if paletteView.convertPoint(event.locationInWindow, fromView: nil).y > 0 {
            NSCursor.pointingHandCursor().set()
        }
    }
    
    // MARK: IBActions
    
    @IBAction func clickedOpenButton(sender: NSButton) {
        NSWorkspace.sharedWorkspace().openURL(NSURL(string: url.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)!)
    }
    
}
