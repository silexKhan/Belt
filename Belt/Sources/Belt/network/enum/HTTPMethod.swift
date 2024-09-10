//
//  HTTPMethod.swift
//
//
//  Created by ahn kyu suk on 9/5/24.
//

import Foundation
import Combine

/// HTTP 메서드 타입 정의 (헤더와 바디 처리 포함)
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
    
    /// Configures a `URLRequest` based on the HTTP method, query or body parameters, and optional headers.
    /// - Parameters:
    ///   - url: The URL to which the request will be made.
    ///   - parameters: The query parameters for GET requests or body data for POST/PUT/DELETE requests (optional).
    ///   - headers: Custom headers to include in the request (optional).
    /// - Returns: A configured `URLRequest` object ready to be used for network calls.
    func configureRequest(url: URL, parameters: [String: Any]?, headers: [String: String]?) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = self.rawValue
        
        // 헤더 필드 설정
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        switch self {
        case .get:
            request.url = buildURLWithQueryParams(url: url, parameters: parameters)
        case .post, .put, .delete, .patch:
            request.httpBody = encodeParameters(parameters)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        return request
    }
    
    /// Builds a URL with encoded query parameters for a GET request.
    /// - Parameters:
    ///   - url: The base URL for the request.
    ///   - parameters: A dictionary containing query parameters to be encoded and added to the URL (optional).
    /// - Returns: A URL with the encoded query parameters.
    private func buildURLWithQueryParams(url: URL, parameters: [String: Any]?) -> URL {
        guard let params = parameters else { return url }
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = params.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        urlComponents?.queryItems = queryItems
        return urlComponents?.url ?? url
    }
    
    /// Encodes the parameters into a JSON body for POST, PUT, DELETE, and PATCH requests.
    /// - Parameter parameters: A dictionary containing the parameters to be encoded.
    /// - Returns: A `Data` object containing the JSON-encoded body, or `nil` if no parameters were provided.
    /// - Throws: An error if the encoding fails.
    private func encodeParameters(_ parameters: [String: Any]?) -> Data? {
        guard let params = parameters else { return nil }
        return try? JSONSerialization.data(withJSONObject: params, options: [])
    }
}
