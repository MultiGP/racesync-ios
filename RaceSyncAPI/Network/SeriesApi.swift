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

    func remove(series seriesId: ObjectId, raceId: ObjectId,
              completion: @escaping StatusCompletionBlock)
}

public class SeriesApi: SeriesApiInterface {

    public init() {}
    fileprivate let repositoryAdapter = RepositoryAdapter()

    public func getSeries(_ currentPage: Int = 0, pageSize: Int = StandardPageSize, _ completion: @escaping ObjectCompletionBlock<[Series]>) {

        let endpoint = EndPoint.seriesList
        let parameters: Params = [:]
        repositoryAdapter.getObjects(endpoint, parameters: parameters, currentPage: currentPage, pageSize: pageSize, type: Series.self, completion)
    }

    public func view(series seriesId: ObjectId, completion: @escaping ObjectCompletionBlock<Series>) {

        let endpoint = "\(EndPoint.seriesView)?\(ParamKey.id)=\(seriesId)"
        repositoryAdapter.getObject(endpoint, type: Series.self, completion)
    }

    public func approve(series seriesId: ObjectId, raceId: ObjectId, completion: @escaping StatusCompletionBlock) {

        let endpoint = "\(EndPoint.seriesApprove)?\(ParamKey.id)=\(seriesId)"
        let parameters: Params = [ParamKey.raceId: raceId]
        repositoryAdapter.performAction(endpoint, parameters: parameters, completion: completion)
    }

    public func unapprove(series seriesId: ObjectId, raceId: ObjectId, completion: @escaping StatusCompletionBlock) {

        let endpoint = "\(EndPoint.seriesUnapprove)?\(ParamKey.id)=\(seriesId)"
        let parameters: Params = [ParamKey.raceId: raceId]
        repositoryAdapter.performAction(endpoint, parameters: parameters, completion: completion)
    }

    public func remove(series seriesId: ObjectId, raceId: ObjectId, completion: @escaping StatusCompletionBlock) {

        let endpoint = "\(EndPoint.seriesRemove)?\(ParamKey.id)=\(seriesId)"
        let parameters: Params = [ParamKey.raceId: raceId]
        repositoryAdapter.performAction(endpoint, parameters: parameters, completion: completion)
    }
}
