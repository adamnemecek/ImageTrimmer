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

class MainViewController: NSViewController {

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
    private let positiveFileNumber = Variable<Int>(0)
    @IBOutlet weak var positiveFileNameField: NSTextField!
    private let negativeFileNumber = Variable<Int>(0)
    @IBOutlet weak var negativeFileNameField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        weak var welf = self
        
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
                return welf?.cropImage(x: _x, y: _y, width: _width, height: _height)
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
                welf?.xField.integerValue = x
                welf?.xStepper.integerValue = x
            })
            .addDisposableTo(disposeBag)
        y.asObservable()
            .subscribe(onNext: { y in
                welf?.yField.integerValue = y
                welf?.yStepper.integerValue = y
            })
            .addDisposableTo(disposeBag)
        width.asObservable()
            .map(intToStr)
            .bindTo(widthField.rx.text)
            .addDisposableTo(disposeBag)
        height.asObservable()
            .map(intToStr)
            .bindTo(heightField.rx.text)
            .addDisposableTo(disposeBag)
        positiveFileNumber.asObservable()
            .map(intToStr)
            .bindTo(positiveFileNameField.rx.text)
            .addDisposableTo(disposeBag)
        negativeFileNumber.asObservable()
            .map(intToStr)
            .bindTo(negativeFileNameField.rx.text)
            .addDisposableTo(disposeBag)
        
        // control to variable
        xField.rx.text
            .flatMap(strToObservableInt)
            .bindTo(x)
            .addDisposableTo(disposeBag)
        yField.rx.text
            .flatMap(strToObservableInt)
            .bindTo(y)
            .addDisposableTo(disposeBag)
        xStepper.rx.controlEvent
            .map { welf!.xStepper.integerValue }
            .bindTo(x)
            .addDisposableTo(disposeBag)
        yStepper.rx.controlEvent
            .map { welf!.yStepper.integerValue }
            .bindTo(y)
            .addDisposableTo(disposeBag)
        widthField.rx.text
            .flatMap(strToObservableInt)
            .bindTo(width)
            .addDisposableTo(disposeBag)
        heightField.rx.text
            .flatMap(strToObservableInt)
            .bindTo(height)
            .addDisposableTo(disposeBag)
        positiveFileNameField.rx.text
            .flatMap(strToObservableInt)
            .bindTo(positiveFileNumber)
            .addDisposableTo(disposeBag)
        negativeFileNameField.rx.text
            .flatMap(strToObservableInt)
            .bindTo(negativeFileNumber)
            .addDisposableTo(disposeBag)
        
        imageView.onClickPixel
            .do(onNext: { _ in
                welf?.view.window?.makeFirstResponder(nil)
            })
            .subscribe(onNext: { x, y in
                welf?.x.value = x
                welf?.y.value = y
            })
            .addDisposableTo(disposeBag)
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
        chooseDirectory(for: positiveField)
    }
    
    @IBAction func onPressChangeN(_ sender: AnyObject) {
        chooseDirectory(for: negativeField)
    }
    
    func chooseDirectory(for field: NSTextField) {
        
        selectDirectory()
            .subscribe(onNext: { result in
                switch result {
                case .ok(let url):
                    if let path = url?.path {
                        field.stringValue = path
                    }
                case .cancel:
                    return
                }
            })
            .addDisposableTo(disposeBag)
        
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
        
        if saveImage(image: image, directory: directory, fileNumber: positiveFileNumber.value) {
            positiveFileNumber.value += 1
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
        
        if saveImage(image: image, directory: directory, fileNumber: negativeFileNumber.value) {
            negativeFileNumber.value += 1
        }
    }
    
    @IBAction func onPressPredButton(_ sender: AnyObject) {
        guard let nsImage = imageView.image else {
            showAlert("image is not loaded")
            return
        }
        
        guard let image = Image<RGBA>(nsImage: nsImage) else {
            return
        }
        
        let width = self.width.value
        let height = self.height.value
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
        
        func select(title: String) -> Observable<URL> {
            return selectDirectory(title: title)
                .map{ result in
                    switch result {
                    case .ok(let _url):
                        if let url = _url {
                            return url
                        } else {
                            throw SelectDirectoryAbortedError()
                        }
                    default:
                        throw SelectDirectoryAbortedError()
                    }
                }
        }
        
        select(title: "Select directory which contains \"Positive\" images.")
            .concat(select(title: "Select directory which contains \"Negative\" images."))
            .toArray()
            .subscribe { [weak self] event in
                switch event {
                case .next(let urls):
                    let w = self!.storyboard!.instantiateController(withIdentifier: "PredictiveCrop") as! NSWindowController
                    let vc = w.contentViewController! as! PredictiveCropViewController
                    vc.positiveSupervisorDirectory.onNext(urls[0].path)
                    vc.negativeSupervisorDirectory.onNext(urls[1].path)
                    vc.x = self!.x
                    vc.y = self!.y
                    vc.positiveFileNumber = self!.positiveFileNumber
                    vc.negativeFileNumber = self!.negativeFileNumber
                    vc.image = image
                    vc.width = width
                    vc.height = height
                    vc.positiveDirectory = positiveDirectory
                    vc.negativeDirectory = negativeDirectory
                    vc.bind()
                    
                    NSApplication.shared().runModal(for: w.window!)
                    w.window?.orderOut(nil)
                    
                case .error(let e):
                    Swift.print("error: \(e)")
                case .completed:
                    break
                }
            }
            .addDisposableTo(disposeBag)
    }
    
    @IBAction func onPressRandomCropButton(_ sender: AnyObject) {
        
        guard let nsImage = imageView.image else {
            showAlert("image is not loaded")
            return
        }
        
        guard let image = Image<RGBA>(nsImage: nsImage) else {
            return
        }
        
        let width = self.width.value
        let height = self.height.value
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
        vc.positiveFileNumber = self.positiveFileNumber
        vc.negativeFileNumber = self.negativeFileNumber
        vc.image = image
        vc.width = width
        vc.height = height
        vc.positiveDirectory = positiveDirectory
        vc.negativeDirectory = negativeDirectory
        
        NSApplication.shared().runModal(for: w.window!)
        w.window?.orderOut(nil)
    }
    
    
}

struct SelectDirectoryAbortedError: Error {
    
}
