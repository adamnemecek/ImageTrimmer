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
        showAlert("failed to write: \(url) \n\(e.localizedDescription)")
        return false
    }
}

enum SelectDirectoryResult {
    case ok(URL?)
    case cancel
}
func selectDirectory(title: String? = nil) -> Observable<SelectDirectoryResult> {
    return Observable.create { observer in
        let panel = NSOpenPanel()
        panel.title = title
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        
        panel.begin() { result in
            
            switch result {
            case NSFileHandlingPanelOKButton:
                observer.onNext(.ok(panel.urls.first))
            case NSFileHandlingPanelCancelButton:
                observer.onNext(.cancel)
            default:
                fatalError("never reaches here.")
            }
            observer.onCompleted()
        }
        return Disposables.create {
            panel.close()
        }
    }
}

func showAlert(_ message: String) {
    let alert = NSAlert()
    alert.messageText = message
    alert.runModal()
}

func intToStr(_ i: Int) -> String {
    return "\(i)"
}

func strToObservableInt(_ str: String) -> Observable<Int> {
    return Int(str).map(Observable.just) ?? Observable.empty()
}


func * (lhs: CATransform3D, rhs: CATransform3D) -> CATransform3D {
    return CATransform3DConcat(lhs, rhs)
}

func *= (lhs: inout CATransform3D, rhs: CATransform3D) {
    lhs = lhs * rhs
}

func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
}

func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
}
