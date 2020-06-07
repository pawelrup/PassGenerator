//
//  URL+unixPath.swift
//  PassGenerator
//
//  Created by Pawel Rup on 26/03/2020.
//

import Foundation

extension URL {
	var unixPath: String {
		absoluteString.replacingOccurrences(of: "file://", with: "")
	}
}
