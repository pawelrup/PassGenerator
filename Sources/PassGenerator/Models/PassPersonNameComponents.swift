//
//  File.swift
//  
//
//  Created by Pawel Rup on 24/11/2019.
//

import Foundation

/// A JSON dictionary with keys that will be provided as components to NSPersonNameComponents. All keys are optional.
///
/// An example might look like this:
///
///     {"givenName":"John", "familyName":"Appleseed"}
public struct PassPersonNameComponents: Codable {
    private enum CodingKeys: String, CodingKey {
        case givenName, middleName, familyName, namePrefix, nameSuffix, nickname, phoneticRepresentation
    }
    private var _phoneticRepresentation = Indirect<PassPersonNameComponents?>(nil)
    
    public let givenName: String?
    public let middleName: String?
    public let familyName: String?
    public let namePrefix: String?
    public let nameSuffix: String?
    public let nickname: String?
    public var phoneticRepresentation: PassPersonNameComponents? {
      get { return _phoneticRepresentation.value }
      set { _phoneticRepresentation.value = newValue }
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        givenName = try values.decodeIfPresent(String.self, forKey: .givenName)
        middleName = try values.decodeIfPresent(String.self, forKey: .middleName)
        familyName = try values.decodeIfPresent(String.self, forKey: .familyName)
        namePrefix = try values.decodeIfPresent(String.self, forKey: .namePrefix)
        nameSuffix = try values.decodeIfPresent(String.self, forKey: .nameSuffix)
        nickname = try values.decodeIfPresent(String.self, forKey: .nickname)
        phoneticRepresentation = try values.decodeIfPresent(PassPersonNameComponents.self, forKey: .phoneticRepresentation)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(givenName, forKey: .givenName)
        try container.encode(middleName, forKey: .middleName)
        try container.encode(familyName, forKey: .familyName)
        try container.encode(namePrefix, forKey: .namePrefix)
        try container.encode(nameSuffix, forKey: .nameSuffix)
        try container.encode(nickname, forKey: .nickname)
        try container.encode(phoneticRepresentation, forKey: .phoneticRepresentation)
    }
}
