//
//  Communicator.swift
//  JobInterviewHW2.0
//
//  Created by Perry on 01/12/2017.
//  Copyright © 2017 perrchick. All rights reserved.
//

import Foundation
import Alamofire

class Communicator {
    
    // Perry: "Ron, I felt it was fimiliar to me, now I remember where did I see it: https://medium.com/@jbergen/you-ve-been-using-enums-in-swift-all-wrong-b8156df64087"
    public enum Response {
        case succeeded(response: Any)
        case failed(error: NSError)
    }

    static func request(urlString: String, completion: @escaping CompletionClosure<Response>) {

        // Make HTTP request and fetch...
        📗("Calling: \(urlString)")
        Alamofire.request(urlString).responseJSON { (response) in
            if let JSON = response.result.value, response.result.error == nil {
                // Request succeeded!
                completion(Response.succeeded(response: JSON))
            } else {
                // Request failed! ... handle failure
                ToastMessage.show(messageText: "Error retrieving address")
                if let error = response.result.error as NSError? {
                    completion(Response.failed(error: error))
                } else {
                    completion(Response.failed(error: NSError.custom(domain: "parsing failed")))
                }
            }
        }
    }
}

extension NSError {
    static func custom(domain: String, code: Int = 0, userInfo: [String : Any]? = nil) -> NSError {
        let error = NSError(domain: domain, code: code, userInfo: userInfo)
        return error
    }
}
