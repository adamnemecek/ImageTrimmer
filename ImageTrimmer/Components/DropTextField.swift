//
//  DropTextField.swift
//  ImageTrimmer
//
//  Created by Araki Takehiro on 2016/10/14.
//  Copyright © 2016年 Araki Takehiro. All rights reserved.
//

import Foundation
import Cocoa

class DropTextField : NSTextField {
    
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
        
        self.stringValue = file
        
    }

}
