//
//  RaceApi.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2019-11-19.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

// MARK: - Interface

public protocol RaceApiInterface {

    /**
     Gets a filtered set of races related to the authenticated User.

     - parameter filters: The list of compounding filters to compose the race query
     - parameter latitude: The coordinate longitude (Optional)
     - parameter longitude: The coordinate longitude (Optional)
     - parameter completion: The closure to be called upon completion. Returns a transcient list of Race objects.
     */
    func getMyRaces(filters: [RaceListFilters],
                    latitude: String?,
                    longitude: String?,
                    completion: @escaping ObjectCompletionBlock<[Race]>)

    /**
    Gets a filtered set of races related to a specific User.

    - parameter filters: The list of compounding filters to compose the race query
    - parameter userId: The User id (Optional)
    - parameter name: The race name. (Optional)
    - parameter startDate: The race start date. This value can be a full date, or month, or year. (Optional)
    - parameter chapterIds: The Chapter's ids. (Optional)
    - parameter seasonId: The Season id the race belongs to. (Optional)
    - parameter raceClass: The race class type. (Optional)
    - parameter latitude: The coordinate longitude (Optional)
    - parameter longitude: The coordinate longitude (Optional)
    - parameter currentPage: The current page cursor position. Default is 0
    - parameter pageSize: The amount of objects to be returned by page. Default is 25.
    - parameter completion: The closure to be called upon completion. Returns a transcient list of Race objects.
    */
    func getRaces(with filters: [RaceListFilters],
                  userId: ObjectId,
                  name: String?,
                  startDate: String?,
                  chapterIds: [ObjectId]?,
                  seasonId: ObjectId?,
                  raceClass: RaceClass?,
                  latitude: String?,
                  longitude: String?,
                  currentPage: Int,
                  pageSize: Int,
                  completion: @escaping ObjectCompletionBlock<[Race]>)

    /**
    Gets a full Race object, including pilot entries and schedule

     - parameter raceId: The Race id.
     - parameter completion: The closure to be called upon completion. Returns a transcient Race object.
    */
    func view(race raceId: ObjectId,
              completion: @escaping ObjectCompletionBlock<Race>)

    /**
    Gets a full Race object, including pilot entries and excluding the schedule

     - parameter raceId: The Race id.
     - parameter completion: The closure to be called upon completion. Returns a transcient Race object.
    */
    func viewSimple(race raceId: ObjectId,
                    completion: @escaping ObjectCompletionBlock<Race>)

    /**
     */
    func join(race raceId: ObjectId,
              aircraftId: ObjectId,
              completion: @escaping StatusCompletionBlock)

    /**
     */
    func resign(race raceId: ObjectId,
                completion: @escaping StatusCompletionBlock)

    /**
    */
    func forceJoin(race raceId: ObjectId,
                   pilotId: ObjectId,
                   completion: @escaping StatusCompletionBlock)

    /**
    */
    func forceResign(race raceId: ObjectId,
                     pilotId: ObjectId,
                     completion: @escaping StatusCompletionBlock)

    /**
     */
    func open(race raceId: ObjectId,
              completion: @escaping StatusCompletionBlock)

    /**
     */
    func close(race raceId: ObjectId,
               completion: @escaping StatusCompletionBlock)

    /**
    */
    func checkIn(race raceId: ObjectId,
                 pilotId: ObjectId?,
                 completion: @escaping ObjectCompletionBlock<RaceEntry>)

    /**
    */
    func checkOut(race raceId: ObjectId,
                  pilotId: ObjectId?,
                  completion: @escaping ObjectCompletionBlock<RaceEntry>)

    /**
    Creates a full Race object, using a data transfer object converted into parameters.

     - parameter data: The data transfer object
     - parameter completion: The closure to be called upon completion. Returns a transcient Race object.
    */
    func createRace(withData data: RaceData,
                    completion: @escaping ObjectCompletionBlock<Race>)

    /**
    */
    func updateRace(race raceId: ObjectId,
                    with beforeData: RaceData?,
                    afterData: RaceData,
                    completion: @escaping ObjectCompletionBlock<Race>)

    /**
    */
    func deleteRace(with raceId: ObjectId,
                    completion: @escaping StatusCompletionBlock)

