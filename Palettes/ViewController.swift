//
//  ViewController.swift
//  Palettes
//
//  Created by Amit Burstein on 11/26/14.
//  Copyright (c) 2014 Amit Burstein. All rights reserved.
//

import Cocoa

extension String {
    subscript(integerIndex: Int) -> Character {
        let index = advance(startIndex, integerIndex)
        return self[index]
    }
    
    subscript(integerRange: Range<Int>) -> String {
        let start = advance(startIndex, integerRange.startIndex)
        let end = advance(startIndex, integerRange.endIndex)
        let range = start..<end
        return self[range]
    }
}

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSWindowDelegate {

    // MARK: Constants
    
    let DefaultNumResults = 20
    let RowHeight = 110
    let PaletteViewCornerRadius = 5
    let CopiedViewAnimationSpringBounciness = 20
    let CopiedViewAnimationSpringSpeed = 15
    let CopiedViewReverseAnimationSpringBounciness = 10
    let CopiedViewReverseAnimationSpringSpeed = 15
    let CopiedViewAnimationToValue = -20
    let CopiedViewReverseAnimationToValue = -40
    let CopiedViewHeight = 40
    let CopiedViewBackgroundColor = "#67809FF5"
    let CopiedViewText = "Copied!"
    let CopiedViewTextSize = 12
    let CopiedViewTextColor = "#ECF0F1"
    let TableTextHeight = 40
    let TableTextSize = 16
    let TableTextColor = "#bdc3c7"
    let TableTextNoResults = "No Results Found"
    let TableTextError = "Error Loading Palettes :("
    let PaletteViewBorderColor = NSColor.gridColor().CGColor
    let PaletteViewBorderWidth = 0.2
    let PaletteCellIdentifier = "PaletteCell"
    let CopyTypeKey = "CopyType"
    let PalettesEndpoint = "http://www.colourlovers.com/api/palettes"
    let TopPalettesEndpoint = "http://www.colourlovers.com/api/palettes/top"
    
    // MARK: Properties
    
    var manager = AFHTTPRequestOperationManager()
    var preferences = NSUserDefaults.standardUserDefaults()
    var showingTopPalettes = true
    var scrolledToBottom = false
    var noResults = false
    var lastEndpoint = ""
    var lastParams = [String:String]()
    var resultsPage = 0
    var palettes = [Palette]()
    var copyType = 0
    var copiedView = NSView()
    var copiedViewAnimation = POPSpringAnimation()
    var copiedViewReverseAnimation = POPSpringAnimation()
    var fadeAnimation = POPBasicAnimation()
    var fadeReverseAnimation = POPBasicAnimation()
    var tableText = NSTextField()
    @IBOutlet weak var tableView: MainTableView!
    @IBOutlet weak var scrollView: NSScrollView!
    
    // MARK: Structs
    
    struct Palette {
        var url: String
        var colors: [String]
        var title: String
    }
    
    // MARK: NSViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let window = NSApplication.sharedApplication().windows[0] as NSWindow
        window.delegate = self
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "scrollViewDidScroll:", name: NSViewBoundsDidChangeNotification, object: scrollView.contentView)
        
        setupCopiedView()
        setupTableText()
        setupAnimations()
        getPalettes(endpoint: TopPalettesEndpoint, params: nil)
    }
    
    override func viewDidAppear() {
        if let lastCopyType = preferences.valueForKey(CopyTypeKey) as? Int {
            copyType = lastCopyType
            let window = NSApplication.sharedApplication().windows[0] as NSWindow
            window.delegate = self
            let popUpButton = window.toolbar?.items[1].view? as NSPopUpButton
            popUpButton.selectItemAtIndex(copyType)
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
        let openButton = cell.openButton
        let palette = palettes[row]
        
        // Set cell properties
        cell.textField?.stringValue = palette.title
        cell.colors = palette.colors
        cell.url = palette.url
        cell.addTrackingArea(NSTrackingArea(rect: NSZeroRect, options: .ActiveInActiveApp | .InVisibleRect | .MouseEnteredAndExited, owner: cell, userInfo: nil))
        
        // Set cell's open button properties
        cell.openButton.wantsLayer = true
        cell.openButton.layer?.opacity = 0
        
        // Set cell's palette view properties
        paletteView.wantsLayer = true
        paletteView.layer?.cornerRadius = CGFloat(PaletteViewCornerRadius)
        paletteView.layer?.borderColor = PaletteViewBorderColor
        paletteView.layer?.borderWidth = CGFloat(PaletteViewBorderWidth)
        paletteView.subviews = []
        paletteView.addTrackingArea(NSTrackingArea(rect: NSZeroRect, options: .ActiveAlways | .InVisibleRect | .CursorUpdate, owner: cell, userInfo: nil))
        
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
        resultsPage = 0
        if searchField.stringValue == "" {
            if !showingTopPalettes {
                getPalettes(endpoint: TopPalettesEndpoint, params: nil)
                showingTopPalettes = true
            }
        } else {
            if let match = searchField.stringValue.rangeOfString("^#?[0-9a-fA-F]{6}$", options: .RegularExpressionSearch) {
                var query = searchField.stringValue
                if query.hasPrefix("#") {
                    query = query[1...6]
                }
                getPalettes(endpoint: PalettesEndpoint, params: ["hex": query])
            } else {
                getPalettes(endpoint: PalettesEndpoint, params: ["keywords": searchField.stringValue])
            }
            showingTopPalettes = false
        }
    }
    
    @IBAction func copyTypeChanged(button: NSPopUpButton!) {
        copyType = button.indexOfSelectedItem
        preferences.setInteger(copyType, forKey: CopyTypeKey)
        preferences.synchronize()
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
    }
    
    func setupTableText() {
        // Set up table text
        tableText = NSTextField(frame: CGRectMake(0, view.bounds.height / 2 - CGFloat(TableTextHeight) / 4, view.bounds.width, CGFloat(TableTextHeight)))
        tableText.bezeled = false
        tableText.drawsBackground = false
        tableText.editable = false
        tableText.selectable = false
        tableText.alignment = .CenterTextAlignment
        tableText.textColor = NSColor(rgba: TableTextColor)
        tableText.font = NSFont.boldSystemFontOfSize(CGFloat(TableTextSize))
    }
    
    func setupAnimations() {
        // Set up copied view animation
        copiedViewAnimation.property = POPAnimatableProperty.propertyWithName(kPOPLayerPositionY) as POPAnimatableProperty
        copiedViewAnimation.toValue = CopiedViewAnimationToValue
        copiedViewAnimation.springBounciness = CGFloat(CopiedViewAnimationSpringBounciness)
        copiedViewAnimation.springSpeed = CGFloat(CopiedViewAnimationSpringSpeed)
        
        // Set up copied view reverse animation
        copiedViewReverseAnimation.property = POPAnimatableProperty.propertyWithName(kPOPLayerPositionY) as POPAnimatableProperty
        copiedViewReverseAnimation.toValue = CopiedViewReverseAnimationToValue
        copiedViewReverseAnimation.springBounciness = CGFloat(CopiedViewReverseAnimationSpringBounciness)
        copiedViewReverseAnimation.springSpeed = CGFloat(CopiedViewReverseAnimationSpringSpeed)
        
        // Set up fade animation
        fadeAnimation.property = POPAnimatableProperty.propertyWithName(kPOPLayerOpacity) as POPAnimatableProperty
        fadeAnimation.fromValue = 0
        fadeAnimation.toValue = 1
        
        // Set up fade reverse animation
        fadeReverseAnimation.property = POPAnimatableProperty.propertyWithName(kPOPLayerOpacity) as POPAnimatableProperty
        fadeReverseAnimation.fromValue = 1
        fadeReverseAnimation.toValue = 0
    }
    
    func getPalettes(#endpoint: String, params: [String:String]?) {
        // Add default keys to params
        var params = params
        if params == nil {
            params = [String:String]()
        }
        params?.updateValue("json", forKey: "format")
        params?.updateValue(String(DefaultNumResults), forKey: "numResults")
        
        // No request if endpoint ans params are unchanged
        if endpoint == lastEndpoint && params! == lastParams {
            return
        }
        
        // Make the request
        manager.GET(endpoint, parameters: params, success: { operation, responseObject in
            // Save the latest endpoint and params
            self.lastEndpoint = "\(operation.request.URL.scheme!)://\(operation.request.URL.host!)\(operation.request.URL.path!)"
            self.lastParams = params!
            
            // Parse the response object
            if let jsonArray = responseObject as? [NSDictionary] {
                // Remove all palettes if this is a new query
                if params?.indexForKey("resultOffset") == nil {
                    self.palettes.removeAll()
                }
                
                // Keep track of whether any results were returned
                // Show and hide table text accordingly
                self.noResults = jsonArray.count == 0
                if self.noResults {
                    if params?.indexForKey("resultOffset") == nil {
                        self.tableText.stringValue = self.TableTextNoResults
                        self.view.addSubview(self.tableText)
                        self.tableText.layer?.pop_addAnimation(self.fadeAnimation, forKey: nil)
                        dispatch_async(dispatch_get_main_queue(), {
                            self.tableView.reloadData()
                            self.tableView.layer?.pop_addAnimation(self.fadeReverseAnimation, forKey: nil)
                        })
                    }
                    return
                } else {
                    self.tableText.removeFromSuperview()
                    self.tableText.layer?.pop_addAnimation(self.fadeReverseAnimation, forKey: nil)
                }
                
                // Parse JSON for each palette and add to palettes array
                for paletteInfo in jsonArray {
                    let url = paletteInfo.objectForKey("url") as? String
                    let colors = paletteInfo.objectForKey("colors") as? [String]
                    let title = paletteInfo.objectForKey("title") as? String
                    self.palettes.append(Palette(url: url!, colors: colors!, title: title!))
                }
                
                // Reload table in main queue and scroll to top if this is a new query
                dispatch_async(dispatch_get_main_queue(), {
                    if params?.indexForKey("resultOffset") == nil {
                        self.tableView.scrollRowToVisible(0)
                        self.tableView.layer?.pop_addAnimation(self.fadeAnimation, forKey: nil)
                    } else {
                        self.scrolledToBottom = false
                    }
                    self.tableView.reloadData()
                })
            } else {
                self.palettes.removeAll()
                self.tableText.stringValue = self.TableTextError
                self.view.addSubview(self.tableText)
                self.tableText.layer?.pop_addAnimation(self.fadeAnimation, forKey: nil)
                dispatch_async(dispatch_get_main_queue(), {
                    self.tableView.reloadData()
                    self.tableView.layer?.pop_addAnimation(self.fadeReverseAnimation, forKey: nil)
                })
            }
        }) { _, _ in
            self.palettes.removeAll()
            self.tableText.stringValue = self.TableTextError
            self.view.addSubview(self.tableText)
            self.tableText.layer?.pop_addAnimation(self.fadeAnimation, forKey: nil)
            dispatch_async(dispatch_get_main_queue(), {
                self.tableView.reloadData()
                self.tableView.layer?.pop_addAnimation(self.fadeReverseAnimation, forKey: nil)
            })
        }
    }
    
    func scrollViewDidScroll(notification: NSNotification) {
        let currentPosition = CGRectGetMaxY(scrollView.contentView.visibleRect)
        let contentHeight = tableView.bounds.size.height - 5;

        if !noResults && !scrolledToBottom && currentPosition > contentHeight - 2 {
            scrolledToBottom = true
            resultsPage++
            var params = lastParams
            params.updateValue(String(DefaultNumResults * resultsPage), forKey: "resultOffset")
            getPalettes(endpoint: lastEndpoint, params: params)
        }
    }

}
