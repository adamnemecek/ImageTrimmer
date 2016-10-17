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
        
        let panRecog = NSPanGestureRecognizer(target: self, action: #selector(DropImageView.onPan))
        addGestureRecognizer(panRecog)
        
        let zoomRecog = NSMagnificationGestureRecognizer(target: self, action: #selector(DropImageView.onZoom))
        addGestureRecognizer(zoomRecog)
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
        
        self.image = NSImage(contentsOfFile: file)
        
        self.easyImage = Image(nsImage: self.image!)
        
        self.layer!.sublayerTransform = CATransform3DIdentity
        
        _onImageLoaded.onNext()
    }
    
    func onPan(_ recognizer: NSPanGestureRecognizer) {
        
        switch recognizer.state {
        case .began, .changed:
            let trans = recognizer.translation(in: self)
            self.layer!.sublayerTransform *= CATransform3DMakeTranslation(trans.x, trans.y, 0)
            
            Swift.print("pan: \(trans)")
            recognizer.setTranslation(NSPoint.zero, in: self)
            
        default:
            break
        }
    }
    
    func onZoom(_ recognizer: NSMagnificationGestureRecognizer) {
        let magnification = recognizer.magnification
        let scaleFactor = (magnification >= 0.0) ? (1.0 + magnification) : 1.0 / (1.0 - magnification)
        
        let location = recognizer.location(in: self)
        let move = CGPoint(x: location.x * (scaleFactor-1), y: location.y * (scaleFactor-1))

        self.layer!.sublayerTransform *= CATransform3DMakeScale(scaleFactor, scaleFactor, 1)
        self.layer!.sublayerTransform *= CATransform3DMakeTranslation(-move.x, -move.y, 0)
        Swift.print("zoom: \(scaleFactor) \(move)")
        
        recognizer.magnification = 0
    }
}
