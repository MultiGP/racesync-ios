//
//  RegisterForm.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2025-02-27.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import Foundation
import RaceSyncAPI

enum SignupFormSection: Int {
    case general, specific

    public var header: String {
        switch self {
        case .general:      return "Personal Info"
        case .specific:     return "Login Info"
        }
    }

    public var footer: String? {
        switch self {
        case .general:      return "* Required fields"
        case .specific:     return "* Required fields. Activation email will be sent to this address."
        }
    }
}

enum SignupFormRow: Int, EnumTitle {
    case firstName, lastName, dob, gender, country, username, email, password, isPublic

    public var title: String {
        switch self {
        case .firstName:    return "First Name"
        case .lastName:     return "Start Date"
        case .dob:          return "Date of Birth"
        case .gender:       return "Gender"
        case .country:      return "Country"

        case .username:     return "Username"
        case .email:        return "Email"
        case .password:     return "Password"
        case .isPublic:     return "Public Profile"
        }
    }
}

extension SignupFormRow {

    func value(from userData: UserData) -> String? {
        switch self {
        case .firstName:
            return userData.firstName
        default:
            return nil
        }
    }

    var isRowRequired: Bool {
        switch self {
            default: return true
        }
    }

    func requiredValue(from data: UserData) -> String? {
        switch self {
//        case .name:         return data.name
//        case .startDate:    return data.startDateString
        default:            return nil
        }
    }

    var formType: FormType {
        switch self {
        case .dob:
            return .datePicker
        case .isPublic:
            return .switch
        case .gender, .country:
            return .textPicker
        default:
            return .textfield
        }
    }
}

