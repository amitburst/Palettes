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
    
    let RowHeight = 110
    let PaletteViewCornerRadius = 5
    let CopiedViewAnimationSpringBounciness = 20
    let CopiedViewAnimationSpringSpeed = 15
    let CopiedViewAnimationToValue = -20
    let CopiedViewReverseAnimationToValue = -40
    let CopiedViewHeight = 40
    let CopiedViewBackgroundColor = "#67809FE6"
    let CopiedViewText = "Copied!"
    let CopiedViewTextSize = 12
    let CopiedViewTextColor = "#ECF0F1"
    let PaletteCellIdentifier = "PaletteCell"
    let PalettesEndpoint = "http://www.colourlovers.com/api/palettes?format=json"
    let TopPalettesEndpoint = "http://www.colourlovers.com/api/palettes/top?format=json"
    
    // MARK: Properties
    
    var manager = AFHTTPRequestOperationManager()
    var palettes = [Palette]()
    var showingTopPalettes = true
    var copiedView = NSView()
    var copiedViewAnimation = POPSpringAnimation()
    var copiedViewReverseAnimation = POPSpringAnimation()
    @IBOutlet weak var tableView: MainTableView!
    
    // MARK: Structs
    
    struct Palette {
        var url: String
        var colors: [String]
        var title: String
    }
    
    // MARK: NSViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var window = NSApplication.sharedApplication().windows[0] as NSWindow
        window.delegate = self
        setupCopiedView()
        getPalettes(endpoint: TopPalettesEndpoint, params: nil)
    }
    
    // MARK: NSTableViewDataSource
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return palettes.count
    }
    
    // MARK: NSTableViewDelegate
    
    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return CGFloat(RowHeight)
    }
    
    func tableView(tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: NSIndexSet) -> NSIndexSet {
        return NSIndexSet()
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        // Create and get references to other important items
        let cell = tableView.makeViewWithIdentifier(PaletteCellIdentifier, owner: self) as PaletteTableCellView
        let paletteView = cell.paletteView
        let palette = palettes[row]
        
        // Set cell properties
        cell.textField?.stringValue = palette.title
        cell.colors = palette.colors
        
        // Set cell's palette view properties
        paletteView.wantsLayer = true
        paletteView.layer?.cornerRadius = CGFloat(PaletteViewCornerRadius)
        paletteView.subviews = []
        
        // Calculate width and height of each color view
        let colorViewWidth = ceil(paletteView.bounds.width / CGFloat(cell.colors.count))
        let colorViewHeight = paletteView.bounds.height
        
        // Create and append color views to palette view
        for i in 0..<cell.colors.count {
            let colorView = NSView(frame: CGRectMake(CGFloat(i) * colorViewWidth, 0, colorViewWidth, colorViewHeight))
            colorView.wantsLayer = true
            colorView.layer?.backgroundColor = NSColor(rgba: "#\(cell.colors[i])").CGColor
            paletteView.addSubview(colorView)
        }

        return cell
    }
    
    // MARK: IBActions
    
    @IBAction func searchFieldChanged(searchField: NSSearchField!) {
        if searchField.stringValue == "" {
            if !showingTopPalettes {
                getPalettes(endpoint: TopPalettesEndpoint, params: nil)
                showingTopPalettes = true
            }
        } else {
            if let match = searchField.stringValue.rangeOfString("^[0-9a-fA-F]{6}$", options: .RegularExpressionSearch) {
                getPalettes(endpoint: PalettesEndpoint, params: ["hex": searchField.stringValue])
            } else {
                getPalettes(endpoint: PalettesEndpoint, params: ["keywords": searchField.stringValue])
            }
            showingTopPalettes = false
        }
    }
    
    // MARK: Functions
    
    func setupCopiedView() {
        // Set up copied view text
        let copiedViewTextField = NSTextField(frame: CGRectMake(0, 0, view.bounds.width, CGFloat(CopiedViewHeight)))
        copiedViewTextField.bezeled = false
        copiedViewTextField.drawsBackground = false
        copiedViewTextField.editable = false
        copiedViewTextField.selectable = false
        copiedViewTextField.alignment = .CenterTextAlignment
        copiedViewTextField.textColor = NSColor(rgba: CopiedViewTextColor)
        copiedViewTextField.font = NSFont.boldSystemFontOfSize(CGFloat(CopiedViewTextSize))
        copiedViewTextField.stringValue = CopiedViewText
        
        // Set up copied view
        copiedView = NSView(frame: CGRectMake(0, CGFloat(-CopiedViewHeight), view.bounds.width, CGFloat(CopiedViewHeight)))
        copiedView.addSubview(copiedViewTextField)
        copiedView.wantsLayer = true
        copiedView.layer?.backgroundColor = NSColor(rgba: CopiedViewBackgroundColor).CGColor
        view.addSubview(copiedView)
        
        // Set up copied view animation
        copiedViewAnimation.property = POPAnimatableProperty.propertyWithName(kPOPLayerPositionY) as POPAnimatableProperty
        copiedViewAnimation.toValue = CopiedViewAnimationToValue
        copiedViewAnimation.springBounciness = CGFloat(CopiedViewAnimationSpringBounciness)
        copiedViewAnimation.springSpeed = CGFloat(CopiedViewAnimationSpringSpeed)
        
        // Set up copied view reverse animation
        copiedViewReverseAnimation.property = POPAnimatableProperty.propertyWithName(kPOPLayerPositionY) as POPAnimatableProperty
        copiedViewReverseAnimation.toValue = CopiedViewReverseAnimationToValue
        copiedViewReverseAnimation.springBounciness = CGFloat(CopiedViewAnimationSpringBounciness)
        copiedViewReverseAnimation.springSpeed = CGFloat(CopiedViewAnimationSpringSpeed)
    }
    
    func getPalettes(#endpoint: String, params: [String:String]?) {
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
