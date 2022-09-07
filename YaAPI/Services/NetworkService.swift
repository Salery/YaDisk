//
//  Service.swift
//  YaAPI
//
//  Created by Devel on 10.07.2022.
//

import Foundation
import Alamofire

final class NetworkService {
    enum encodeTo {
        case httpBody, queryString
    }
    func postRequest<T:Decodable, P:Encodable>(url: String,
                                               token: String? = nil,
                                               method: String = "POST",
                                               parameters: P,
                                               parametersEncodeTo: encodeTo = .httpBody,
                                               headers: HTTPHeaders? = nil,
                                               completion: @escaping (T?, Int?)->Void) {
        let tempURL = URL(string: url) ?? URL(string: "https://yandex.ru")!
        let contentLength = (try? URLEncodedFormParameterEncoder()
            .encode(parameters,into: URLRequest(url: tempURL, method: .post, headers: nil)).httpBody?.count ?? 0) ?? 0
        let method = HTTPMethod(rawValue: method)
        let defaultHeaders = token != nil ? HTTPHeaders([
            "Content-Type" : "application/json",
            "Accept" : "application/json",
            "Authorization" : "OAuth \(token ?? "")"
        ]) : HTTPHeaders([
            "Content-Type" : "application/x-www-form-urlencoded",
            "Content-Length" : contentLength.description
        ])
        let headers = headers != nil ? headers : defaultHeaders
        var encoder: ParameterEncoder
        switch parametersEncodeTo {
        case .httpBody:
            encoder = .urlEncodedForm
        case .queryString:
            encoder = URLEncodedFormParameterEncoder(encoder: URLEncodedFormEncoder(allowedCharacters: .urlHostAllowed), destination: .queryString)
        }
        
        AF.request (url,
                   method: method,
                   parameters: parameters,
                   encoder: encoder,
                    headers: headers) { $0.timeoutInterval = YaConst.requestTimeout }
            .responseDecodable(of: T.self) { response in
            switch response.result {
            case .success(_):
                completion(response.value, nil)
            case .failure(let error):
                print("Request failure (to model: \(T.self):", error.localizedDescription)
                completion(nil, response.response?.statusCode ?? -1)
            }
        }
    }
    
    func getRequest<T:Decodable, P:Encodable>(url: String,
                                              parameters: P,
                                              token: String,
                                              headers: HTTPHeaders? = nil,
                                              completion: @escaping (T?, Int?)->Void) {
        let headers = headers != nil ? headers : HTTPHeaders([
            "Content-Type" : "application/json",
            "Accept" : "application/json",
            "Authorization" : "OAuth \(token)"
        ])
        
        AF.request (url,
                    method: .get,
                    parameters: parameters,
                    encoder: .urlEncodedForm,
                    headers: headers) { $0.timeoutInterval = YaConst.requestTimeout }
                    .responseDecodable (of: T.self, decoder: JSONDecoder()) { response in
            switch response.result {
            case .success(_):
                completion(response.value, nil)
            case .failure(let error):
                print("Request failure (to model: \(T.self):", error.localizedDescription)
                completion(nil, response.response?.statusCode ?? -1)
            }
        }
    }
    
    func download<P:Encodable>(url: String, parameters: P, to: URL,
                               token: String, headers: HTTPHeaders? = nil,
                               progressHandler: @escaping (Progress) -> Void,
                               completion: @escaping (URL?, Int?)->Void) {
        let headers = headers != nil ? headers : HTTPHeaders([
            "Content-Type" : "application/json",
            "Accept" : "application/json",
            "Authorization" : "OAuth \(token)"
        ])
        let to: DownloadRequest.Destination = {temporaryURL,response in
            (to, [.removePreviousFile, .createIntermediateDirectories])
        }
        var downloadRequest: DownloadRequest?
        let progressHandler: (Progress)->Void = { progress in
            progress.cancellationHandler = {
                downloadRequest?.cancel()
            }
            progressHandler(progress)
        }
        
        downloadRequest = AF.download (url,
                                       method: .get,
                                       parameters: parameters,
                                       encoder: .urlEncodedForm,
                                       headers: headers,
                                       requestModifier: { $0.timeoutInterval = YaConst.requestTimeout },
                                       to: to)
            .downloadProgress(queue: .main, closure: progressHandler) // default queue - main
            .responseData { responce in
                if let error = responce.error, responce.response?.statusCode != 200 {
                    print("Responce code: \(String(describing: responce.response?.statusCode))")
                    print("Download from \(url) failed: ", error.localizedDescription)
                }
                completion(responce.fileURL, responce.response?.statusCode)
            }
    }
    
