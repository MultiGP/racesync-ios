//
//  StandingApi.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2025-05-30.
//  Copyright © 2025 MultiGP Inc. All rights reserved.
//

import Foundation
import ObjectMapper

// MARK: - Interface
public protocol StandingApiInterface {

    /**
     */
    func getStandings(for season: StandingSeason, _ completion: @escaping ObjectCompletionBlock<[Standing]>)
}

public class StandingApi: StandingApiInterface {

    public init() {}

    public func getStandings(for season: StandingSeason, _ completion: @escaping ObjectCompletionBlock<[Standing]>) {

        guard let baseUrl = Self.getStandingsUrl(for: season) else { return }

        // This is too fragile but no choice for now
        var headers = ["position", "firstName", "userName", "lastName", "userId", "chapterName",
                       "email", "country", "season1", "season1Score"]

        if season == .y2024 || season == .y2025 {
            headers += ["season2", "season2Score"]
        }

        fetchStandings(from: baseUrl) { result in
            DispatchQueue.main.async {
                var log: String = "+ Ended request with "

                switch result {
                    case .success(let jsonArray):
                        let models = Mapper<Standing>().mapArray(JSONArray: jsonArray)
                        log += "(\(models.count) objects)"
                        completion(models, nil)

                    case .failure(let error):
                        let err = error as NSError
                        log += " Network Error: \(err.debugDescription)"
                        completion(nil, err)
                    }

                Clog.log("\(log)")
            }
        }
    }
}

extension StandingApi {

    fileprivate func fetchStandings(from url: URL, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        Clog.log("Starting request \(String(describing: url))")

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                return completion(.failure(error))
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                return completion(.failure(NSError(domain: "InvalidData", code: 0)))
            }

            completion(.success(json))

        }.resume()
    }

    static func getStandingsUrl(for season: StandingSeason) -> URL? {
        let baseUrl = MGPWeb.getURL(for: .viewZipperSeasonResults)

        var params = [(String, String)]()

        if season == .y2024 || season == .y2025 {
            params += [
                ("season1", "\(season.rawValue)Summer"),
                ("season2", "\(season.rawValue)Spring")
            ]
        } else {
            params += [
                ("season1", "\(season.rawValue)")
            ]
        }

        params += [("exportjson", "true")]

        var components = URLComponents(string: baseUrl.absoluteString)
        components?.queryItems = params.map { URLQueryItem(name: $0.0, value: $0.1) }

        return components?.url
    }
}
