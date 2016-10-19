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

class DropImageView : NSImageView {
    
    private let disposeBag = DisposeBag()
    
    private(set) var easyImage: Image<RGBA>?
    
    private var overlay: CALayer!
    private var sublayer: CALayer!
    
    private let _onImageLoaded = PublishSubject<Void>()
    var onImageLoaded: Observable<Void> {
        return _onImageLoaded
    }
    
    private let _onClickPixel = PublishSubject<(Int, Int)>()
    var onClickPixel: Observable<(Int, Int)> {
        return _onClickPixel
    }
    
    let clipRect = ReplaySubject<(Int, Int, Int, Int)>.create(bufferSize: 1)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        register(forDraggedTypes: [NSFilenamesPboardType])
        
        let panRecog = NSPanGestureRecognizer(target: self, action: #selector(onPan))
        addGestureRecognizer(panRecog)
        
        let zoomRecog = NSMagnificationGestureRecognizer(target: self, action: #selector(onZoom))
        addGestureRecognizer(zoomRecog)
        
        let clickRecog = NSClickGestureRecognizer(target: self, action: #selector(onClick))
        addGestureRecognizer(clickRecog)
        
        overlay = CALayer()
        overlay.borderWidth = 0.3
        overlay.borderColor = CGColor(red: 1, green: 0, blue: 0, alpha: 1)
        overlay.zPosition = 0.001
        overlay.bounds = CGRect(x: 0, y: 0, width: 0, height: 0)
        self.layer!.addSublayer(overlay)
        
        sublayer = CALayer()
        self.layer!.addSublayer(sublayer)
        
        weak var welf = self
        
        clipRect.subscribe(onNext: { x, y, width, height in
            welf?.drawRect(x: x, y: y, width: width, height: height)
        }).addDisposableTo(disposeBag)
        
        onImageLoaded.withLatestFrom(clipRect)
            .subscribe(onNext: { x, y, width, height in
                welf?.drawRect(x: x, y: y, width: width, height: height)
            })
            .addDisposableTo(disposeBag)
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return NSDragOperation.generic
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        
        let files = sender.draggingPasteboard().propertyList(forType: NSFilenamesPboardType) as! [String]
        
        guard let file = files.first else {
            return false
        }
        
        guard let image = NSImage(contentsOfFile: file) else {
            showAlert("invalid image file.")
            return false
        }
        self.image = image
        
        self.easyImage = Image(nsImage: image)
        
        self.layer!.sublayerTransform = CATransform3DIdentity
        
        _onImageLoaded.onNext()
        
        return true
    }
    
    override func scrollWheel(with event: NSEvent) {
        self.layer!.sublayerTransform *= CATransform3DMakeTranslation(event.deltaX, -event.deltaY, 0)
    }
    
    func onPan(_ recognizer: NSPanGestureRecognizer) {
        
        switch recognizer.state {
        case .began, .changed:
            guard let imageSize = self.image?.size else {
                return
            }
            let location = recognizer.location(in: self)
            let inSublayer = self.layer!.convert(location, to: self.sublayer)
            
            let imageAspectRatio = imageSize.width / imageSize.height
            let viewAspectRatio = self.bounds.width / self.bounds.height
            
            let imageOrigin: CGPoint
            let scale: CGFloat
            if imageAspectRatio < viewAspectRatio {
                scale = self.bounds.height / imageSize.height
                imageOrigin = CGPoint(x: (self.bounds.width - imageSize.width*scale)/2, y: 0)
            } else {
                scale = self.bounds.width / imageSize.width
                imageOrigin = CGPoint(x: 0, y: (self.bounds.height - imageSize.height*scale)/2)
            }
            
            let pt = (inSublayer - imageOrigin)/scale
            _onClickPixel.onNext((Int(pt.x), Int(imageSize.height - pt.y)))
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
        
        recognizer.magnification = 0
    }
    
    func onClick(_ recognizer: NSClickGestureRecognizer) {
        guard let imageSize = self.image?.size else {
            return
        }
        let location = recognizer.location(in: self)
        let inSublayer = self.layer!.convert(location, to: self.sublayer)
        
        let imageAspectRatio = imageSize.width / imageSize.height
        let viewAspectRatio = self.bounds.width / self.bounds.height
        
        let imageOrigin: CGPoint
        let scale: CGFloat
        if imageAspectRatio < viewAspectRatio {
            scale = self.bounds.height / imageSize.height
            imageOrigin = CGPoint(x: (self.bounds.width - imageSize.width*scale)/2, y: 0)
        } else {
            scale = self.bounds.width / imageSize.width
            imageOrigin = CGPoint(x: 0, y: (self.bounds.height - imageSize.height*scale)/2)
        }
        
        let pt = (inSublayer - imageOrigin)/scale
        _onClickPixel.onNext((Int(pt.x), Int(imageSize.height - pt.y)))
    }
    
    func drawRect(x: Int, y: Int, width: Int, height: Int) {
        
        guard let imageSize = self.image?.size else {
            return
        }
        
        guard width>0 && height>0 else {
            overlay.isHidden = true
            return
        }
        overlay.isHidden = false
        
        let y_ = imageSize.height - CGFloat(y)
        
        let imageAspectRatio = imageSize.width / imageSize.height
        let viewAspectRatio = self.bounds.width / self.bounds.height
        
        let imageOrigin: CGPoint
        let scale: CGFloat
        if imageAspectRatio < viewAspectRatio {
            scale = self.bounds.height / imageSize.height
            imageOrigin = CGPoint(x: (self.bounds.width - imageSize.width*scale)/2, y: 0)
        } else {
            scale = self.bounds.width / imageSize.width
            imageOrigin = CGPoint(x: 0, y: (self.bounds.height - imageSize.height*scale)/2)
        }
        
        let inSublayer = CGPoint(x: CGFloat(x), y: y_) * scale + imageOrigin
        
        let w = scale*CGFloat(width)
        let h = scale*CGFloat(height)
        overlay.bounds = CGRect(x: 0, y: 0, width: w, height: h)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        overlay.position = inSublayer + CGPoint(x: w/2, y: -h/2)
        CATransaction.commit()
    }
}
