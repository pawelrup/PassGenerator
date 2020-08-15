import Foundation

public struct PassLocation: Hashable {
	/// Altitude, in meters, of the location.
	public var altitude: Double?
	/// Latitude, in degrees, of the location.
	public var latitude: Double
	/// Longitude, in degrees, of the location.
	public var longitude: Double
	/// Text displayed on the lock screen when the pass is currently relevant. For example, a description of the nearby location such as “Store nearby on 1st and Main.”
	public var relevantText: [PassLanguage: String]?
	
	public init(altitude: Double? = nil, latitude: Double, longitude: Double, relevantText: [PassLanguage: String]? = nil) {
		self.altitude = altitude
		self.latitude = latitude
		self.longitude = longitude
		self.relevantText = relevantText
	}
}

// MARK: - Encodable
extension PassLocation: Encodable {
	enum CodingKeys: String, CodingKey {
		case altitude
		case latitude
		case longitude
		case relevantText
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		if let altitude = altitude {
			try container.encode(altitude, forKey: .altitude)
		}
		try container.encode(latitude, forKey: .latitude)
		try container.encode(longitude, forKey: .longitude)
		if relevantText != nil {
			try container.encode("pass.location.\(hashValue)", forKey: .relevantText)
		}
	}
}

// MARK: - Localizable
extension PassLocation: Localizable {
	public var strings: [PassLanguage: [String: String]] {
		var strings = [PassLanguage: [String: String]]()
		let keys: [PassLanguage] = relevantText.flatMap { Array($0.keys) } ?? []
		for language in Set(keys) {
			var values = [String: String]()
			values["pass.location.\(hashValue)"] = relevantText?[language]
			strings[language] = values
		}
		return strings
	}
}
