//
//  DropImageView.swift
//  ImageTrimmer
//
//  Created by Araki Takehiro on 2016/10/13.
//  Copyright © 2016年 Araki Takehiro. All rights reserved.
//

import Foundation
import Cocoa
import EasyImagy
import RxSwift

class DropImageView : NSImageView{
    
    private(set) var easyImage: Image<RGBA>?
    
    var onImageLoaded: Observable<Void> {
        return _onImageLoaded
    }
    
    private let _onImageLoaded = PublishSubject<Void>()
    
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
        
        self.easyImage = Image(nsImage: self.image!)
        
        _onImageLoaded.onNext()
    }
}
