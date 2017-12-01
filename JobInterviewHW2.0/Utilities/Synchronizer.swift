//
//  Synchronizer.swift
//  SomeApp
//
//  Created by Perry on 3/25/16.
//  Copyright © 2016 PerrchicK. All rights reserved.
//

import Foundation

/// Inspired from a prevoius project of mine: https://github.com/PerrchicK/swift-app/blob/5f3dbf46e4feeded2319377c4fdbb4f4fbf3c99d/SomeApp/SomeApp/Classes/Utilities/Synchronizer.swift
class Synchronizer {
    internal class HolderTicket {
        let blockOperation: BlockOperation
        let raceConditionQueue: OperationQueue
        
        init(raceConditionQueue: OperationQueue, block: (() -> Void)? = nil) {
            self.raceConditionQueue = raceConditionQueue
            if let block = block {
                blockOperation = BlockOperation(block: block)
            } else {
                blockOperation = BlockOperation(block: {
                    // Do nothing...
                    //📘("operation is done")
                })
            }
        }
        @discardableResult
        func release() -> Bool {
            if !blockOperation.isFinished {
                // Dispatch...
                raceConditionQueue.addOperation(blockOperation)
                return true
            }
            
            return false
        }
    }
    
    let raceConditionQueue = OperationQueue()
    
    let completionOperation: BlockOperation
    fileprivate var shouldAddCompletionOperation = true
    /**
     Initializes an atomic synchronization between two operations
     
     - parameter operation1: An operation to do, regardless the time to end
     - parameter operation2: An operation to do, regardless the time to end
     - parameter finalOperation: The completion operation to do, only after the first two are finished. It shall be invoked on the main thread.
     */
    init(userInfo: AnyObject? = nil, queueToRunOnDone: DispatchQueue = DispatchQueue.main, finalOperation: @escaping (_ userInfo: AnyObject?) -> Void) {
        let completionOperation = BlockOperation {
                DispatchQueue.main.async(execute: {
                    finalOperation(userInfo)
                })
        }
        
        self.completionOperation = completionOperation
    }
    
    func createHolder(onReleaseBlock: (() -> Void)? = nil) -> HolderTicket {
        let blocker = HolderTicket(raceConditionQueue: self.raceConditionQueue, block: onReleaseBlock)
        self.completionOperation.addDependency(blocker.blockOperation)
        
        // Will occur only once
        if shouldAddCompletionOperation {
            shouldAddCompletionOperation = false
            self.raceConditionQueue.addOperation(completionOperation)
        }
        
        return blocker
    }
    
    static func syncOperations(_ operations: [() -> Void],withFinalOperation finalOperation: @escaping () -> Void) {
        guard operations.count > 0 else { finalOperation(); return }
        
        guard operations.count > 1 else {
            operations[0]()
            finalOperation()
            return
        }
        
        let raceConditionQueue = OperationQueue()
        let completionOperation = BlockOperation {
            DispatchQueue.main.async(execute: {
                finalOperation()
            })
        }
        
        var blockOps = [BlockOperation]()
        for operation in operations {
            let blockOperation = BlockOperation(block: operation)
            blockOps.append(blockOperation)
            
            completionOperation.addDependency(blockOperation)
        }
        
        raceConditionQueue.addOperation(completionOperation)
        
        for blockOperation in blockOps {
            raceConditionQueue.addOperation(blockOperation)
        }
    }
}
