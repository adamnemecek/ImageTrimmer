
import Foundation
import Cocoa
import RxSwift
import RxCocoa
import EasyImagy

class PredictiveTrimViewController : TrimViewController {
    
    let disposeBag = DisposeBag()
    
    @IBOutlet weak var imageView: NSImageView!
    
    @IBOutlet weak var xField: NSTextField!
    @IBOutlet weak var yField: NSTextField!
    @IBOutlet weak var strideField: NSTextField!
    @IBOutlet weak var measureField: NSPopUpButton!
    
    // Model
    private var mu: [Double]!
    private var sigma2: [Double]!
    private var epsilon: Double!
    
    lazy var blockView: BlockView = {
        var array = NSArray()
        Bundle.main.loadNibNamed("BlockView", owner: nil, topLevelObjects: &array)
        let v = array.filter{ $0 is BlockView }.first as! BlockView
        
        self.view.addSubview(v)
        
        self.view.addConstraints([
                NSLayoutConstraint(item: v,
                                   attribute: .top,
                                   relatedBy: .equal,
                                   toItem: self.view,
                                   attribute: .top,
                                   multiplier: 1,
                                   constant: 0),
                NSLayoutConstraint(item: v,
                                   attribute: .left,
                                   relatedBy: .equal,
                                   toItem: self.view,
                                   attribute: .left,
                                   multiplier: 1,
                                   constant: 0),
                NSLayoutConstraint(item: v,
                                   attribute: .bottom,
                                   relatedBy: .equal,
                                   toItem: self.view,
                                   attribute: .bottom,
                                   multiplier: 1,
                                   constant: 0),
                NSLayoutConstraint(item: v,
                                   attribute: .right,
                                   relatedBy: .equal,
                                   toItem: self.view,
                                   attribute: .right,
                                   multiplier: 1,
                                   constant: 0)
            ])
        v.translatesAutoresizingMaskIntoConstraints = false
        
        v.onClickListener = { [weak self] in self!.cancelSearch() }
        
        return v
    }()
    
    override func viewWillDisappear() {
        cancelSearch()
    }
    
    override func viewDidDisappear() {
        NSApplication.shared().stopModal()
    }
    
    override func bind(image: Image<RGBA>!, x: Variable<Int>, y: Variable<Int>, width: Int, height: Int, positiveDirectory: String, negativeDirectory: String, positiveFileNumber: Variable<Int>, negativeFileNumber: Variable<Int>) {
        
        fatalError("use another")
        
    }
    
    func bind(image: Image<RGBA>!,
                       x: Variable<Int>,
                       y: Variable<Int>,
                       width: Int,
                       height: Int,
                       positiveDirectory: String,
                       negativeDirectory: String,
                       positiveFileNumber: Variable<Int>,
                       negativeFileNumber: Variable<Int>,
                       positiveSupervisorDirectory: String,
                       negativeSupervisorDirectory: String) {
        
        super.bind(image: image,
                   x: x,
                   y: y,
                   width: width,
                   height: height,
                   positiveDirectory: positiveDirectory,
                   negativeDirectory: negativeDirectory,
                   positiveFileNumber: positiveFileNumber,
                   negativeFileNumber: negativeFileNumber)
        
        weak var welf = self
        
        measureField.rx.controlEvent.startWith(())
            .map { welf!.measureField.selectedItem!.title }
            .subscribe(onNext: {
                Swift.print($0)
                welf!.createModel(positiveDirectory: positiveSupervisorDirectory,
                                  negativeDirectory: negativeSupervisorDirectory,
                                  measure: $0)
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
    
    func createModel(positiveDirectory: String, negativeDirectory: String, measure: String) {
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
                                               mu: mu, sigma2: sigma2, measure: measure)
                
                self.mu = mu
                self.sigma2 = sigma2
                self.epsilon = epsilon
                
                DispatchQueue.main.async {
                    self.blockView.hide()
                }
            } catch(let e) {
                let message: String
                switch e {
                case is InvalidInputError:
                    message = (e as! InvalidInputError).description
                default:
                    message = e.localizedDescription
                }
                Swift.print("error: \(message)")
                DispatchQueue.main.async {
                    showAlert("Error:\n\(message)")
                    self.view.window?.close()
                }
            }
        }
    }
    
    private var searchNextDisposable: Disposable?
    
