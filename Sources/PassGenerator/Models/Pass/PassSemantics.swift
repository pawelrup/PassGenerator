//
//  File.swift
//  
//
//  Created by Pawel Rup on 24/11/2019.
//

import Foundation

/// The operating system uses the semantic tag data to offer a pass at the most appropriate time. For example, semantic tags added to a movie pass could take effect when the user arrives in the theater at the scheduled time by showing a Siri suggestion to enable Do Not Disturb mode for the duration of the film.
/// In order for the system to send the suggestion to set Do Not Disturb, the eventType must be set to indicate that the pass is a movie ticket and the silenceRequested, eventStartDate, eventEndDate, and venueLocation tags must be added.
public struct PassSemantics: Codable {
    
    // MARK: - Semantics for All Passes
    
    /// The total price for the pass
    public var totalPrice: PassCurrencyAmount?
    
    // MARK: - Semantics for Boarding Passes and Events
    
    /// The duration of the event or transit journey, in seconds.
    public var duration: PassValue?
    /// Seating details for all seats at the event or transit journey.
    public var seats: [PassSeat]?
    /// Request the user's device to remain silent during a the event or transit journey. This key may not be honored and the system will determine the length of the silence period.
    public var silenceRequested: Bool?
    
    // MARK: - Semantics for All Boarding Passes
    
    /// The geographic coordinates of the transit departure, suitable to be shown on a map. If possible, precise locations are more useful to travelers, such as the specific location of the gate at an airport.
    public var departureLocation: PassLocation?
    /// A brief description of the departure location. For example, for a flight departing from an airport whose code is "SFO", "San Francisco" might be an appropriate description.
    public var departureLocationDescription: String?
    /// The geographic coordinates of the transit destination, suitable to be shown on a map.
    public var destinationLocation: PassLocation?
    /// A brief description of the destination location.
    public var destinationLocationDescription: String?
    /// The name of the transit company.
    public var transitProvider: String?
    /// The name of the vehicle being boarded, such as the name of a boat.
    public var vehicleName: String?
    /// The identifier of the vehicle being boarded, such as the aircraft registration number or train number.
    public var vehicleNumber: String?
    /// A brief description of the type of vehicle being boarded, such as the model and manufacturer of a plane or the class of a boat.
    public var vehicleType: String?
    /// The updated date and time of departure, if different than the original scheduled date.
    public var originalDepartureDate: Date?
    /// The updated date and time of departure, if different than the original scheduled date.
    public var currentDepartureDate: Date?
    /// The original scheduled date and time of arrival.
    public var originalArrivalDate: Date?
    /// The updated date and time of arrival, if different than the original scheduled date.
    public var currentArrivalDate: Date?
    /// The original scheduled date and time of boarding.
    public var originalBoardingDate: Date?
    /// The updated date and time of boarding, if different than the original scheduled date.
    public var currentBoardingDate: Date?
    /// A group number for boarding.
    public var boardingGroup: String?
    /// A sequence number for boarding.
    public var boardingSequenceNumber: String?
    /// A booking or reservation confirmation number.
    public var confirmationNumber: String?
    /// A brief description of the current status of the vessel being boarded, such as "On Time" or "Delayed". For delayed statuses, provide currentBoardingDate, currentDepartureDate, and currentArrivalDate where available.
    public var transitStatus: String?
    /// A brief description explaining the reason for the current transitStatus, such as "Thunderstorms".
    public var transitStatusReason: String?
    /// The passenger's name.
    public var passengerName: PassPersonNameComponents?
    /// The name of a frequent flyer or loyalty program.
    public var membershipProgramName: String?
    /// The ticketed passenger's frequent flyer or loyalty number.
    public var membershipProgramNumber: String?
    /// The priority status held by the ticketed passenger, such as "Gold" or "Silver".
    public var priorityStatus: String?
    /// The type of security screening that the ticketed passenger will be subject to, such as "Priority".
    public var securityScreening: String?
    
    // MARK: - Semantics for Airline Boarding Passes
    
