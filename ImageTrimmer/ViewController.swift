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
    private let x = Variable<Int>(0)
    @IBOutlet weak var xField: NSTextField!
    @IBOutlet weak var xStepper: NSStepper!
    private let y = Variable<Int>(0)
    @IBOutlet weak var yField: NSTextField!
    @IBOutlet weak var yStepper: NSStepper!
    
    // size
    private let width = Variable<Int>(30)
    @IBOutlet weak var widthField: NSTextField!
    private let height = Variable<Int>(30)
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
            .combineLatest(x.asObservable(),
                           y.asObservable(),
                           width.asObservable(),
                           height.asObservable())
            { _x, _y, _width, _height -> NSImage? in
                return self.cropImage(x: _x, y: _y, width: _width, height: _height)
            }
            .bindTo(previewImageView.rx.image)
            .addDisposableTo(disposeBag)

        Observable
            .combineLatest(x.asObservable(),
                           y.asObservable(),
                           width.asObservable(),
                           height.asObservable()){ ($0, $1, $2, $3) }
            .bindTo(imageView.clipRect)
            .addDisposableTo(disposeBag)
        
        // variable to control
        x.asObservable()
            .subscribe(onNext: { x in
                self.xField.integerValue = x
                self.xStepper.integerValue = x
            })
            .addDisposableTo(disposeBag)
        y.asObservable()
            .subscribe(onNext: { y in
                self.yField.integerValue = y
                self.yStepper.integerValue = y
            })
            .addDisposableTo(disposeBag)
        width.asObservable()
            .map { "\($0)" }
            .bindTo(widthField.rx.text)
            .addDisposableTo(disposeBag)
        height.asObservable()
            .map { "\($0)" }
            .bindTo(heightField.rx.text)
            .addDisposableTo(disposeBag)
        
        // control to variable
        xField.rx.text
            .flatMap { Int($0).map(Observable.just) ?? Observable.empty() }
            .bindTo(x)
            .addDisposableTo(disposeBag)
        yField.rx.text
            .flatMap { Int($0).map(Observable.just) ?? Observable.empty() }
            .bindTo(y)
            .addDisposableTo(disposeBag)
        widthField.rx.text
            .flatMap { Int($0).map(Observable.just) ?? Observable.empty() }
            .bindTo(width)
            .addDisposableTo(disposeBag)
        heightField.rx.text
            .flatMap { Int($0).map(Observable.just) ?? Observable.empty() }
            .bindTo(height)
            .addDisposableTo(disposeBag)
        xStepper.rx.controlEvent
            .map { self.xStepper.integerValue }
            .bindTo(x)
            .addDisposableTo(disposeBag)
        yStepper.rx.controlEvent
            .map { self.yStepper.integerValue }
            .bindTo(y)
            .addDisposableTo(disposeBag)
        
        imageView.onClickPixel.subscribe(onNext: { x, y in
            self.x.value = x
            self.y.value = y
        }).addDisposableTo(disposeBag)
    }
    
    func cropImage(x: Int, y: Int, width: Int, height: Int) -> NSImage? {
        guard let image = self.imageView.easyImage else {
            return nil
        }
        guard 0<x && x+width<=image.width && 0<y && y+height<=image.height else {
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
            showAlert("image is not loaded")
            return
        }
        let directory = positiveField.stringValue
        
        guard !directory.isEmpty else {
            showAlert("directory for positive images is not set")
            return
        }
        
        if saveImage(image: image, directory: directory, fileNumber: positiveFileNumber) {
            positiveFileNumber += 1
        }
    }
    
    @IBAction func onPressCropN(_ sender: AnyObject) {
        guard let image = previewImageView.image else {
            showAlert("image is not loaded")
            return
        }
        let directory = negativeField.stringValue
        
        guard !directory.isEmpty else {
            showAlert("directory for negative images is not set")
            return
        }
        
        if saveImage(image: image, directory: directory, fileNumber: negativeFileNumber) {
            negativeFileNumber += 1
        }
    }
    
    @IBAction func onPressRandomCropButton(_ sender: AnyObject) {
        
        guard let nsImage = imageView.image else {
            showAlert("image is not loaded")
            return
        }
        
        guard let image = Image<RGBA>(nsImage: nsImage) else {
            return
        }
        
        let width = widthField.integerValue
        let height = heightField.integerValue
        guard width > 0, height > 0 else {
            showAlert("invalid size: \(width), \(height)")
            return
        }
        
        let positiveDirectory = self.positiveField.stringValue
        let negativeDirectory = self.negativeField.stringValue
        guard !positiveDirectory.isEmpty && !negativeDirectory.isEmpty else {
            showAlert("invalid directories: \npositive: \(positiveDirectory) \nnegative: \(negativeDirectory)")
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