    private func trimNext() {
        
        let strider = self.strideField.integerValue
        guard strider > 0 else {
            showAlert("Stirde must be greater than 0.")
            return
        }
        
        let x = self.x.value
        let y = self.y.value
        
        guard x>=0 && y>=0 else {
            showAlert("Invalid position.")
            return
        }
        
        guard let observable = searchNext(x: x, y: y ,strider: strider) else {
            return
        }
        
        self.blockView.show(with: "Searching...")
        
        weak var welf = self
        let disposable = observable.observeOn(MainScheduler.instance)
            .subscribe(
            onNext: { state in
                switch state {
                case .progress(let x, let y):
                    welf?.blockView.messageLabel.stringValue = "Searching...(\(x), \(y))"
                case .found(let x, let y):
                    welf?.x.value = x
                    welf?.y.value = y
                    welf?.imageView.image = Image(welf!.image[x..<x+welf!.width, y..<y+welf!.height]).nsImage
                case .notFound:
                    showAlert("Reached end.")
                    welf?.imageView.image = nil
                }
            },
            onCompleted: { welf?.blockView.hide() },
            onDisposed: { welf?.blockView.hide() })
        
        disposable.addDisposableTo(disposeBag)
        searchNextDisposable = disposable
    }
    
    private func cancelSearch() {
        searchNextDisposable?.dispose()
        searchNextDisposable = nil
    }
    
    private enum SearchState {
        case progress(x: Int, y: Int)
        case found(x: Int, y: Int)
        case notFound
    }
    
    private func searchNext(x: Int, y: Int, strider: Int) -> Observable<SearchState>? {
        
        return Observable<SearchState>.create { observer in
            var canceled = false
            
            DispatchQueue.global().async {
                var v = DBL_MIN
                var x = x
                var y = y
                
                repeat {
                    guard !canceled else {
                        break
                    }
                    x += strider
                    if(x + self.width >= self.image.width) {
                        x = 0
                        y += strider
                    }
                    if(y + self.height >= self.image.height){
                        observer.onNext(.notFound)
                        break
                    }
                    let patch = self.image[x..<x+self.width, y..<y+self.height]
                    let patchGray = patch.pixels.map { Double($0.gray)/255.0 }
                    v = self.gaussian(x: patchGray, mu: self.mu, sigma2: self.sigma2)
                    
                    if(v > self.epsilon) {
                        // found positive-like point
                        print("(\(x), \(y)): score \(v) > \(self.epsilon)")
                        observer.onNext(.found(x: x, y: y))
                        self.imageView.image = Image(self.image[x..<x+self.width, y..<y+self.height]).nsImage
                        break
                    }else {
                        observer.onNext(.progress(x: x, y: y))
                    }
                } while(true)
                
                observer.onCompleted()
            }
            
            return Disposables.create {
                canceled = true
            }
        }
    }
    
    @IBAction func onPressTrimNextButton(_ sender: AnyObject) {
        self.view.window?.makeFirstResponder(nil)
        trimNext()
    }
    
    @IBAction func onPressPosiiveButton(_ sender: AnyObject) {
        guard let image = imageView.image else {
            showAlert("Image is not found yet.")
            return
        }
        
        let number = positiveFileNumber.value
        
        if saveImage(image: image, directory: positiveDirectory, fileNumber: number) {
            positiveFileNumber.value += 1
            trimNext()
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
            trimNext()
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
            throw InvalidInputError("No valid positive samples found.")
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
                     mu: [Double], sigma2: [Double], measure: String) throws -> Double {
        
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
            throw InvalidInputError("No samples for cross validation found.\nP: \(positiveValues.count)\nN: \(negativeValues.count)")
        }
        
        Swift.print("\(minimum) <= epsilon <= \(maximum)")
        
        let candidates = linspace(minimum: minimum, maximum: maximum, count: 100)
        
        // score and best e
        let (maxScore, epsilon) = try candidates.reduce((DBL_MIN, DBL_MIN)) { acc, e in
            let truePositive = positiveValues.filter { $0 > e }.count
            let falsePositive = negativeValues.filter { $0 > e }.count
            
            let recall = Double(truePositive) / Double(positiveValues.count)
            let precision = Double(truePositive) / Double(truePositive + falsePositive)
            let f1Score = (2*recall*precision)/(recall+precision)
            
//            print("\(e): \nrec: \(recall)\nprec: \(precision)\nf1: \(f1Score)\n")
            
            let score: Double
            switch measure {
            case "Recall":
                score = recall
            case "Precision":
                score = precision
            case "F1 score":
                score = f1Score
            default:
                throw InvalidInputError("Invalid measure: \(measure)")
            }
            
            if acc.0 <= score {
                return (score, e)
            } else {
                return acc
            }
        }
        
        Swift.print("Max \(measure): \(maxScore)")
        Swift.print("epsilon: \(epsilon)")
        return epsilon
    }
    
    func loadGrayImage(url: URL) -> Image<Double>? {
        return Image<RGBA>(contentsOf: url)?.toGrayImage()
    }
}

private class InvalidInputError: Error {
    
    let description: String
    init(_ description: String) {
        self.description = description
    }
    
    
}
