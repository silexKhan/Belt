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
    
    /// 메서드에 따라 URLRequest를 구성하는 함수 (헤더 필드 추가 가능)
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
    
    /// GET 메서드를 위한 쿼리 파라미터를 URL에 추가하는 함수
    private func buildURLWithQueryParams(url: URL, parameters: [String: Any]?) -> URL {
        guard let params = parameters else { return url }
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = params.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        urlComponents?.queryItems = queryItems
        return urlComponents?.url ?? url
    }
    
    /// POST, PUT, DELETE 등의 메서드를 위한 바디 파라미터를 JSON으로 인코딩하는 함수
    private func encodeParameters(_ parameters: [String: Any]?) -> Data? {
        guard let params = parameters else { return nil }
        return try? JSONSerialization.data(withJSONObject: params, options: [])
    }
}
