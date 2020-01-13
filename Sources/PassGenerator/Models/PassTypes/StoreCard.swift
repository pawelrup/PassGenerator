//
//  File.swift
//  
//
//  Created by Pawel Rup on 10/01/2020.
//

import Foundation

public protocol StoreCard {
    var description: String { get }
    var organizationName: String { get }
    var passTypeIdentifier: String { get }
    var serialNumber: String { get }
    var teamIdentifier: String { get }
    var backgroundColor: String { get }
    var foregroundColor: String { get }
    var labelColor: String { get }
    var stripColor: String? { get }
    var passBarcodeFormat: PassBarcodeFormat { get }
    var locations: [PassLocation] { get }
    var auxiliaryFields: [PassField]? { get }
    var backFields: [PassField] { get }
    var headerFields: [PassField]? { get }
    var primaryFields: [PassField]? { get }
    var secondaryFields: [PassField] { get }
    var passBarcodeAltText: String { get }
    var passBarcodeMessage: String { get }
    var semantics: PassSemantics? { get }
}

extension StoreCard {
    private var passBarcode: PassBarcode {
        .init(altText: passBarcodeAltText, format: passBarcodeFormat, message: passBarcodeMessage, messageEncoding: .iso88591)
    }
    private var passStructure: PassStructure {
        PassStructure(auxiliaryFields: auxiliaryFields, backFields: backFields, headerFields: headerFields, primaryFields: primaryFields, secondaryFields: secondaryFields, transitType: nil)
    }
    
    public var pass: Pass {
        Pass(
            description: description,
            formatVersion: 1,
            organizationName: organizationName,
            passTypeIdentifier: passTypeIdentifier,
            serialNumber: serialNumber,
            teamIdentifier: teamIdentifier,
            locations: locations,
            storeCard: passStructure,
            barcodes: [passBarcode],
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            labelColor: labelColor,
            stripColor: stripColor,
            semantics: semantics)
    }
}
