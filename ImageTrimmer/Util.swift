
import Foundation
import Cocoa
import EasyImagy
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
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
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

extension Image where Pixel: RGBAType {
    init?(contentsOf url: URL) {
        self.init(contentsOfFile: url.path)
    }
    
    func toGrayImage() -> Image<Double> {
        return self.map { Double($0.gray) / 255.0 }
    }
}

func loadGrayImage(url: URL) -> Image<Double>? {
    return Image<RGBA>(contentsOf: url)?.toGrayImage()
}

extension NSImage {
    var bitmapRep: NSBitmapImageRep? {
        for rep in representations {
            guard let rep = rep as? NSBitmapImageRep else {
                continue
            }
            return rep
        }
        return nil
    }
}

extension Array {
    func partition(cvarRate: Float) -> (Array<Element>, Array<Element>) {
        let shuffled = self.shuffled()
        let cvarCount = Int(cvarRate * Float(shuffled.count))
        return (Array(shuffled[cvarCount..<self.count]),
                Array(shuffled[0..<cvarCount]))
    }
    
    func shuffled() -> Array<Element> {
        var array = self
        
        for i in 0..<array.count {
            let ub = UInt32(array.count - i)
            let d = Int(arc4random_uniform(ub))
            
            let tmp = array[i]
            array[i] = array[i+d]
            array[i+d] = tmp
        }
        
        return array
    }
    
    func zip<T,R>(with other: Array<T>, f: (Element, T)->R) -> Array<R> {
        return Swift.zip(self, other).map(f)
    }
}

func showAlert(_ message: String) {
    let alert = NSAlert()
    alert.messageText = message
    alert.runModal()
}

func linspace(minimum: Double, maximum: Double, count: Int) -> StrideTo<Double> {
    let strider = (maximum - minimum) / Double(count)
    return stride(from: minimum, to: maximum, by: strider)
}


// For observable conversion
func intToStr(_ i: Int) -> String {
    return "\(i)"
}

func strToObservableInt(_ str: String) -> Observable<Int> {
    return Int(str).map(Observable.just) ?? Observable.empty()
}

// CATransform3D
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
