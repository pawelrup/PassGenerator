//
//  File.swift
//  
//
//  Created by Pawel Rup on 24/11/2019.
//

import Foundation

/// A dictionary consisting of an ISO 4217 currency code in the currencyCode key and an amount in the amount key. Both values must be JSON strings.
///
/// An example might look like this:
///
///     {"currencyCode:"USD", "amount":"12.50"}
public struct PassCurrencyAmount: Codable {
    public let currencyCode: String
    public let amount: String
}
