//
//  EventApi.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero on 2026-05-18.
//  Copyright © 2026 MultiGP Inc. All rights reserved.
//

import Foundation
import ObjectMapper

// MARK: - Interface
public protocol EventApiInterface {

    /**
     */
    func getIO26Event(_ completion: @escaping ObjectCompletionBlock<Event>)
}

public class EventApi: EventApiInterface {
    
    public init() {}
    
    public func getIO26Event(_ completion: @escaping ObjectCompletionBlock<Event>) {
        
        // Return cache immediately if available
        if let cached = EventStore.shared.load() {
            completion(cached, nil)
            
#if DEBUG
            return
#endif
        }

        let url = URL(string: "https://script.google.com/macros/s/AKfycbwxgL-ib1uq1EMyfkjrpvmdoMSxzKGG5x--MV4GAMExkM3UEV5FHovTM_UKbTtALQBj/exec")!

        // Always fetch from network and overwrite cache
        fetchEvent(from: url) { result in
            DispatchQueue.main.async {
                var log = "+ Ended request with "

                switch result {
                case .success(let json):
                    let model = Mapper<Event>().map(JSONObject: json)
                    log += "\(model?.name ?? "")"
                    if let model { EventStore.shared.save(model) }
                    completion(model, nil)

                case .failure(let error):
                    let err = error as NSError
                    log += " Network Error: \(err.debugDescription)"
                    completion(nil, err)
                }

                Clog.log(log)
            }
        }
    }
}

extension EventApi {

    fileprivate func fetchEvent(from url: URL, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        
        Clog.log("Starting request \(String(describing: url))")

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                return completion(.failure(error))
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return completion(.failure(NSError(domain: "InvalidData", code: 0)))
            }

            completion(.success(json))

        }.resume()
    }
}
