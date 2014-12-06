//
//  AppDelegate.swift
//  Palettes
//
//  Created by Amit Burstein on 11/26/14.
//  Copyright (c) 2014 Amit Burstein. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: NSApplicationDelegate
    
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
    
}
