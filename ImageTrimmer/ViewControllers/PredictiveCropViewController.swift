//
//  PredictiveCropViewController.swift
//  ImageTrimmer
//
//  Created by Araki Takehiro on 2016/10/18.
//  Copyright © 2016年 Araki Takehiro. All rights reserved.
//

import Foundation
import Cocoa
import RxSwift
import RxCocoa
import EasyImagy

class PredictiveCropViewController : CropViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var imageView: NSImageView!
    
    @IBOutlet weak var xField: NSTextField!
    @IBOutlet weak var yField: NSTextField!
    @IBOutlet weak var strideField: NSTextField!
    
    var positiveSupervisorDirectory = ReplaySubject<String>.create(bufferSize: 1)
    var negativeSupervisorDirectory = ReplaySubject<String>.create(bufferSize: 1)
    var x: Variable<Int>!
    var y: Variable<Int>!
    
    // Model
    private var mu: [Double]!
    private var sigma2: [Double]!
    private var epsilon: Double!
    
    lazy var blockView: BlockView = {
        var array = NSArray()
        Bundle.main.loadNibNamed("BlockView", owner: nil, topLevelObjects: &array)
        let v = array.filter{ $0 is BlockView }.first as! BlockView
        self.view.addSubview(v)
        v.bounds = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
        return v
    }()
    
    override func viewDidDisappear() {
        NSApplication.shared().stopModal()
    }
    
    func bind() {
        
        weak var welf = self
        
        Observable.combineLatest(positiveSupervisorDirectory,
                                 negativeSupervisorDirectory) { ($0, $1) }
            .subscribe(onNext: {
                Swift.print($0)
                welf!.createModel(positiveDirectory: $0.0, negativeDirectory: $0.1)
            })
            .addDisposableTo(disposeBag)
        
        x.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { x in
                welf?.xField.integerValue = x
            })
            .addDisposableTo(disposeBag)
        y.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { y in
                welf?.yField.integerValue = y
            })
            .addDisposableTo(disposeBag)
        
        xField.rx.text
            .flatMap(strToObservableInt)
            .bindTo(x)
            .addDisposableTo(disposeBag)
        yField.rx.text
            .flatMap(strToObservableInt)
            .bindTo(y)
            .addDisposableTo(disposeBag)
    }
    
    func createModel(positiveDirectory: String, negativeDirectory: String) {
        blockView.show(with: "Creating model.")
        DispatchQueue.global().async {
            
            do {
                let fm = FileManager.default
                let positives = try fm.contentsOfDirectory(atPath: positiveDirectory)
                let negatives = try fm.contentsOfDirectory(atPath: negativeDirectory)
                
                let (pEstimate, pVar) = positives.partition(cvarRate: 0.1)
                
                let (mu, sigma2) = try self.getGaussianParameter(positiveDirectory: positiveDirectory,
                                                             positiveFiles: pEstimate)
                
                let epsilon = try self.findEpsilon(positiveDirectory: positiveDirectory, positiveFiles: pVar,
                                               negativeDirectory: negativeDirectory, negativeFiles: negatives,
                                               mu: mu, sigma2: sigma2)
                
                self.mu = mu
                self.sigma2 = sigma2
                self.epsilon = epsilon
                
                DispatchQueue.main.async {
                    self.blockView.hide()
                }
            } catch is InvalidInputError {
                self.view.window?.close()
            } catch(let e) {
                Swift.print("error: \(e.localizedDescription)")
                self.view.window?.close()
            }
        }
    }
    
    func cropNext() {
        let strider = strideField.integerValue
        guard strider > 0 else {
            showAlert("Stirde must be greater than 0.")
            return
        }
        
        var x = self.x.value
        var y = self.y.value
        
        guard x>=0 && y>=0 else {
            showAlert("Invalid position.")
            return
        }
        
        blockView.show(with: "Searching...")
        
        DispatchQueue.global().async {
            var v = DBL_MIN
            
            repeat {
                x += strider
                if(x + self.width >= self.image.width) {
                    x = 0
                    y += strider
                }
                if(y + self.height >= self.image.height){
                    DispatchQueue.main.async {
                        showAlert("Reached end.")
                        self.imageView.image = nil
                        self.blockView.hide()
                    }
                    break
                }
                let patch = self.image[x..<x+self.width, y..<y+self.height]
                let patchGray = patch.pixels.map { Double($0.gray)/255.0 }
                v = self.gaussian(x: patchGray, mu: self.mu, sigma2: self.sigma2)
                
                if(v > self.epsilon) {
                    // found positive-like point
                    print("(\(x), \(y)): score \(v) > \(self.epsilon)")
                    self.imageView.image = Image(self.image[x..<x+self.width, y..<y+self.height]).nsImage
                    DispatchQueue.main.async {
                        self.x.value = x
                        self.y.value = y
                        self.blockView.hide()
                    }
                    break
                }else {
                    DispatchQueue.main.async {
                        self.blockView.messageLabel.stringValue = "Searching...(\(x), \(y))"
                    }
                }
            } while(true)
        }
    }
    
    @IBAction func onPressCropNextButton(_ sender: AnyObject) {
        self.view.window?.makeFirstResponder(nil)
        cropNext()
    }
    
    @IBAction func onPressPosiiveButton(_ sender: AnyObject) {
        guard let image = imageView.image else {
            showAlert("Image is not found yet.")
            return
        }
        
        let number = positiveFileNumber.value
        
        if saveImage(image: image, directory: positiveDirectory, fileNumber: number) {
            positiveFileNumber.value += 1
            cropNext()
        }
    }
    
    @IBAction func onPressNeagtiveButton(_ sender: AnyObject) {
        
        guard let image = imageView.image else {
            showAlert("Image is not found yet.")
            return
        }
        
        let number = negativeFileNumber.value
        
        if saveImage(image: image, directory: negativeDirectory, fileNumber: number) {
            negativeFileNumber.value += 1
            cropNext()
        }
    }
    
    @IBAction func onPressEndButton(_ sender: AnyObject) {
        NSApplication.shared().stopModal()
    }
    
    func getGaussianParameter(positiveDirectory: String, positiveFiles: [String]) throws -> (mu: [Double], sigma2: [Double]) {
        
        let positiveUrl = URL(fileURLWithPath: positiveDirectory)
        
        let initial = (0, [Double](repeating: 0.0, count: width*height), [Double](repeating: 0.0, count: width*height))
        let (num, sums, sums2) = positiveFiles.reduce(initial) { acc, p in
            guard let gray = self.loadGrayImage(url: positiveUrl.appendingPathComponent(p)) else {
                return acc
            }
            
            guard gray.width == self.width && gray.height == self.height else {
                return acc
            }
            
            let sums = acc.1.zip(with: gray.pixels, f: +)
            let sums2 = acc.2.zip(with: gray.pixels) { acc, p in acc + p*p }
            return (acc.0+1, sums, sums2)
        }
    
        print("Number of samples for gaussian parameter: \(num)")
        if(num == 0) {
            throw InvalidInputError()
        }
        let mu = sums.map { $0 / Double(num) }
        let sigma2 = sums2.map { $0 / Double(num) }
            .zip(with: mu.zip(with: mu, f: *), f: -)
        
        return (mu, sigma2)
    }
    
    func gaussian(x: [Double], mu: [Double], sigma2: [Double]) -> Double {
        
        assert(x.count == mu.count && mu.count == sigma2.count)
        
        let a = sigma2.map { sqrt(2*M_PI*$0) }
        
        let xmu = x.zip(with: mu) { x, mu in pow(x-mu, 2) }
        
        let exponent = xmu.zip(with: sigma2) { xmu, sigma2 in -xmu/(2*sigma2) }
        
        return a.zip(with: exponent) { a, exponent in a*exp(exponent) }
            .reduce(1.0, +)
    }
    
    func findEpsilon(positiveDirectory: String, positiveFiles: [String],
                     negativeDirectory: String, negativeFiles: [String],
                     mu: [Double], sigma2: [Double]) throws -> Double {
        
        let positiveUrl = URL(fileURLWithPath: positiveDirectory)
        let initial = (DBL_MAX, DBL_MIN, [Double]())
        let (_minimum, _maximum, positiveValues) = positiveFiles
            .reduce(initial) { acc, p in
                guard let gray = self.loadGrayImage(url: positiveUrl.appendingPathComponent(p)) else {
                    return acc
                }
                guard gray.width==self.width && gray.height==self.height else {
                    return acc
                }
                let v = gaussian(x: gray.pixels, mu: mu, sigma2: sigma2)
                if v < acc.0 {
                    return (v, acc.1, acc.2+[v])
                } else if v > acc.1 {
                    return (acc.0, v, acc.2+[v])
                } else {
                    return (acc.0, acc.1, acc.2+[v])
                }
        }
        
        let negativeUrl = URL(fileURLWithPath: negativeDirectory)
        let initial2 = (_minimum, _maximum, [Double]())
        let (minimum, maximum, negativeValues) = negativeFiles.reduce(initial2) { acc, n in
            guard let gray = self.loadGrayImage(url: negativeUrl.appendingPathComponent(n)) else {
                return acc
            }
            guard gray.width==self.width && gray.height==self.height else {
                return acc
            }
            let v = gaussian(x: gray.pixels, mu: mu, sigma2: sigma2)
            if v < acc.0 {
                return (v, acc.1, acc.2+[v])
            } else if v > acc.1 {
                return (acc.0, v, acc.2+[v])
            } else {
                return (acc.0, acc.1, acc.2+[v])
            }
        }
        
        print("Epsilon estimation samples: P: \(positiveValues.count) N: \(negativeValues.count)")
        guard positiveValues.count > 0 && negativeValues.count > 0 else {
            throw InvalidInputError()
        }
        
        Swift.print("\(minimum) <= epsilon <= \(maximum)")
        
        let candidates = linspace(minimum: minimum, maximum: maximum, count: 100)
        
        // score and best e
        let (maxScore, epsilon) = candidates.reduce((DBL_MIN, DBL_MIN)) { acc, e in
            let truePositive = positiveValues.filter { $0 > e }.count
            let falsePositive = negativeValues.filter { $0 > e }.count
            
            let recall = Double(truePositive) / Double(positiveValues.count)
            let precision = Double(truePositive) / Double(truePositive + falsePositive)
            let f1Score = (2*recall*precision)/(recall+precision)
            
//            print("\(e): \nrec: \(recall)\nprec: \(precision)\nf1: \(f1Score)\n")
            
            // using recall may help to find boundary sample.
            if acc.0 <= recall {
                return (recall, e)
            } else {
                return acc
            }
        }
        
//        Swift.print("maxScore: \(maxScore)")
        Swift.print("epsilon: \(epsilon)")
        return epsilon
    }
    
    func loadGrayImage(url: URL) -> Image<Double>? {
        return Image<RGBA>(contentsOf: url)?.toGrayImage()
    }
}

private struct InvalidInputError: Error {
    
}
