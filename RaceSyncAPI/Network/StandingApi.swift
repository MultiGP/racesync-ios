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
    func getStandings(forSeason season: String, _ completion: @escaping ObjectCompletionBlock<[Standing]>)
}

public class StandingApi: StandingApiInterface {


    public init() {}

    public func getStandings(forSeason season: String, _ completion: @escaping ObjectCompletionBlock<[Standing]>) {

        guard let baseUrl = getStandingsUrl(forSeason: season) else { return }

        // This is too fragile but no choice for now
        let headers = ["position", "firstName", "userName", "lastName", "userId", "chapterName",
                       "email", "country", "season1", "season1Score", "season2", "season2Score"]

        fetchCSVAndConvertToJSON(from: baseUrl, knownHeaders: headers) { result in
            switch result {
                case .success(let jsonArray):
                    let models = Mapper<Standing>().mapArray(JSONArray: jsonArray)
                    completion(models, nil)
                case .failure(let error):
                    completion(nil, error as NSError)
                }
        }
    }
}

fileprivate extension StandingApi {

    func fetchCSVAndConvertToJSON(from url: URL, knownHeaders: [String]? = nil, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                return completion(.failure(error))
            }

            guard let data = data,
                  let rawHTML = String(data: data, encoding: .utf8) else {
                return completion(.failure(NSError(domain: "InvalidData", code: 0)))
            }

            let csv = self.extractCleanCSV(from: rawHTML, injectingHeaders: knownHeaders)
            let result = self.parseCSV(csv)
            completion(result)

        }.resume()
    }

    func extractCleanCSV(from html: String, injectingHeaders headers: [String]? = nil) -> String {
        var text = html.stripHTML(false)

        if let range = text.range(of: "\n1,") ?? text.range(of: "1,") {
            text = String(text[range.lowerBound...])
        }

        text = text.replacingOccurrences(of: "[email protected]", with: "")

        if let headers = headers, !headers.isEmpty {
            let headerLine = headers.joined(separator: ",")
            return headerLine + "\n" + text
        }

        return text
    }

    private func parseCSV(_ csv: String) -> Result<[[String: Any]], Error> {
        let lines = csv.components(separatedBy: .newlines).filter { !$0.isEmpty }

        guard let firstLine = lines.first else {
            return .failure(NSError(domain: "NoHeader", code: 0))
        }

        let keys = firstLine.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        var jsonArray: [[String: Any]] = []

        for line in lines.dropFirst() {
            let values = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard values.count == keys.count else { continue }

            let dict = Dictionary(uniqueKeysWithValues: zip(keys, values))
            jsonArray.append(dict)
        }

        return .success(jsonArray)
    }

    func getStandingsUrl(forSeason season: String) -> URL? {

        let baseURLString = MGPWebConstant.viewZipperSeasonResults
        let params: [String: String] = [
            "season1": "\(season)Spring",
            "season2": "\(season)Summer",
            "exportcsv": "true"
        ]

        var components = URLComponents(string: baseURLString.rawValue)
        components?.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }

        return components?.url
    }
}
