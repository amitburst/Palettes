//
//  ViewController.swift
//  Palettes
//
//  Created by Amit Burstein on 11/26/14.
//  Copyright (c) 2014 Amit Burstein. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    // MARK: Properties
    
    let manager = AFHTTPRequestOperationManager()
    var palettes = Array<Palette>()
    let topPalettesEndpoint = "http://www.colourlovers.com/api/palettes/top?format=json"
    
    // MARK: Structs
    
    struct Palette {
        var url: String?
        var colors: Array<String>?
        var title: String?
    }
    
    // MARK: NSViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getTopPalettes()
    }
    
    // MARK: Functions
    
    func getTopPalettes() {
        manager.GET(topPalettesEndpoint, parameters: nil, success: { _, responseObject in
            // Should get a JSON array back
            if let jsonArray = responseObject as? Array<NSDictionary> {
                for paletteInfo in jsonArray {
                    // Extract fields from JSON object
                    let url = paletteInfo.objectForKey("urll") as? String
                    let colors = paletteInfo.objectForKey("colors") as? Array<String>
                    let title = paletteInfo.objectForKey("title") as? String
                    
                    // Don't add to palettes array if any fields are nil
                    if url == nil || colors == nil || title == nil {
                        continue
                    }
                    
                    // Add to palettes array
                    self.palettes.append(Palette(url: url!, colors: colors!, title: title!))
                }
            } else {
                println("Could not load JSON...")
            }
        }) { _, error in
            println(error.localizedDescription)
        }
    }

}
