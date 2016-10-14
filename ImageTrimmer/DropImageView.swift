//
//  DropImageView.swift
//  ImageTrimmer
//
//  Created by Araki Takehiro on 2016/10/13.
//  Copyright © 2016年 Araki Takehiro. All rights reserved.
//

import Foundation
import Cocoa

class DropImageView : NSImageView{
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        register(forDraggedTypes: [NSFilenamesPboardType])
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return NSDragOperation.generic
    }
    
    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        
        guard let info = sender else {
            return
        }
        
        let files = info.draggingPasteboard().propertyList(forType: NSFilenamesPboardType) as! [String]
        
        guard let file = files.first else {
            return
        }
        
        Swift.print("load: \(file)")
        self.image = NSImage(contentsOfFile: file)
        
        
        
    }

}
