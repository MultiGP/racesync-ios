//
//  SeriesApi.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2025-09-25.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

// MARK: - Interface

public protocol SeriesApiInterface {

    func getSeries(_ currentPage: Int, pageSize: Int, _ completion: @escaping ObjectCompletionBlock<[Series]>)

    func view(series seriesId: ObjectId,
              completion: @escaping ObjectCompletionBlock<Series>)
}

public class SeriesApi: SeriesApiInterface {

    public init() {}
    fileprivate let repositoryAdapter = RepositoryAdapter()

    public func getSeries(_ currentPage: Int = 0, pageSize: Int = StandardPageSize, _ completion: @escaping ObjectCompletionBlock<[Series]>) {

        let endpoint = EndPoint.seriesList
        var parameters: Params = [:]

        repositoryAdapter.getObjects(endpoint, parameters: parameters, currentPage: currentPage, pageSize: pageSize, type: Series.self, completion)
    }

    public func view(series seriesId: ObjectId, completion: @escaping ObjectCompletionBlock<Series>) {

        let endpoint = "\(EndPoint.seriesView)?\(ParamKey.id)=\(seriesId)"

        repositoryAdapter.getObject(endpoint, type: Series.self, completion)
    }
}
