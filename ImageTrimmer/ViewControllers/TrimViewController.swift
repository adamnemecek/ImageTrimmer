
import Foundation
import Cocoa
import EasyImagy
import RxSwift

class TrimViewController: NSViewController {
    var image: Image<RGBA>!
    var width: Int!
    var height: Int!
    var positiveDirectory: String!
    var negativeDirectory: String!
    
    var positiveFileNumber: Variable<Int>!
    var negativeFileNumber: Variable<Int>!
}
