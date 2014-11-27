//
//  ViewController.swift
//  Palettes
//
//  Created by Amit Burstein on 11/26/14.
//  Copyright (c) 2014 Amit Burstein. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    // MARK: Properties
    
    let manager = AFHTTPRequestOperationManager()
    var palettes = Array<Palette>()
    @IBOutlet weak var tableView: NSTableView!
    let topPalettesEndpoint = "http://www.colourlovers.com/api/palettes/top?format=json"
    
    // MARK: Structs
    
    struct Palette {
        var url: String?
        var colors: [String]?
        var title: String?
    }
    
    // MARK: NSViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getTopPalettes()
    }
    
    // MARK: NSTableViewDataSource
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return palettes.count
    }
    
    // MARK: NSTableViewDelegate
    
    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 110
    }
    
    func tableView(tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: NSIndexSet) -> NSIndexSet {
        return NSIndexSet()
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let result = tableView.makeViewWithIdentifier("PaletteCell", owner: self) as PaletteTableCellView
        result.textField?.stringValue = palettes[row].title!
        result.colorView.wantsLayer = true
        result.colorView.layer?.cornerRadius = 5
        
        let width = ceil(result.colorView.bounds.width / CGFloat(palettes[row].colors!.count))
        let height = result.colorView.bounds.height
        for var i = 0; i < palettes[row].colors!.count; i++ {
            let view = NSView(frame: CGRectMake(CGFloat(i) * width, 0, width, height))
            view.wantsLayer = true
            view.layer?.backgroundColor = NSColor(rgba: "#\(palettes[row].colors![i])").CGColor
            result.colorView.addSubview(view)
        }

        return result
    }
    
    // MARK: Functions
    
    func getTopPalettes() {
        manager.GET(topPalettesEndpoint, parameters: nil, success: { _, responseObject in
            // Should get a JSON array back
            if let jsonArray = responseObject as? Array<NSDictionary> {
                for paletteInfo in jsonArray {
                    // Extract fields from JSON object
                    let url = paletteInfo.objectForKey("url") as? String
                    let colors = paletteInfo.objectForKey("colors") as? Array<String>
                    let title = paletteInfo.objectForKey("title") as? String
                    
                    // Don't add to palettes array if any fields are nil
                    if url == nil || colors == nil || title == nil {
                        continue
                    }
                    
                    // Add to palettes array
                    self.palettes.append(Palette(url: url!, colors: colors!, title: title!))
                }
                
                // Reload tableview on main queue
                dispatch_async(dispatch_get_main_queue(), {
                    self.tableView.reloadData()
                })
            } else {
                println("Could not load JSON...")
            }
        }) { _, _ in
            println("Could not load JSON...")
        }
    }

}
