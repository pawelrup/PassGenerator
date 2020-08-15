import Foundation

public enum PassValue {
	case double(Double)
	case string(String)
	case localizedString([PassLanguage: String])
}

extension PassValue: Encodable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		switch self {
		case .double(let double):
			try container.encode(double)
		case .string(let string):
			try container.encode(string)
		case .localizedString(let dict):
			try container.encode("pass.field.\(dict.hashValue)")
		}
	}
}

// MARK: - Localizable
extension PassValue: Localizable {
	public var strings: [PassLanguage: [String: String]] {
		guard case let .localizedString(dict) = self else { return [:] }
		var strings = [PassLanguage: [String: String]]()
		let keys: [PassLanguage] = Array(dict.keys)
		for language in Set(keys) {
			var values = [String: String]()
			values["pass.field.\(dict.hashValue)"] = dict[language]
			strings[language] = values
		}
		return strings
	}
}
