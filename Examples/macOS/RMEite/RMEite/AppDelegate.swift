//
//  AppDelegate.swift
//  RMEite
//
//  Created by Felix on 02.11.21.
//

import Cocoa
import SwiftUI
import SwiftOSC

/// Expiration
let expirationDate = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2021, month: 12, day: 15))

/// create OSC server
let port = "9010" // TODO: use Int / UIInt16 !
var server = OSCServer(address: "", port: 9001)
let oscHandler = OSCHandler()

/// defaults
let settingsStore = SettingsStore.shared

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var overlay: OverlayWindow!
    var popover: NSPopover!
    var expiredAlert: ModalWindow?
    public var statusBarItem: NSStatusItem!
    
    var addressValue = OSCAddress()
    
    var windowTimer: Timer!
        
    func applicationWillFinishLaunching(_ notification: Notification) {
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        terminateDuplicateInstance()
        
        checkExpiration()
        
        //        print("UserDefaults.isEditMode", settingsStore.isEditMode) // debug
        
        let popoverView = PopoverView()
        
        overlay = OverlayWindow()
                
        /// create the popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: popoverView)
        self.popover = popover
        
        /// create the status bar item
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        if let button = self.statusBarItem.button {
            button.image = NSImage(named: "faderIcon22")
//            button.action = #selector(togglePopover(_:)) // old way without rightClick
            button.action = #selector(self.statusBarButtonClicked(_:))
            button.sendAction(on: [.leftMouseDown, .rightMouseUp]) // fun fact: .rightMouseDown results in "Left click"!
        }
        // Add Menu Item for NSMenu // exemplary, we don't do this, we go to the editMode action right away ...
//            menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        /// start OSC server
        server.start()
        server.delegate = oscHandler
        
        if server.running {
            print("🔹 \(server) started on port \(String(server.port)), address filter: \(server.address == "" ? "<none>" : server.address)")
        } else {
            print("OSC server is not running")
        }
        
        /// Bonjour server
        // TODO: useless, the Bonjour service is NOT connected to the OSCservice !!!
//        let bonjour = Bonjour.shared
//        bonjour.BonjourAdvertise(port: port)
//        bonjour.BonjourFinder()
        
        /// Bonjour client Setup / prime TotalMix to get values
        let tmc = TMClient() // "TotalMixClient"
        tmc.pushRefresh()
        tmc.setSubmixMain()
        
        // MARK: Window Control
        /// Window Control
        NotificationCenter.default.addObserver(self, selector: #selector(onDidOSCValueChange(notification:)), name: .didOSCValueChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDidButtonOverlayEdit(notification:)), name: .didButtonOverlayEdit, object: nil)
    }
    
    @objc func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        if event.type == NSEvent.EventType.rightMouseUp {
            //            print("Right Click")
            //            statusBarItem?.menu = menu  // next 3 lines, we don't do this, we go to the editMode action right away ...
            //            statusBarItem?.button?.performClick(nil)
            //            statusItem?.popUpMenu(menu)
            statusBarItem?.menu = nil
            if overlay.editMode {
                overlay.setToEditMode(false)
            } else {
                overlay.setToEditMode()
            }
            if windowTimer != nil { windowTimer.invalidate() }
        } else {
            //            print("Left Click")
            togglePopover(sender)
        }
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = self.statusBarItem.button {
            if self.popover.isShown {
                self.popover.performClose(sender)
            } else {
                self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                self.popover.contentViewController?.view.window?.becomeKey()
            }
        }
    }
    
    @objc func onDidOSCValueChange(notification: NSNotification!) {
//        print("editMode", self.overlay.editMode)
        if !self.overlay.editMode {
//            print("DEBUG: showing overlay window")
            overlay.makeKeyAndOrderFront(nil)
            
            if windowTimer != nil { windowTimer.invalidate() }
            windowTimer = Timer.scheduledTimer(withTimeInterval: settingsStore.overlayTimeout, repeats: false) { (_) in //  withTimeInterval was: 3
//                print("DEBUG: closing overlay window after timeout of \(String(format: "%.1f", settingsStore.overlayTimeout)) sec")
                self.overlay.close()
            }
        }
    }
    
    @objc func onDidButtonOverlayEdit(notification: NSNotification!) {
        if overlay.editMode == false {
            overlay.setToEditMode(true)
            if windowTimer != nil { windowTimer.invalidate() }
        } else {
            overlay.setToEditMode(false)
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        server.stop()
    }
    
}

