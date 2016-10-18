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
import RxSwift

class RandomCropViewController : CropViewController {
    
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
        let number = positiveFileNumber.value
        if saveImage(image: imageView.image!, directory: positiveDirectory, fileNumber: number) {
            positiveFileNumber.value += 1
            cropRandomly()
        }
    }
    
    @IBAction func onPressNeagtiveButton(_ sender: AnyObject) {
        let number = negativeFileNumber.value
        
        if saveImage(image: imageView.image!, directory: negativeDirectory, fileNumber: number) {
            negativeFileNumber.value += 1
            cropRandomly()
        }
    }
    
    @IBAction func onPressEndButton(_ sender: AnyObject) {
        NSApplication.shared().stopModal()
    }
    
}
