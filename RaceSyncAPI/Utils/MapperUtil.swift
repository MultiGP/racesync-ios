//
//  MapperUtil.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2019-12-18.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import Foundation
import ObjectMapper

public class MapperUtil {

    public static let dateTransform = TransformOf<Date, String>(fromJSON: { (value: String?) -> Date? in
        guard let value = value else { return nil }
        return DateUtil.deserializeJSONDate(value)
    }) { (_: Date?) -> String? in
        return nil
    }

    public static let stringTransform = TransformOf<String, String>(fromJSON: { (value: String?) -> String? in
        guard let value = value else { return nil }
        return value.stringByDecodingHTMLEntities
    }) { (_: String?) -> String? in
        return nil
    }

    public static let doubleTransform = TransformOf<Double, String>(
        fromJSON: { value in
            guard let value = value else { return nil }
            return Double(value)
        },
        toJSON: { _ in nil }
    )

    public static let doubleArrayTransform = TransformOf<[Double], [Any]>(
        fromJSON: { $0?.compactMap { Double(String(describing: $0)) } ?? [] },
        toJSON: { $0 }
    )
}