    func delete<P:Encodable>(url: String,
                             parameters: P,
                             token: String,
                             headers: HTTPHeaders? = nil,
                             completion: @escaping (Int)->Void) {
        let headers = headers != nil ? headers : HTTPHeaders([
            "Content-Type" : "application/json",
            "Accept" : "application/json",
            "Authorization" : "OAuth \(token)"
        ])
        
        AF.request (url,
                    method: .delete,
                    parameters: parameters,
                    encoder: .urlEncodedForm,
                    headers: headers) { $0.timeoutInterval = YaConst.requestTimeout }
                    .response { response in
            completion(response.response?.statusCode ?? -1)
            switch response.result {
            case .success(_):
                break
            case .failure(let error):
                print("Request failure: ", error.localizedDescription)
            }
        }
    }
    
//MARK: Delete: func testGetRequest
    func testGetRequest<T:Decodable, P:Encodable>(url: String,
                                              parameters: P,
                                              token: String,
                                              headers: HTTPHeaders? = nil,
                                              completion: @escaping (T?, Int?)->Void) {
        let headers = headers != nil ? headers : HTTPHeaders([
            "Content-Type" : "application/json",
            "Accept" : "application/json",
            "Authorization" : "OAuth \(token)"
        ])
        
        AF.request (url,
                    method: .get,
                    parameters: parameters,
                    encoder: .urlEncodedForm,
                    headers: headers) { $0.timeoutInterval = YaConst.requestTimeout }
                    .responseDecodable (of: T.self, decoder: JSONDecoder()) { response in
            print(response.response as Any)
            //print(String(data: (response.value ?? Data()) ?? Data(), encoding: .utf8) )
//            completion(nil, 500)
            switch response.result {
            case .success(_):
                completion(response.value, nil)
            case .failure(let error):
                print("Request failure (to model: \(T.self):", error.localizedDescription)
                completion(nil, response.response?.statusCode ?? -1)
            }
        }
    }
//MARK: Delete: func testPostRequest
    func testPostRequest<T:Decodable, P:Encodable>(url: String,
                                               token: String? = nil,
                                               parameters: P,
                                               headers: HTTPHeaders? = nil,
                                               completion: @escaping (T?, Int?)->Void) {
        let tempURL = URL(string: url) ?? URL(string: "https://yandex.ru")!
        let contentLength = (try? URLEncodedFormParameterEncoder()
            .encode(parameters,into: URLRequest(url: tempURL, method: .post, headers: nil)).httpBody?.count ?? 0) ?? 0
        let defaultHeaders = token != nil ? HTTPHeaders([
            "Content-Type" : "application/json",
            "Accept" : "application/json",
            "Authorization" : "OAuth \(token ?? "")"
        ]) : HTTPHeaders([
            "Content-Type" : "application/x-www-form-urlencoded",
            "Content-Length" : contentLength.description
        ])
        let headers = HTTPHeaders([
            "Content-Type" : "application/x-www-form-urlencoded",
            "Content-Length" : contentLength.description,
            "Authorization" : "OAuth \(token!)"
        ])
        let headers1 = HTTPHeaders([
            "Content-Type" : "application/json",
            "Accept" : "application/json",
            "Authorization" : "OAuth \(token!)"
        ])
        AF.request (url,
                   method: .post,
                   parameters: parameters,
                    encoder: URLEncodedFormParameterEncoder(encoder: URLEncodedFormEncoder(allowedCharacters: .urlHostAllowed), destination: .queryString),
                    headers: headers1) { $0.timeoutInterval = YaConst.requestTimeout }
                    .response { response in
            //print(response.response as Any)
            print(String(data: (response.value ?? Data()) ?? Data(), encoding: .utf8) as Any )
        }
    }
}
