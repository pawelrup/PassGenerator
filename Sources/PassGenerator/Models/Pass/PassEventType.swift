//
//  File.swift
//  
//
//  Created by Pawel Rup on 24/11/2019.
//

import Foundation

/// The event type.
public enum PassEventType: String, Codable {
    case generic = "PKEventTypeGeneric"
    case livePerformance = "PKEventTypeLivePerformance"
    case movie = "PKEventTypeMovie"
    case sports = "PKEventTypeSports"
    case conference = "PKEventTypeConference"
    case convention = "PKEventTypeConvention"
    case workshop = "PKEventTypeWorkshop"
    case socialGathering = "PKEventTypeSocialGathering"
}
