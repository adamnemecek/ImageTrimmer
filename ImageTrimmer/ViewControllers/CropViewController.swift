//
//  CropViewController.swift
//  ImageTrimmer
//
//  Created by Araki Takehiro on 2016/10/18.
//  Copyright © 2016年 Araki Takehiro. All rights reserved.
//

import Foundation
import Cocoa
import EasyImagy
import RxSwift

class CropViewController: NSViewController {
    var image: Image<RGBA>!
    var width: Int!
    var height: Int!
    var positiveDirectory: String!
    var negativeDirectory: String!
    
    var positiveFileNumber: Variable<Int>!
    var negativeFileNumber: Variable<Int>!
}
