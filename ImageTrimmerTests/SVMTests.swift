
import XCTest
@testable import ImageTrimmer

class SVMTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testTrain() {
        
        var x11 = [1.0, 1.0];
        var x10 = [1.0, 0.0];
        var x01 = [0.0, 1.0];
        var x00 = [0.0, 0.0];
        var samples = [
            Sample(elements: &x11, length: 2, positive: false),
            Sample(elements: &x10, length: 2, positive: true),
            Sample(elements: &x01, length: 2, positive: true),
            Sample(elements: &x00, length: 2, positive: false)
        ]
        
        let model = train(&samples, 2, Int32(samples.count), 1, 0.5)
        
        let p11 = predict(model, Sample(elements: &x11, length: 2, positive: false))
        let p10 = predict(model, Sample(elements: &x10, length: 2, positive: false))
        let p01 = predict(model, Sample(elements: &x01, length: 2, positive: false))
        let p00 = predict(model, Sample(elements: &x00, length: 2, positive: false))
        
        XCTAssertFalse(p11)
        XCTAssertTrue(p10)
        XCTAssertTrue(p01)
        XCTAssertFalse(p00)
        
        destroy(model)
    }
    
    func testTrain2() {
        
        let s = 100
        
        let vecs = linspace(minimum: -1, maximum: 1, count: s)
            .flatMap { x in linspace(minimum: -1, maximum: 1, count: s).map { (x,$0) } }
            .shuffled()
        
        var samples = vecs.map { x, y -> Sample in
            let e = UnsafeMutablePointer<Double>.allocate(capacity: 2)
            e[0] = x
            e[1] = y
            print(e[0], e[1])
            return Sample(elements: e, length: 2, positive: x*x+y*y<1.0)
        }
        
        let start = Date()
        let model = train(&samples, 2, Int32(samples.count), 1, 0.5)
        print("elapsed time:", Date().timeIntervalSince(start))
        
        do{
            let p = vecs.filter { x, y in
                var e = [x, y]
                let r = predict(model, Sample(elements: &e, length: 2, positive: false))
                return (x*x+y*y<1.0) == r
                }.count
            
            print("train accuracy: \(Double(p)/Double(vecs.count))")
        }
        
        do {
            let c: Int = 1000
            let p = (0..<c)
                .map { _ -> (Double, Double) in
                let x = 1.0 - 2*Double(arc4random_uniform(1024*1024)) / (1024*1024)
                let y = 1.0 - 2*Double(arc4random_uniform(1024*1024)) / (1024*1024)
                return (x, y)
                }
                .filter { x, y in
                    var e = [x, y]
                    let r = predict(model, Sample(elements: &e, length: 2, positive: false))
                    return (x*x+y*y<1.0) == r
                }.count
            
            print("accuracy: \(Double(p)/Double(c))")
        }
        
        samples.forEach { $0.elements.deallocate(capacity: 2) }
        
        destroy(model)
    }
}
