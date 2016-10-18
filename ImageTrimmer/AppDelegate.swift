//
//  AppDelegate.swift
//  ImageTrimmer
//
//  Created by Araki Takehiro on 2016/10/13.
//  Copyright © 2016年 Araki Takehiro. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func onSelectAcknowledgements(_ sender: AnyObject) {
        let url = URL(string: "https://github.com/t-ae/ImageTrimmer/Acknowledgements.md")!
        NSWorkspace.shared().open(url)
    }
}

