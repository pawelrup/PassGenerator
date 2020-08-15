//
//  Localizable.swift
//  
//
//  Created by Pawel Rup on 15/08/2020.
//

public protocol Localizable {
	var strings: [PassLanguage: [String: String]] { get }
}
