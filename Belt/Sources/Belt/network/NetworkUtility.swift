//
//  File.swift
//  
//
//  Created by ahn kyu suk on 9/5/24.
//

import Foundation
import Combine

/// 네트워크 요청을 처리하는 유틸리티 클래스
public class NetworkUtility {
    
    /// 네트워크 요청 처리 (GET, POST, PUT, DELETE, PATCH 지원)
    /// - Parameters:
    ///   - url: 요청할 URL
    ///   - method: HTTP 메서드 (GET, POST, PUT, DELETE, PATCH)
    ///   - parameters: GET 쿼리 파라미터 또는 POST/PUT/DELETE 바디 데이터
    ///   - headers: 추가 요청 헤더 필드
    /// - Returns: 네트워크 요청 결과를 반환하는 `AnyPublisher`
    public func request(
        url: URL,
        method: HTTPMethod,
        parameters: [String: Any]? = nil,
        requestHeaderFields: [String: String]? = nil
    ) -> AnyPublisher<Data, URLError> {
        
        let request = method.configureRequest(url: url, parameters: parameters, headers: requestHeaderFields)
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .eraseToAnyPublisher()
    }
}

extension AnyPublisher where Output == Data, Failure == URLError {
    
    /// 데이터를 String으로 변환해 출력하는 디버깅 함수
    func debug() -> AnyPublisher<Data, URLError> {
        return self.handleEvents(receiveOutput: { data in
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response String: \(responseString)")
            } else {
                print("Unable to convert Data to String")
            }
        })
        .eraseToAnyPublisher()
    }
}
