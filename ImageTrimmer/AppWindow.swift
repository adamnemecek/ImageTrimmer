//
//  AppWindow.swift
//  ImageTrimmer
//
//  Created by Araki Takehiro on 2016/10/13.
//  Copyright © 2016年 Araki Takehiro. All rights reserved.
//

import Cocoa

class AppWindow : NSWindow, NSDraggingDestination {
    override func awakeFromNib() {
        Swift.print("window")
    }
}
