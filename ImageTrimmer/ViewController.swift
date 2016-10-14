//
//  ViewController.swift
//  ImageTrimmer
//
//  Created by Araki Takehiro on 2016/10/13.
//  Copyright © 2016年 Araki Takehiro. All rights reserved.
//

import Cocoa
import EasyImagy

class ViewController: NSViewController {

    @IBOutlet weak var imageView: NSImageView!
    
    @IBOutlet weak var widthField: NSTextField!
    @IBOutlet weak var heightField: NSTextField!
    
    @IBOutlet weak var positiveField: NSTextField!
    @IBOutlet weak var negativeField: NSTextField!
    
    @IBOutlet weak var positiveFileNameField: NSTextField!
    @IBOutlet weak var negativeFileNameField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
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
    
    @IBAction func onPressCropButton(_ sender: AnyObject) {
        cropAndShowAlert()
    }
    
    func cropAndShowAlert() {
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
