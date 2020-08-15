import Foundation

public struct PassBeacon {
	/// Major identifier of a Bluetooth Low Energy location beacon.
	public var major: UInt16?
	/// Minor identifier of a Bluetooth Low Energy location beacon.
	public var minor: UInt16?
	/// Unique identifier of a Bluetooth Low Energy location beacon.
	public var proximityUUID: String
	/// Text displayed on the lock screen when the pass is currently relevant. For example, a description of the nearby location such as “Store nearby on 1st and Main.”
	public var relevantText: [PassLanguage: String]?
	
	public init(major: UInt16? = nil, minor: UInt16? = nil, proximityUUID: String, relevantText: [PassLanguage: String]? = nil) {
		self.major = major
		self.minor = minor
		self.proximityUUID = proximityUUID
		self.relevantText = relevantText
	}
}

// MARK: - Encodable
extension PassBeacon: Encodable {
	enum CodingKeys: String, CodingKey {
		case major
		case minor
		case proximityUUID
		case relevantText
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		if let major = major {
			try container.encode(major, forKey: .major)
		}
		if let minor = minor {
			try container.encode(minor, forKey: .minor)
		}
		try container.encode(proximityUUID, forKey: .proximityUUID)
		if relevantText != nil {
			try container.encode("pass.beacon.\(proximityUUID)", forKey: .relevantText)
		}
	}
}

// MARK: - Localizable
extension PassBeacon: Localizable {
	public var strings: [PassLanguage: [String: String]] {
		var strings = [PassLanguage: [String: String]]()
		let keys: [PassLanguage] = relevantText.flatMap { Array($0.keys) } ?? []
		for language in Set(keys) {
			var values = [String: String]()
			values["pass.beacon.\(proximityUUID)"] = relevantText?[language]
			strings[language] = values
		}
		return strings
	}
}
