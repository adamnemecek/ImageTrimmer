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

class PredictiveCropViewController : CropViewController {
    
    let disposeBag = DisposeBag()
    
    var positiveSupervisorDirectory = ReplaySubject<String>.create(bufferSize: 1)
    var negativeSupervisorDirectory = ReplaySubject<String>.create(bufferSize: 1)
    
    override func viewDidLoad() {
        
        Observable.combineLatest(positiveSupervisorDirectory,
                                 negativeSupervisorDirectory) { ($0, $1) }
            .subscribe(onNext: {
                Swift.print($0)
            })
            .addDisposableTo(disposeBag)
        
        
    }
}
