//
//  RandomCropWindow.swift
//  ImageTrimmer
//
//  Created by Araki Takehiro on 2016/10/14.
//  Copyright © 2016年 Araki Takehiro. All rights reserved.
//

import Foundation
import Cocoa
import EasyImagy

class RandomCropViewController : NSViewController {
    
    var image: Image<RGBA>!
    var width: Int!
    var height: Int!
    var positiveDirectory: String!
    var negativeDirectory: String!
    
    var delegate: RandomCropViewControllerDelegate!
    
    @IBOutlet weak var imageView: NSImageView!
    
    override func viewDidAppear() {
        super.viewDidAppear()
        cropRandomly()
    }
    
    func cropRandomly() {
        
        let maxX = UInt32(image.width) - UInt32(width)
        let x = Int(arc4random_uniform(maxX))
        
        let maxY = UInt32(image.height) - UInt32(height)
        let y = Int(arc4random_uniform(maxY))
        
        let cropped = Image(image[x..<x+width, y..<y+height])
        
        imageView.image = cropped.nsImage
    }
    
    @IBAction func onPressPosiiveButton(_ sender: AnyObject) {
        let number = delegate.positiveFileNumber
        if save(directory: positiveDirectory, fileNumber: number) {
            delegate.positiveFileNumber += 1
            cropRandomly()
        }
    }
    
    @IBAction func onPressNeagtiveButton(_ sender: AnyObject) {
        let number = delegate.positiveFileNumber
        
        if save(directory: positiveDirectory, fileNumber: number) {
            delegate.negativeFileNumber += 1
            cropRandomly()
        }
    }
    
    @IBAction func onPressEndButton(_ sender: AnyObject) {
        NSApplication.shared().stopModal()
    }
    
    
    func save(directory: String, fileNumber: Int) -> Bool {
        let directoryUrl = URL(fileURLWithPath: directory, isDirectory: true)
        let url = URL(fileURLWithPath: "\(fileNumber).png", isDirectory: false, relativeTo: directoryUrl)
        
        let image = imageView.image!
        
        let data = image.tiffRepresentation!
        let b = NSBitmapImageRep.imageReps(with: data).first! as! NSBitmapImageRep
        let pngData = b.representation(using: NSPNGFileType, properties: [:])!
        
        do {
            try pngData.write(to: url, options: Data.WritingOptions.atomic)
            Swift.print("save: \(url)")
            return true
        } catch(let e) {
            Swift.print("failed to write: \(url) \n\(e.localizedDescription)")
            return false
        }
    }
    
}

protocol RandomCropViewControllerDelegate {
    var positiveFileNumber: Int { get set }
    var negativeFileNumber: Int { get set }
}
