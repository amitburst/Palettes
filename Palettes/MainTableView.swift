//
//  MainTableView.swift
//  Palettes
//
//  Created by Amit Burstein on 11/29/14.
//  Copyright (c) 2014 Amit Burstein. All rights reserved.
//

import Cocoa

class MainTableView: NSTableView {
    
    // MARK: NSTableView
    
    override func drawGridInClipRect(clipRect: NSRect) {
        let lastRowRect = rectOfRow(numberOfRows - 1)
        let myClipRect = NSMakeRect(0, 0, lastRowRect.size.width, NSMaxY(lastRowRect))
        let finalClipRect = NSIntersectionRect(clipRect, myClipRect)
        super.drawGridInClipRect(finalClipRect)
    }
    
    // MARK: Functions
    
    func scrollRowToVisible(row: Int, animate: Bool) {
        if (animate) {
            let rowRect = rectOfRow(row)
            var scrollOrigin = rowRect.origin
            let clipView = superview as NSClipView
            scrollOrigin.y += max(0, round((rowRect.height - clipView.frame.height) * 0.5));
            let scrollView = clipView.superview as NSScrollView
            if scrollView.respondsToSelector("flashScrollers") {
                scrollView.flashScrollers()
            }
            clipView.animator().setBoundsOrigin(scrollOrigin)
        } else {
            scrollRowToVisible(row)
        }
    }
    
}