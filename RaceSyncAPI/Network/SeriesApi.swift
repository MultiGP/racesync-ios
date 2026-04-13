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

    func approve(series seriesId: ObjectId, raceId: ObjectId,
                        completion: @escaping StatusCompletionBlock)

    func unapprove(series seriesId: ObjectId, raceId: ObjectId,
                              completion: @escaping StatusCompletionBlock)

    func join(series seriesId: ObjectId, with raceId: ObjectId,
              completion: @escaping StatusCompletionBlock)

    func leave(series seriesId: ObjectId, with raceId: ObjectId,
              completion: @escaping StatusCompletionBlock)

    func remove(race raceId: ObjectId, from seriesId: ObjectId,
              completion: @escaping StatusCompletionBlock)
}

public class SeriesApi: SeriesApiInterface {

    public init() {}
    fileprivate let repositoryAdapter = RepositoryAdapter()

    public func getSeries(_ currentPage: Int = 0, pageSize: Int = StandardPageSize, _ completion: @escaping ObjectCompletionBlock<[Series]>) {

        let endpoint = EndPoint.seriesList
        repositoryAdapter.getObjects(endpoint, currentPage: currentPage, pageSize: pageSize, type: Series.self, completion)
    }

    public func view(series seriesId: ObjectId, completion: @escaping ObjectCompletionBlock<Series>) {

        let endpoint = "\(EndPoint.seriesView)?\(ParamKey.id)=\(seriesId)"
        repositoryAdapter.getObject(endpoint, type: Series.self, completion)
    }

    public func approve(series seriesId: ObjectId, raceId: ObjectId, completion: @escaping StatusCompletionBlock) {
        performSeriesAction(with: EndPoint.seriesApprove, seriesId: seriesId, raceId: raceId, completion: completion)
    }

    public func unapprove(series seriesId: ObjectId, raceId: ObjectId, completion: @escaping StatusCompletionBlock) {
        performSeriesAction(with: EndPoint.seriesUnapprove, seriesId: seriesId, raceId: raceId, completion: completion)
    }

    public func join(series seriesId: ObjectId, with raceId: ObjectId, completion: @escaping StatusCompletionBlock) {
        performSeriesAction(with: EndPoint.seriesJoin, seriesId: seriesId, raceId: raceId, completion: completion)
    }

    public func leave(series seriesId: ObjectId, with raceId: ObjectId, completion: @escaping StatusCompletionBlock) {
        performSeriesAction(with: EndPoint.seriesLeave, seriesId: seriesId, raceId: raceId, completion: completion)
    }

    public func remove(race raceId: ObjectId, from seriesId: ObjectId, completion: @escaping StatusCompletionBlock) {
        performSeriesAction(with: EndPoint.seriesRemove, seriesId: seriesId, raceId: raceId, completion: completion)
    }

    private func performSeriesAction(with endpoint: String, seriesId: ObjectId, raceId: ObjectId, completion: @escaping StatusCompletionBlock) {

        let endpoint = "\(endpoint)?\(ParamKey.id)=\(seriesId)"
        let parameters: Params = [ParamKey.raceId: raceId]
        repositoryAdapter.performAction(endpoint, parameters: parameters, completion: completion)
    }
}
