//
//  Throttler.swift
//  JobInterviewHW2.0
//
//  Created by Perry on 01/12/2017.
//  Copyright © 2017 perrchick. All rights reserved.
//

import Foundation

/// Inspired from: https://www.linkedin.com/groups/121874/121874-6326861594919870465 & https://gist.github.com/simme/b78d10f0b29325743a18c905c5512788
class Throttler { // TODO: Test it, because this haven't been tested yet, memory and stuff
    private var operationToThrottle: (() -> ())?
    private var closureTimer: ClosureTimer?

    func throttle(timeout: TimeInterval, operation: @escaping () -> ()) {
        closureTimer?.invalidate()
        closureTimer = ClosureTimer.runBlockAfterDelay(afterDelay: timeout, block: { [weak self] _ in
            self?.closureTimer?.invalidate()
            self?.closureTimer = nil
            self?.operationToThrottle?()
        })
    }
}
