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
	
    func generatePass(configuration: PassGeneratorConfiguration, logger: Logger) -> EventLoopFuture<Data> {
		return flatMap { [unowned self] value in
            let generator = PassGenerator(configuration: configuration, logger: logger)
			return generator.generatePass(value.pass, on: self.eventLoop)
		}
	}
}
