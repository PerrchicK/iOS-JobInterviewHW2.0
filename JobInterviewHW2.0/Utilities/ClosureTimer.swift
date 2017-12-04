//
//  ClosureTimer.swift
//  Scenes
//
//  Created by Perry on 30/08/2016.
//  Copyright © 2017 perrchick. All rights reserved.
//

import Foundation

class ClosureTimer {
    let timer: Timer
    class Executor {
        let block: CompletionClosure<Any?>
        
        init(block: @escaping CompletionClosure<Any>) {
            self.block = block
        }
        
        @objc func timerFired(_ timer: Timer) {
            block(timer.userInfo as AnyObject?)
        }
    }
    
    init(afterDelay seconds: TimeInterval = 0.0, userInfo: Any?,repeats: Bool, block: @escaping CompletionClosure<Any>) {
        
        let executor = Executor(block: block)
        
        timer = Timer.scheduledTimer(timeInterval: seconds, target: executor, selector: #selector(Executor.timerFired(_:)), userInfo: userInfo, repeats: repeats)
        
    }
    
    func invalidate() {
        timer.invalidate()
    }
    
    @discardableResult
    static func runBlockAfterDelay(afterDelay seconds: Double, repeats: Bool = false, userInfo: Any? = nil, onQueue: DispatchQueue = DispatchQueue.main, block: @escaping CompletionClosure<Any>) -> ClosureTimer {
        let timer = ClosureTimer(afterDelay: seconds, userInfo: userInfo, repeats: repeats, block: block)
        
        return timer
    }
}
