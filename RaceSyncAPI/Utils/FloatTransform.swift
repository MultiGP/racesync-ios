//
//  FloatTransform.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2025-08-07.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import Foundation
import ObjectMapper

public class FloatTransform: TransformType {

    public typealias Object = Float32
    public typealias JSON = String

    init() {}
    public func transformFromJSON(_ value: Any?) -> Float32? {
        if let strValue = value as? String {
            return Float32(strValue)
        }
        return value as? Float32 ?? nil
    }

    public func transformToJSON(_ value: Float32?) -> String? {
        if let intValue = value {
            return "\(intValue)"
        }
        return nil
    }
}