    /**
    */
    func finalizeRace(with raceId: ObjectId,
                    completion: @escaping StatusCompletionBlock)

    /**
     Cancels all the HTTP requests of race API endpoint
    */
    func cancelAll()
}

public class RaceApi: RaceApiInterface {

    public init() {}

    fileprivate let repositoryAdapter = RepositoryAdapter()

    public func getMyRaces(filters: [RaceListFilters],
                           latitude: String? = nil,
                           longitude: String? = nil,
                           completion: @escaping ObjectCompletionBlock<[Race]>) {
        guard let user = APIServices.shared.myUser else { return }

        let lat = latitude ?? user.latitude
        let long = longitude ?? user.longitude

        getRaces(with: filters, userId: user.id, latitude: lat, longitude: long, completion: completion)
    }

    public func getRaces(with filters: [RaceListFilters] = [RaceListFilters](),
                         userId: ObjectId = "",
                         name: String? = nil,
                         startDate: String? = nil,
                         chapterIds: [ObjectId]? = nil,
                         seasonId: ObjectId? = nil,
                         raceClass: RaceClass? = nil,
                         latitude: String? = nil, longitude: String? = nil,
                         currentPage: Int = 0, pageSize: Int = StandardPageSize,
                         completion: @escaping ObjectCompletionBlock<[Race]>) {

        let endpoint = EndPoint.raceList
        var params = parametersForRaces(with: filters, userId: userId, latitude: latitude, longitude: longitude, pageSize: pageSize)

        if let name = name, name.count > 0 {
            params[ParamKey.name] = name
        }

        if let date = startDate, date.count > 0 {
            params[ParamKey.startDate] = date
        }

        if let chapterIds = chapterIds, chapterIds.count > 0 {
            params[ParamKey.chapterId] = chapterIds
        }

        if let seasonId = seasonId, seasonId.count > 0 {
            params[ParamKey.seasonId] = seasonId
        }

        if let raceClass = raceClass {
            params[ParamKey.raceClass] = raceClass.rawValue
        }

        repositoryAdapter.getObjects(endpoint, parameters: params, currentPage: currentPage, pageSize: pageSize, type: Race.self, completion)
    }

    public func view(race raceId: ObjectId, completion: @escaping ObjectCompletionBlock<Race>) {

        let endpoint = "\(EndPoint.raceView)?\(ParamKey.id)=\(raceId)"

        repositoryAdapter.getObject(endpoint, type: Race.self, completion)
    }

    public func viewSimple(race raceId: ObjectId, completion: @escaping ObjectCompletionBlock<Race>) {

        let endpoint = "\(EndPoint.raceViewSimple)?\(ParamKey.id)=\(raceId)"

        repositoryAdapter.getObject(endpoint, type: Race.self, completion)
    }

    public func join(race raceId: ObjectId, aircraftId: ObjectId, completion: @escaping StatusCompletionBlock) {

        let endpoint = "\(EndPoint.raceJoin)?\(ParamKey.id)=\(raceId)"
        let parameters = [ParamKey.aircraftId: aircraftId]

        repositoryAdapter.performAction(endpoint, parameters: parameters, completion: completion)
    }

    public func resign(race raceId: ObjectId, completion: @escaping StatusCompletionBlock) {
        
        let endpoint = "\(EndPoint.raceResign)?\(ParamKey.id)=\(raceId)"

        repositoryAdapter.performAction(endpoint, completion: completion)
    }

    public func forceJoin(race raceId: ObjectId, pilotId: ObjectId, completion: @escaping StatusCompletionBlock) {

        let endpoint = "\(EndPoint.raceForceJoin)?\(ParamKey.id)=\(raceId)"
        let parameters = [ParamKey.pilotId: pilotId]

        repositoryAdapter.performAction(endpoint, parameters: parameters, completion: completion)
    }

    public func forceResign(race raceId: ObjectId, pilotId: ObjectId, completion: @escaping StatusCompletionBlock) {

        let endpoint = "\(EndPoint.raceResign)?\(ParamKey.id)=\(raceId)"
        let parameters = [ParamKey.pilotId: pilotId]

        repositoryAdapter.performAction(endpoint, parameters: parameters, completion: completion)
    }

