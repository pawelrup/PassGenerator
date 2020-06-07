//
//  EventLoopFuture+GeneratePass.swift
//  PassGenerator
//
//  Created by Pawel Rup on 20/02/2020.
//

import Foundation
import NIO
import Logging

public extension EventLoopFuture where Value: PassConvertible {
	
	func generatePass(certificateURL: URL, certificatePassword: String, wwdrURL: URL, templateURL: URL, destinationURL: URL, logger: Logger) -> EventLoopFuture<Data> {
		return flatMap { [unowned self] value in
			let generator = PassGenerator(certificateURL: certificateURL, certificatePassword: certificatePassword, wwdrURL: wwdrURL, templateURL: templateURL, logger: logger)
			return generator.generatePass(value.pass, to: destinationURL, on: self.eventLoop)
		}
	}
}
