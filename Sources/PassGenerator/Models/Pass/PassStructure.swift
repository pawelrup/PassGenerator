import Foundation

public struct PassStructure {
	/// Additional fields to be displayed on the front of the pass.
	public var auxiliaryFields: [PassField]?
	/// Fields to be on the back of the pass.
	public var backFields: [PassField]?
	/// Fields to be displayed in the header on the front of the pass.
	/// Use header fields sparingly; unlike all other fields, they remain visible when a stack of passes are displayed.
	public var headerFields: [PassField]?
	/// Fields to be displayed prominently on the front of the pass.
	public var primaryFields: [PassField]?
	/// Fields to be displayed on the front of the pass.
	public var secondaryFields: [PassField]?
	/// Required for boarding passes; otherwise not allowed. Type of transit.
	public var transitType: PassTransitType?
	
	public init(auxiliaryFields: [PassField]? = nil, backFields: [PassField]? = nil, headerFields: [PassField]? = nil, primaryFields: [PassField]? = nil, secondaryFields: [PassField]? = nil, transitType: PassTransitType? = nil) {
		self.auxiliaryFields = auxiliaryFields
		self.backFields = backFields
		self.headerFields = headerFields
		self.primaryFields = primaryFields
		self.secondaryFields = secondaryFields
		self.transitType = transitType
	}
}

// MARK: - Encodable
extension PassStructure: Encodable {
	enum CodingKeys: String, CodingKey {
		case auxiliaryFields
		case backFields
		case headerFields
		case primaryFields
		case secondaryFields
		case transitType
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		if let auxiliaryFields = auxiliaryFields {
			try container.encode(auxiliaryFields, forKey: .auxiliaryFields)
		}
		if let backFields = backFields {
			try container.encode(backFields, forKey: .backFields)
		}
		if let headerFields = headerFields {
			try container.encode(headerFields, forKey: .headerFields)
		}
		if let primaryFields = primaryFields {
			try container.encode(primaryFields, forKey: .primaryFields)
		}
		if let secondaryFields = secondaryFields {
			try container.encode(secondaryFields, forKey: .secondaryFields)
		}
		if let transitType = transitType {
			try container.encode(transitType, forKey: .transitType)
		}
	}
}

// MARK: - Localizable
extension PassStructure: Localizable {
	public var strings: [PassLanguage: [String: String]] {
		[
			(auxiliaryFields ?? []),
			(backFields ?? []),
			(headerFields ?? []),
			(primaryFields ?? []),
			(secondaryFields ?? [])
		]
		.flatMap { $0 }
		.map { $0.strings }
		.reduce([:]) { $0.merging($1, uniquingKeysWith: { $0.merging($1, uniquingKeysWith: { $1 }) }) }
	}
}