    public func open(race raceId: ObjectId, completion: @escaping StatusCompletionBlock) {

        let endpoint = "\(EndPoint.raceOpen)?\(ParamKey.id)=\(raceId)"

        repositoryAdapter.performAction(endpoint, completion: completion)
    }

    public func close(race raceId: ObjectId, completion: @escaping StatusCompletionBlock) {

        let endpoint = "\(EndPoint.raceClose)?\(ParamKey.id)=\(raceId)"

        repositoryAdapter.performAction(endpoint, completion: completion)
    }

    public func checkIn(race raceId: ObjectId, pilotId: ObjectId? = nil, completion: @escaping ObjectCompletionBlock<RaceEntry>) {

        let endpoint = "\(EndPoint.raceCheckIn)?\(ParamKey.id)=\(raceId)"
        var params = Params()
        params[ParamKey.pilotId] = pilotId

        repositoryAdapter.getObject(endpoint, parameters: params, type: RaceEntry.self, completion)
    }

    public func checkOut(race raceId: ObjectId, pilotId: ObjectId? = nil, completion: @escaping ObjectCompletionBlock<RaceEntry>) {

        let endpoint = "\(EndPoint.raceCheckOut)?\(ParamKey.id)=\(raceId)"
        var params = Params()
        params[ParamKey.pilotId] = pilotId

        repositoryAdapter.getObject(endpoint, parameters: params, type: RaceEntry.self, completion)
    }

    public func createRace(withData data: RaceData, completion: @escaping ObjectCompletionBlock<Race>) {

        let endpoint = "\(EndPoint.raceCreate)?\(ParamKey.chapterId)=\(data.chapterId)"
        let params = data.toParams()

        repositoryAdapter.getObject(endpoint, parameters: params, type: Race.self, completion)
    }

    public func updateRace(race raceId: ObjectId, with beforeData: RaceData? = nil, afterData: RaceData, completion: @escaping ObjectCompletionBlock<Race>) {

        let endpoint = "\(EndPoint.raceUpdate)?\(ParamKey.id)=\(raceId)"
        var params = Params()

        if let beforeData = beforeData {
            params = afterData.toDiffParams(beforeData)
        } else {
            params = afterData.toParams()
        }

        repositoryAdapter.getObject(endpoint, parameters: params, type: Race.self, completion)
    }

    public func deleteRace(with raceId: ObjectId, completion: @escaping StatusCompletionBlock) {

        let endpoint = "\(EndPoint.raceDelete)?\(ParamKey.id)=\(raceId)"

        repositoryAdapter.performAction(endpoint, completion: completion)
    }

    public func finalizeRace(with raceId: ObjectId, completion: @escaping StatusCompletionBlock) {

        let endpoint = "\(EndPoint.raceFinalize)?\(ParamKey.id)=\(raceId)"

        repositoryAdapter.performAction(endpoint, completion: completion)
    }

    public func cancelAll() {
        repositoryAdapter.networkAdapter.httpCancelRequests(with: EndPoint.race)
    }
}

fileprivate extension RaceApi {

    func parametersForRaces(with filters: [RaceListFilters],
                            userId: ObjectId = "",
                            latitude: String? = nil, longitude: String? = nil,
                            pageSize: Int = StandardPageSize) -> Params {

        var parameters: Params = [:]

        if filters.contains(.nearby) {
            let settings = APIServices.shared.settings
            let lengthUnit = settings.lengthUnit
            var radiusString = settings.searchRadius

            if lengthUnit == .kilometers {
                radiusString = APIUnitSystem.convert(radiusString, to: .miles)
            }

            var nearbyDict = [ParamKey.radius: radiusString]
            if let lat = latitude { nearbyDict[ParamKey.latitude] = lat }
            if let long = longitude { nearbyDict[ParamKey.longitude] = long }
            parameters[ParamKey.nearBy] = nearbyDict
        }
        else if filters.contains(.joined) {
            parameters[ParamKey.joined] = [ParamKey.pilotId : userId]
        }

        if filters.contains(.series) {
            parameters[ParamKey.isQualifier] = true
        }

        if filters.contains(.upcoming) {
            parameters[ParamKey.upcoming] = [ParamKey.limit: pageSize]
        } else if filters.contains(.past) {
            parameters[ParamKey.past] = [ParamKey.limit: pageSize]
        }

        return parameters
    }
}