    /// The IATA flight code, such as "EX123".
    public var flightCode: String?
    /// The IATA airline code, such as "EX" for flightCode "EX123".
    public var airlineCode: String?
    /// The numeric portion of the IATA flightCode, such as 123 for flightCode "EX123".
    public var flightNumber: String?
    /// The IATA airport code for the departure airport, such as "SFO" or "SJC".
    public var departureAirportCode: String?
    /// The full name of the departure airport, such as "San Francisco International Airport".
    public var departureAirportName: String?
    /// The terminal name or letter of the departure terminal, such as "A". Do not include the word "Terminal".
    public var departureTerminal: String?
    /// The gate number or letters of the departure gate, such as "1A". Do not include the word "Gate".
    public var departureGate: String?
    /// The IATA airport code for the destination airport, such as "SFO" or "SJC".
    public var destinationAirportCode: String?
    /// The full name of the destination airport, such as "San Francisco International Airport".
    public var destinationAirportName: String?
    /// The terminal name or letter of the destination terminal, such as "A". Do not include the word "Terminal".
    public var destinationTerminal: String?
    /// The gate number or letters of the destination gate, such as "1A". Do not include the word "Gate".
    public var destinationGate: String?
    
    // MARK: - Semantics for Train and Other Rail Boarding Passes
    
    /// The name of the departure platform, such as "A". Do not include the word "Platform".
    public var departurePlatform: String?
    /// The name of the departure station, such as "1st Street Station".
    public var departureStationName: String?
    /// The name of the destination platform, such as "A". Do not include the word "Platform".
    public var destinationPlatform: String?
    /// The name of the destination station, such as "1st Street Station".
    public var destinationStationName: String?
    /// The car number.
    public var carNumber: String?
    
    // MARK: - Semantics for All Event Tickets
    
    /// The full name for the event, such as the title of a movie.
    public var eventName: String?
    /// The full name of the venue.
    public var venueName: String?
    /// The geographic coordinates of the venue.
    public var venueLocation: PassLocation?
    /// The full name of the entrance to use to gain access to the ticketed event, such as "Gate A".
    public var venueEntrance: String?
    /// The phone number for enquiries about the venue's ticketed event.
    public var venuePhoneNumber: String?
    /// The full name of the room where the ticketed event is taking place.
    public var venueRoom: String?
    /// The event type.
    public var eventType: PassEventType?
    /// The date and time the event starts.
    public var eventStartDate: Date?
    /// The date and time the event ends.
    public var eventEndDate: Date?
    /// The Adam IDs for the artists performing, in decreasing order of significance.
    public var artistIDs: [String]?
    /// The full names of the performers and opening acts, in decreasing order of significance.
    public var performerNames: [String]?
    /// The genre of the performance.
    public var genre: String?
    
    // MARK: - Semantics for Sports Event Tickets
    
    /// The unabbreviated league name for a sporting event.
    public var leagueName: String?
    /// The abbreviated league name for a sporting event.
    public var leagueAbbreviation: String?
    /// The home location of the home team.
    public var homeTeamLocation: String?
    /// The name of the home team.
    public var homeTeamName: String?
    /// The unique abbreviation of the home team's name.
    public var homeTeamAbbreviation: String?
    /// The home location of the away team.
    public var awayTeamLocation: String?
    /// The name of the away team.
    public var awayTeamName: String?
    /// The unique abbreviation of the away team's name.
    public var awayTeamAbbreviation: String?
    /// The commonly used local name of the sport.
    public var sportName: String?
    
    // MARK: - Semantics for Store Card Passes
    
    /// The balance redeemable with the pass.
    public var balance: PassCurrencyAmount?
    
