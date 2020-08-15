import Foundation

public struct PassField {
	/// Attributed value of the field.
	/// The value may contain HTML markup for links. Only the <a> tag and its href attribute are supported.
	/// For example, the following is key-value pair specifies a link with the text “Edit my profile”: "attributedValue": "<a href='http://example.com/customers/123'>Edit my profile</a>"
	/// This key’s value overrides the text specified by the value key.
	/// Available in iOS 7.0.
	public var attributedValue: PassValue?
	/// Format string for the alert text that is displayed when the pass is updated. The format string must contain the escape %@, which is replaced with the field’s new value. For example, “Gate changed to %@.”
	/// If you don’t specify a change message, the user isn’t notified when the field changes.
	public var changeMessage: String?
	/// Data detectors that are applied to the field’s value.
	/// The default value is all data detectors. Provide an empty array to use no data detectors.
	/// Data detectors are applied only to back fields.
	public var dataDetectorTypes: [PassDataDetectorType]?
	/// The key must be unique within the scope of the entire pass. For example, “departure-gate.”
	public var key: String
	/// Label text for the field.
	public var label: [PassLanguage: String]?
	/// Alignment for the field’s contents.
	/// The default value is natural alignment, which aligns the text appropriately based on its script direction.
	/// This key is not allowed for primary fields or back fields.
	public var textAligment: PassTextAlignment?
	/// Value of the field, for example, 42.
	public var value: PassValue?
	
	public init(attributedValue: PassValue? = nil, changeMessage: String? = nil, dataDetectorTypes: [PassDataDetectorType]? = nil, key: String, label: [PassLanguage: String]? = nil, textAligment: PassTextAlignment? = nil, value: PassValue? = nil) {
		self.attributedValue = attributedValue
		self.changeMessage = changeMessage
		self.dataDetectorTypes = dataDetectorTypes
		self.key = key
		self.label = label
		self.textAligment = textAligment
		self.value = value
	}
}

// MARK: - Encodable
extension PassField: Encodable {
	enum CodingKeys: String, CodingKey {
		case attributedValue
		case changeMessage
		case dataDetectorTypes
		case key
		case label
		case textAligment
		case value
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		if let attributedValue = attributedValue {
			try container.encode(attributedValue, forKey: .attributedValue)
		}
		if let changeMessage = changeMessage {
			try container.encode(changeMessage, forKey: .changeMessage)
		}
		if let dataDetectorTypes = dataDetectorTypes {
			try container.encode(dataDetectorTypes, forKey: .dataDetectorTypes)
		}
		try container.encode(key, forKey: .key)
		if label != nil {
			try container.encode("pass.field.\(key)", forKey: .label)
		}
		if let textAligment = textAligment {
			try container.encode(textAligment, forKey: .textAligment)
		}
		if let value = value {
			try container.encode(value, forKey: .value)
		}
	}
}

// MARK: - Localizable
extension PassField: Localizable {
	public var strings: [PassLanguage: [String: String]] {
		var strings = [PassLanguage: [String: String]]()
		let keys: [PassLanguage] = label.flatMap { Array($0.keys) } ?? []
		for language in Set(keys) {
			var values = [String: String]()
			values["pass.field.\(key)"] = label?[language]
			strings[language] = values
		}
		return strings
	}
}
