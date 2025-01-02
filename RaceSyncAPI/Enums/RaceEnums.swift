//
//  RaceEnums.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2019-12-22.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import Foundation

public enum RaceType: String, EnumTitle {
    case normal = "1"
    case qualifier = "2"
    case final = "3"

    public var title: String {
        switch self {
        case .normal:       return "Normal"
        case .qualifier:    return "Qualifiers"
        case .final:        return "Championship"
        }
    }
}

//STATUSES = array(0=>'Open', 1=>'Closed')
public enum RaceStatus: String, EnumTitle {
    case open = "0"
    case closed = "1"

    public var title: String {
        switch self {
        case .open:         return "Open"
        case .closed:       return "Closed"
        }
    }
}


//TYPES = array(1=>'Public Event', 0=>'Private Event')
public enum EventType: String, EnumTitle {
    case `public` = "1"
    case `private` = "0"

    public var title: String {
        switch self {
        case .public:       return "Public Event"
        case .private:      return "Private Event"
        }
    }
}

//OFFICIAL_STATUSES = array(0=>'Normal', 1=>'Requested', 2=>'Official')
public enum RaceOfficialStatus: String {
    case normal = "0"
    case requested = "1"
    case approved = "2"

    public var title: String {
        switch self {
        case .normal:       return "Normal"
        case .requested:    return "Requested"
        case .approved:     return "Official"
        }
    }
}

//SCORING_FORMATS = array(0=>'Aggregate Laps', 1=>'Fastest Lap', 6=>'Fastest 2 Consecutive Laps', 2=>'Fastest 3 Consecutive Laps')
public enum ScoringFormat: String, EnumTitle {
    case aggregateLap = "0"
    case fastestLap = "1"
    case fastest2Laps = "6"
    case fastest3Laps = "2"

    public var title: String {
        switch self {
        case .aggregateLap:     return "Aggregate Laps"
        case .fastestLap:       return "Fastest Lap"
        case .fastest2Laps:     return "Fastest 2 Consecutive Laps"
        case .fastest3Laps:     return "Fastest 3 Consecutive Laps"
        }
    }
}

//See https://github.com/MultiGP/multigp-com/blob/main/public_html/mgp/protected/modules/multigp/models/Race.php#L114-L122
// TODO: Pull these values from the server instead of hardcoding them on the app, since they may change depending on agreements
public enum RaceClass: String, EnumTitle {
    case open = "0"
    case whoop = "1"
    case micro = "2"
    case freedom = "3"
    case `spec7in` = "4"
    case mega = "5"
    case esport = "6"
    case `spec5in` = "7"
    case prospec = "8"

    public var title: String {
        switch self {
        case .open:         return "Open"
        case .whoop:        return "Whoop"
        case .micro:        return "Micro"
        case .freedom:      return "Freedom Spec"
        case .spec7in:      return "7 Inch Spec"
        case .mega:         return "Mega"
        case .esport:       return "E-Sport class"
        case .spec5in:      return "5 Inch Spec"
        case .prospec:      return "Pro Spec"
        }
    }
}

// QUALIFYING_TYPES = array(0 => "Controlled Qualifying/Practice", 1 => "Open ZippyQ/Qualifying/Practice" )
public enum QualifyingType: String, EnumTitle {
    case controlled = "0"
    case open = "1"

    public var title: String {
        switch self {
        case .controlled:   return "Controlled Qualifying"
        case .open:         return "Open ZippyQ"
        }
    }
}