    public init(totalPrice: PassCurrencyAmount? = nil, duration: PassValue? = nil, seats: [PassSeat]? = nil, silenceRequested: Bool? = nil, departureLocation: PassLocation? = nil, departureLocationDescription: String? = nil, destinationLocation: PassLocation? = nil, destinationLocationDescription: String? = nil, transitProvider: String? = nil, vehicleName: String? = nil, vehicleNumber: String? = nil, vehicleType: String? = nil, originalDepartureDate: Date? = nil, currentDepartureDate: Date? = nil, originalArrivalDate: Date? = nil, currentArrivalDate: Date? = nil, originalBoardingDate: Date? = nil, currentBoardingDate: Date? = nil, boardingGroup: String? = nil, boardingSequenceNumber: String? = nil, confirmationNumber: String? = nil, transitStatus: String? = nil, transitStatusReason: String? = nil, passengerName: PassPersonNameComponents? = nil, membershipProgramName: String? = nil, membershipProgramNumber: String? = nil, priorityStatus: String? = nil, securityScreening: String? = nil, flightCode: String? = nil, airlineCode: String? = nil, flightNumber: String? = nil, departureAirportCode: String? = nil, departureAirportName: String? = nil, departureTerminal: String? = nil, departureGate: String? = nil, destinationAirportCode: String? = nil, destinationAirportName: String? = nil, destinationTerminal: String? = nil, destinationGate: String? = nil, departurePlatform: String? = nil, departureStationName: String? = nil, destinationPlatform: String? = nil, destinationStationName: String? = nil, carNumber: String? = nil, eventName: String? = nil, venueName: String? = nil, venueLocation: PassLocation? = nil, venueEntrance: String? = nil, venuePhoneNumber: String? = nil, venueRoom: String? = nil, eventType: PassEventType? = nil, eventStartDate: Date? = nil, eventEndDate: Date? = nil, artistIDs: [String]? = nil, performerNames: [String]? = nil, genre: String? = nil, leagueName: String? = nil, leagueAbbreviation: String? = nil, homeTeamLocation: String? = nil, homeTeamName: String? = nil, homeTeamAbbreviation: String? = nil, awayTeamLocation: String? = nil, awayTeamName: String? = nil, awayTeamAbbreviation: String? = nil, sportName: String? = nil, balance: PassCurrencyAmount? = nil) {
        self.totalPrice = totalPrice
        self.duration = duration
        self.seats = seats
        self.silenceRequested = silenceRequested
        self.departureLocation = departureLocation
        self.departureLocationDescription = departureLocationDescription
        self.destinationLocation = destinationLocation
        self.destinationLocationDescription = destinationLocationDescription
        self.transitProvider = transitProvider
        self.vehicleName = vehicleName
        self.vehicleNumber = vehicleNumber
        self.vehicleType = vehicleType
        self.originalDepartureDate = originalDepartureDate
        self.currentDepartureDate = currentDepartureDate
        self.originalArrivalDate = originalArrivalDate
        self.currentArrivalDate = currentArrivalDate
        self.originalBoardingDate = originalBoardingDate
        self.currentBoardingDate = currentBoardingDate
        self.boardingGroup = boardingGroup
        self.boardingSequenceNumber = boardingSequenceNumber
        self.confirmationNumber = confirmationNumber
        self.transitStatus = transitStatus
        self.transitStatusReason = transitStatusReason
        self.passengerName = passengerName
        self.membershipProgramName = membershipProgramName
        self.membershipProgramNumber = membershipProgramNumber
        self.priorityStatus = priorityStatus
        self.securityScreening = securityScreening
        self.flightCode = flightCode
        self.airlineCode = airlineCode
        self.flightNumber = flightNumber
        self.departureAirportCode = departureAirportCode
        self.departureAirportName = departureAirportName
        self.departureTerminal = departureTerminal
        self.departureGate = departureGate
        self.destinationAirportCode = destinationAirportCode
        self.destinationAirportName = destinationAirportName
        self.destinationTerminal = destinationTerminal
        self.destinationGate = destinationGate
        self.departurePlatform = departurePlatform
        self.departureStationName = departureStationName
        self.destinationPlatform = destinationPlatform
        self.destinationStationName = destinationStationName
        self.carNumber = carNumber
        self.eventName = eventName
        self.venueName = venueName
        self.venueLocation = venueLocation
        self.venueEntrance = venueEntrance
        self.venuePhoneNumber = venuePhoneNumber
        self.venueRoom = venueRoom
        self.eventType = eventType
        self.eventStartDate = eventStartDate
        self.eventEndDate = eventEndDate
        self.artistIDs = artistIDs
        self.performerNames = performerNames
        self.genre = genre
        self.leagueName = leagueName
        self.leagueAbbreviation = leagueAbbreviation
        self.homeTeamLocation = homeTeamLocation
        self.homeTeamName = homeTeamName
        self.homeTeamAbbreviation = homeTeamAbbreviation
        self.awayTeamLocation = awayTeamLocation
        self.awayTeamName = awayTeamName
        self.awayTeamAbbreviation = awayTeamAbbreviation
        self.sportName = sportName
        self.balance = balance
    }
}
