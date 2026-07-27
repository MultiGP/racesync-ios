//
//  ZippyqApi.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero on 2026-07-27.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import Foundation
import ObjectMapper

public typealias ZippyqRevisionHash = String

public protocol ZippyqApiInterface {
    
    func getQueues(for raceId: ObjectId, completion: @escaping ObjectCompletionBlock<ZippyqResponse>)
    
    func getRevision(for raceId: ObjectId,
                     revision: ZippyqRevisionHash,
                     completion: @escaping ObjectCompletionBlock<ZippyqRevision>)
    
    func addPilot(to raceId: ObjectId,
                  pilotId: ObjectId,
                  slot: Int?,
                  cycle: Int?,
                  heat: Int?,
                  completion: @escaping ObjectCompletionBlock<ZippyqResponse>)
    
    func removePilot(from raceId: ObjectId,
                     pilotId: ObjectId,
                     slot: Int?,
                     cycle: Int?,
                     heat: Int?,
                     completion: @escaping ObjectCompletionBlock<ZippyqResponse>)
}

public class ZippyqApi: ZippyqApiInterface {

    fileprivate let repositoryAdapter = RepositoryAdapter()

    public init() {}

    public func getQueues(for raceId: ObjectId, completion: @escaping ObjectCompletionBlock<ZippyqResponse>) {
        let endpoint = "\(EndPoint.zippyQList)?\(ParamKey.raceId)=\(raceId)"
        repositoryAdapter.getObject(endpoint, type: ZippyqResponse.self, keyPath: nil, completion)
    }

    public func getRevision(for raceId: ObjectId,
                            revision: ZippyqRevisionHash,
                            completion: @escaping ObjectCompletionBlock<ZippyqRevision>) {
        let endpoint = "\(EndPoint.zippyQRevision)?\(ParamKey.raceId)=\(raceId)"
        repositoryAdapter.getObject(endpoint, type: ZippyqRevision.self, completion)
    }

    public func addPilot(to raceId: ObjectId,
                         pilotId: ObjectId,
                         slot: Int? = nil,
                         cycle: Int? = nil,
                         heat: Int? = nil,
                         completion: @escaping ObjectCompletionBlock<ZippyqResponse>) {
        performPilotAction(EndPoint.zippyQAddPilot, raceId: raceId, pilotId: pilotId,
                           slot: slot, cycle: cycle, heat: heat, completion: completion)
    }

    public func removePilot(from raceId: ObjectId,
                            pilotId: ObjectId,
                            slot: Int? = nil,
                            cycle: Int? = nil,
                            heat: Int? = nil,
                            completion: @escaping ObjectCompletionBlock<ZippyqResponse>) {
        performPilotAction(EndPoint.zippyQRemovePilot, raceId: raceId, pilotId: pilotId,
                           slot: slot, cycle: cycle, heat: heat, completion: completion)
    }
}

fileprivate extension ZippyqApi {

    func performPilotAction(_ endpoint: String,
                            raceId: ObjectId,
                            pilotId: ObjectId,
                            slot: Int?,
                            cycle: Int?,
                            heat: Int?,
                            completion: @escaping ObjectCompletionBlock<ZippyqResponse>) {
        
        var params: Params = [ParamKey.raceId: raceId]
        if let slot { params[ParamKey.slot] = slot }
        if let cycle { params[ParamKey.cycle] = cycle }
        if let heat { params[ParamKey.heat] = heat }

        let endpoint = "\(endpoint)?\(ParamKey.pilotId)=\(pilotId)"
        repositoryAdapter.getObject(endpoint, parameters: params, type: ZippyqResponse.self, keyPath: nil, completion)
    }
}
