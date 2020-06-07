import Foundation

/// A dictionary with one or more of the following JSON string keys. Valid keys are: seatSection, seatRow, seatNumber, seatIdentifier, seatType, seatDescription.
///
/// An example might look like this:
///
///     {"seatRow":"1", "seatNumber":"A", "seatType":"Economy"}
public struct PassSeat: Codable {
	public let seatSection: String?
	public let seatRow: String?
	public let seatNumber: String?
	public let seatIdentifier: String?
	public let seatType: String?
	public let seatDescription: String?
	
	public init(seatSection: String? = nil, seatRow: String? = nil, seatNumber: String? = nil, seatIdentifier: String? = nil, seatType: String? = nil, seatDescription: String? = nil) {
		self.seatSection = seatSection
		self.seatRow = seatRow
		self.seatNumber = seatNumber
		self.seatIdentifier = seatIdentifier
		self.seatType = seatType
		self.seatDescription = seatDescription
	}
}
