//
//  ViewController.swift
//  Palettes
//
//  Created by Amit Burstein on 11/26/14.
//  Copyright (c) 2014 Amit Burstein. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSWindowDelegate {

    // MARK: Constants
    
    let rowHeight: CGFloat = 110
    let colorViewCornerRadius: CGFloat = 5
    let copyViewPositionAnimSpringBounciness: CGFloat = 20
    let copyViewPositionAnimSpringSpeed: CGFloat = 15
    let palettesEndpoint = "http://www.colourlovers.com/api/palettes?format=json"
    let topPalettesEndpoint = "http://www.colourlovers.com/api/palettes/top?format=json"
    
    // MARK: Properties
    
    let manager = AFHTTPRequestOperationManager()
    var palettes = [Palette]()
    var showingTopPalettes = true
    var copyView = NSView(frame: CGRectMake(0, -40, 250, 40))
    var copyViewPositionAnim = POPSpringAnimation()
    var copyViewPositionReverseAnim = POPSpringAnimation()
    @IBOutlet weak var tableView: MainTableView!
    
    // MARK: Structs
    
    struct Palette {
        var url: String?
        var colors: [String]?
        var title: String?
    }
    
    // MARK: NSViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var window = NSApplication.sharedApplication().windows[0] as NSWindow
        window.delegate = self;
        setupCopyView()
        getPalettes(topPalettesEndpoint, params: nil)
    }
    
    // MARK: NSTableViewDataSource
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return palettes.count
    }
    
    // MARK: NSTableViewDelegate
    
    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return rowHeight
    }
    
    func tableView(tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: NSIndexSet) -> NSIndexSet {
        return NSIndexSet()
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellView = tableView.makeViewWithIdentifier("PaletteCell", owner: self) as PaletteTableCellView
        cellView.textField?.stringValue = palettes[row].title!
        cellView.colorView.wantsLayer = true
        cellView.colorView.layer?.cornerRadius = colorViewCornerRadius
        cellView.colors = palettes[row].colors!
        
        let width = ceil(cellView.colorView.bounds.width / CGFloat(palettes[row].colors!.count))
        let height = cellView.colorView.bounds.height
        cellView.colorView.subviews = []
        for var i = 0; i < palettes[row].colors!.count; i++ {
            let colorView = NSView(frame: CGRectMake(CGFloat(i) * width, 0, width, height))
            colorView.wantsLayer = true
            colorView.layer?.backgroundColor = NSColor(rgba: "#\(palettes[row].colors![i])").CGColor
            cellView.colorView.addSubview(colorView)
        }

        return cellView
    }
    
    // MARK: IBActions
    
    @IBAction func searchFieldChanged(searchField: NSSearchField!) {
        if searchField.stringValue == "" {
            if !showingTopPalettes {
                getPalettes(topPalettesEndpoint, params: nil)
                showingTopPalettes = true
            }
        } else {
            if let match = searchField.stringValue.rangeOfString("^[0-9a-fA-F]{6}$", options: .RegularExpressionSearch) {
                getPalettes(palettesEndpoint, params: ["hex": searchField.stringValue])
            } else {
                getPalettes(palettesEndpoint, params: ["keywords": searchField.stringValue])
            }
            showingTopPalettes = false
        }
    }
    
    // MARK: Functions
    
    func setupCopyView() {
        copyView.wantsLayer = true
        copyView.layer?.backgroundColor = NSColor(rgba: "#67809FE6").CGColor
        let copyViewTextField = NSTextField(frame: CGRectMake(0, 0, 250, 40))
        copyViewTextField.bezeled = false
        copyViewTextField.drawsBackground = false
        copyViewTextField.editable = false
        copyViewTextField.selectable = false
        copyViewTextField.alignment = .CenterTextAlignment
        copyViewTextField.textColor = NSColor(rgba: "#ECF0F1")
        copyViewTextField.font = NSFont.boldSystemFontOfSize(12)
        copyViewTextField.stringValue = "Copied!"
        copyView.addSubview(copyViewTextField)
        view.addSubview(copyView)
        
        copyViewPositionAnim.property = POPAnimatableProperty.propertyWithName(kPOPLayerPositionY) as POPAnimatableProperty
        copyViewPositionAnim.toValue = -20
        copyViewPositionAnim.springBounciness = copyViewPositionAnimSpringBounciness
        copyViewPositionAnim.springSpeed = copyViewPositionAnimSpringSpeed
        
        copyViewPositionReverseAnim.property = POPAnimatableProperty.propertyWithName(kPOPLayerPositionY) as POPAnimatableProperty
        copyViewPositionReverseAnim.toValue = -40
        copyViewPositionReverseAnim.springBounciness = copyViewPositionAnimSpringBounciness
        copyViewPositionReverseAnim.springSpeed = copyViewPositionAnimSpringSpeed

        copyViewPositionAnim.completionBlock = { _, _ in
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                self.copyView.layer!.pop_addAnimation(self.copyViewPositionReverseAnim, forKey: nil)
            })
        }
    }
    
    func getPalettes(endpoint: String, params: [String:String]?) {
        manager.GET(endpoint, parameters: params, success: { operation, responseObject in
            if let jsonArray = responseObject as? [NSDictionary] {
                self.palettes.removeAll()
                for paletteInfo in jsonArray {
                    let url = paletteInfo.objectForKey("url") as? String
                    let colors = paletteInfo.objectForKey("colors") as? [String]
                    let title = paletteInfo.objectForKey("title") as? String
                    self.palettes.append(Palette(url: url!, colors: colors!, title: title!))
                }
                dispatch_async(dispatch_get_main_queue(), {
                    self.tableView.reloadData()
                    self.tableView.scrollRowToVisible(0, animate: true)
                })
            } else {
                println("Could not load JSON...")
            }
        }) { _, _ in
            println("Could not load JSON...")
        }
    }

}
