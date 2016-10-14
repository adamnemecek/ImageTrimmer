//
//  Util.swift
//  ImageTrimmer
//
//  Created by Araki Takehiro on 2016/10/14.
//  Copyright © 2016年 Araki Takehiro. All rights reserved.
//

import Foundation
import Cocoa
import RxSwift

func saveImage(image: NSImage, directory: String, fileNumber: Int) -> Bool {
    let directoryUrl = URL(fileURLWithPath: directory, isDirectory: true)
    let url = URL(fileURLWithPath: "\(fileNumber).png", isDirectory: false, relativeTo: directoryUrl)
    
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
