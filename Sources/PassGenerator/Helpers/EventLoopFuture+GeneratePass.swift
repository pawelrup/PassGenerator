//
//  EventLoopFuture+GeneratePass.swift
//  
//
//  Created by Pawel Rup on 20/02/2020.
//

import Foundation
import NIO

public extension EventLoopFuture where Value: PassConvertible {
    
    func generatePass(certificateURL: URL, certificatePassword: String, wwdrURL: URL, templateURL: URL) -> EventLoopFuture<Data> {
        return flatMap { [unowned self] value in
            let generator = PassGenerator(certificateURL: certificateURL, certificatePassword: certificatePassword, wwdrURL: wwdrURL, templateDirectoryURL: templateURL)
            return generator.generatePass(pass: value.pass, on: self.eventLoop)
        }
    }
}
