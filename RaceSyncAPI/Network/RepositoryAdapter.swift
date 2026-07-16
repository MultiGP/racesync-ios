//
//  RepositoryAdapter.swift
//  RaceSyncAPI
//
//  Created by Ignacio Romero Zurbuchen on 2019-11-24.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import Alamofire
import AlamofireObjectMapper
import ObjectMapper
import SwiftyJSON

class RepositoryAdapter {

    let networkAdapter = NetworkAdapter(serverUri: MGPWeb.getUrl(for: .apiBase))
    private static let responseQueue = DispatchQueue(label: "com.multigp.racesync.repository.response", qos: .userInitiated, attributes: .concurrent)

    func getObject<Element: Mappable>(_ endPoint: String, parameters: Params? = nil, type: Element.Type, keyPath: String = ParamKey.data, _ completion: @escaping ObjectCompletionBlock<Element>) {
        
        networkAdapter.httpRequest(endPoint, method: .post, parameters: parameters) { (request) in
            Clog.log("Starting request \(String(describing: request.request?.url)) with parameters \(String(describing: parameters))")
            request.responseObject(queue: Self.responseQueue, keyPath: keyPath, completionHandler: { (response: DataResponse<Element>) in
                Clog.log("Ended request with code \(String(describing: response.response?.statusCode))")

                if let response = response.response {
                    if response.statusCode == 401 {
                        Clog.log("Detected 401. Should log out User!")
                    }
                }

                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    if let errors = ErrorUtil.errors(fromJSON: json) {
                        Self.completeOnMain(completion, object: nil, error: errors.first)
                    } else {
                        Self.completeOnMain(completion, object: value, error: nil)
                    }
                case .failure:
                    let error = ErrorUtil.parseError(response)
                    Clog.log("Network error \(error.debugDescription)")
                    Self.completeOnMain(completion, object: nil, error: error)
                }
            })
        }
    }

    func getObjects<Element: Mappable>(_ endPoint: String, parameters: Params? = nil, currentPage: Int = 0, pageSize: Int = StandardPageSize, skipPagination: Bool = false, type: Element.Type, keyPath: String = ParamKey.data, _ completion: @escaping ObjectCompletionBlock<[Element]>) {

        var finalEndpoint = endPoint

        // only include pagination if required
        if !skipPagination {
            finalEndpoint = "\(endPoint)?\(ParamKey.currentPage)=\(currentPage)&\(ParamKey.pageSize)=\(pageSize)"
        }

        networkAdapter.httpRequest(finalEndpoint, method: .post, parameters: parameters) { (request) in
            Clog.log("Starting request \(String(describing: request.request?.url)) with parameters \(String(describing: parameters))")
            request.responseArray(queue: Self.responseQueue, keyPath: keyPath, completionHandler: { (response: DataResponse<[Element]>) in
                var log: String = "+ Ended request with code \(String(describing: response.response?.statusCode)) "

                if let code = response.response?.statusCode, code == 401 {
                    Clog.log("Detected 401. Should log out User!")
                }

                // patch for when lists are empty
                switch response.value {
                case .none:
                    log += "(0 objects)"
                    Self.completeOnMain(completion, object: [], error: nil)
                    Clog.log("\(log)")
                    return
                default:
                    break
                }

                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    if let errors = ErrorUtil.errors(fromJSON: json) {
                        Self.completeOnMain(completion, object: nil, error: errors.first)
                        log += " Network Error: \(errors.first.debugDescription)"
                    } else {
                        Self.completeOnMain(completion, object: value, error: nil)
                        log += "(\(value.count) objects)"
                    }
                case .failure:
                    let error = ErrorUtil.parseError(response)
                    Self.completeOnMain(completion, object: nil, error: error)
                    log += " Network Error: \(error.debugDescription)"
                }

                Clog.log("\(log)")
            })
        }
    }

    func performAction(_ endPoint: String, parameters: Params? = nil, completion: @escaping StatusCompletionBlock) {
        networkAdapter.httpRequest(endPoint,  method: .post, parameters: parameters) { (request) in
            Clog.log("Starting request \(String(describing: request.request?.url)) with parameters \(String(describing: parameters))")
            request.responseJSON(queue: Self.responseQueue) { (response) in
                Clog.log("Ended request with code \(String(describing: response.response?.statusCode))")

                if let code = response.response?.statusCode, code == 401 {
                    Clog.log("Detected 401. Should log out User!")
                }

                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    if let errors = ErrorUtil.errors(fromJSON: json) {
                        Self.completeOnMain(completion, status: false, error: errors.first)
                    } else {
                        Self.completeOnMain(completion, status: json[ParamKey.status].bool ?? false, error: nil)
                    }
                case .failure:
                    Self.completeOnMain(completion, status: false, error: response.error as NSError?)
                }
            }
        }
    }

    func uploadImage(_ data: Data, name: String, url: String, progressBlock: ProgressBlock?, _ completion: @escaping ObjectCompletionBlock<String>) {
        Clog.log("Starting request \(url)")

        // Multipart
        networkAdapter.httpMultipartUpload(data, name: name, url: url) { (result) in
            switch result {
            case .success(let upload, _, _):

                upload.uploadProgress(closure: { (progress) in
                    print("Upload Progress: \(progress.fractionCompleted)")
                })

                upload.responseString { response in
                    var log: String = "+ Ended request with code \(String(describing: response.response?.statusCode)) "

                    switch response.result {
                    case .success(let value):
                        let json = JSON.init(parseJSON: value)
                        if let errors = ErrorUtil.errors(fromJSONString: value) {
                            completion(nil, errors.first)
                        } else {
                            completion(json[ParamKey.url].rawValue as? String, nil)
                        }
                    case .failure:
                        let error = ErrorUtil.parseError(response)
                        log += " Network Error: \(error.debugDescription)"
                        completion(nil, error)
                    }

                    Clog.log("\(log)")
                }

            case .failure(let encodingError):
                Clog.log("encodingError \(encodingError)")
                print(encodingError)
            }
        }
    }
}

private extension RepositoryAdapter {

    static func completeOnMain<Element>(_ completion: @escaping ObjectCompletionBlock<Element>, object: Element?, error: NSError?) {
        DispatchQueue.main.async {
            completion(object, error)
        }
    }

    static func completeOnMain(_ completion: @escaping StatusCompletionBlock, status: Bool, error: NSError?) {
        DispatchQueue.main.async {
            completion(status, error)
        }
    }
}
