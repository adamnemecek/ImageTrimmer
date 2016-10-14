//
//  ViewController.swift
//  ImageTrimmer
//
//  Created by Araki Takehiro on 2016/10/13.
//  Copyright © 2016年 Araki Takehiro. All rights reserved.
//

import Cocoa
import EasyImagy
import RxSwift
import RxCocoa

class ViewController: NSViewController {

    let disposeBag = DisposeBag()
    
    @IBOutlet weak var imageView: DropImageView!
    @IBOutlet weak var previewImageView: NSImageView!
    
    // position
    @IBOutlet weak var xField: NSTextField!
    @IBOutlet weak var xStepper: NSStepper!
    @IBOutlet weak var yField: NSTextField!
    @IBOutlet weak var yStepper: NSStepper!
    
    // size
    @IBOutlet weak var widthField: NSTextField!
    @IBOutlet weak var heightField: NSTextField!
    
    // directory
    @IBOutlet weak var positiveField: NSTextField!
    @IBOutlet weak var negativeField: NSTextField!
    
    // file No.
    @IBOutlet weak var positiveFileNameField: NSTextField!
    @IBOutlet weak var negativeFileNameField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.onImageLoaded
            .map { () -> NSImage? in
                return nil
            }
            .bindTo(previewImageView.rx.image)
            .addDisposableTo(disposeBag)
        
        Observable
            .combineLatest(xField.rx.text,
                           yField.rx.text,
                           widthField.rx.text,
                           heightField.rx.text)
            { _x, _y, _width, _height -> NSImage? in
                return self.cropImage(x: _x, y: _y, width: _width, height: _height)
            }
            .bindTo(previewImageView.rx.image)
            .addDisposableTo(disposeBag)
        
        xField.rx.text
            .flatMap { Int($0).map(Observable.just) ?? Observable.empty() }
            .subscribe(onNext: { i in
                self.xStepper.integerValue = i
            })
            .addDisposableTo(disposeBag)
        
        yField.rx.text
            .flatMap { Int($0).map(Observable.just) ?? Observable.empty() }
            .subscribe(onNext: { i in
                self.yStepper.integerValue = i
            })
            .addDisposableTo(disposeBag)
    }
    
    func cropImage(x: String, y: String, width: String, height: String) -> NSImage? {
        guard let x = Int(x),
            let y = Int(y),
            let width = Int(width),
            let height = Int(height) else {
                return nil
        }
        guard let image = self.imageView.easyImage else {
            return nil
        }
        let crop = Image(image[x..<x+width, y..<y+height])
        return crop.nsImage
    }

    @IBAction func onPressChangeP(_ sender: AnyObject) {
        chooseDirectory(forField: positiveField)
    }
    
    @IBAction func onPressChangeN(_ sender: AnyObject) {
        chooseDirectory(forField: negativeField)
    }
    
    func chooseDirectory(forField: NSTextField) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        
        panel.begin() { result in
            guard result == NSFileHandlingPanelOKButton else {
                return
            }
            
            if let path = panel.urls.first {
                forField.stringValue = path.path
            }
        }
    }
    
    @IBAction func onPressCropP(_ sender: AnyObject) {
        guard let image = previewImageView.image else {
            return
        }
        let directory = positiveField.stringValue
        
        guard !directory.isEmpty else {
            return
        }
        
        if saveImage(image: image, directory: directory, fileNumber: positiveFileNumber) {
            positiveFileNumber += 1
        }
    }
    
    @IBAction func onPressCropN(_ sender: AnyObject) {
        guard let image = previewImageView.image else {
            return
        }
        let directory = negativeField.stringValue
        
        guard !directory.isEmpty else {
            return
        }
        
        if saveImage(image: image, directory: directory, fileNumber: negativeFileNumber) {
            negativeFileNumber += 1
        }
    }
    
    @IBAction func onPressRandomCropButton(_ sender: AnyObject) {
        
        guard let nsImage = imageView.image else {
            Swift.print("image not loaded")
            return
        }
        
        guard let image = Image<RGBA>(nsImage: nsImage) else {
            return
        }
        
        let width = widthField.integerValue
        let height = heightField.integerValue
        guard width > 0, height > 0 else {
            Swift.print("invalid size: \(width), \(height)")
            return
        }
        
        let positiveDirectory = self.positiveField.stringValue
        let negativeDirectory = self.negativeField.stringValue
        guard !positiveDirectory.isEmpty && !negativeDirectory.isEmpty else {
            Swift.print("invalid: \npositive: \(positiveDirectory) \nnegative: \(negativeDirectory)")
            return
        }
        
        let w = storyboard!.instantiateController(withIdentifier: "RandomCrop") as! NSWindowController
        
        let vc = w.contentViewController! as! RandomCropViewController
        vc.delegate = self
        vc.image = image
        vc.width = width
        vc.height = height
        vc.positiveDirectory = positiveDirectory
        vc.negativeDirectory = negativeDirectory
        
        NSApplication.shared().runModal(for: w.window!)
        w.window!.orderOut(nil)
    }
    
    @IBAction func onStepX(_ sender: AnyObject) {
        xField.integerValue = xStepper.integerValue
        previewImageView.image =
            cropImage(x: xField.stringValue,
                      y: yField.stringValue,
                      width: widthField.stringValue,
                      height: heightField.stringValue)
        
    }
    
    @IBAction func onStepY(_ sender: AnyObject) {
        yField.integerValue = yStepper.integerValue
        previewImageView.image =
            cropImage(x: xField.stringValue,
                      y: yField.stringValue,
                      width: widthField.stringValue,
                      height: heightField.stringValue)
    }

}

extension ViewController : RandomCropViewControllerDelegate {
    var positiveFileNumber: Int {
        get {
            return self.positiveFileNameField.integerValue
        }
        set(value) {
            self.positiveFileNameField.integerValue = value
        }
    }
    
    var negativeFileNumber: Int {
        get {
            return self.negativeFileNameField.integerValue
        }
        set(value) {
            self.negativeFileNameField.integerValue = value
        }
    }
}
