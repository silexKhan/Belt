//
//  File.swift
//  
//
//  Created by ahn kyu suk on 9/5/24.
//

import Foundation
import Combine

/// A utility class for handling HTTP network requests using `Combine` framework.
/// This class supports various HTTP methods (GET, POST, PUT, DELETE, PATCH) and allows sending both query parameters
/// for GET requests and body parameters for POST/PUT/DELETE requests. It also supports adding custom headers to requests.
/// The result of each request is returned as an `AnyPublisher`, which can be subscribed to for reactive handling of network responses.
///
/// The class automatically handles common issues such as URL encoding, JSON encoding for body data, and error handling based on HTTP status codes.
///
/// # Features:
/// - Support for GET, POST, PUT, DELETE, PATCH HTTP methods
/// - Support for sending query parameters or body data (JSON format)
/// - Custom request headers
/// - Reactive error handling using `Combine`
///
/// # Example Usage:
///
/// ```swift
/// let networkUtility = NetworkUtility()
/// let url = URL(string: "https://api.example.com/resource")!
///
/// // GET request with query parameters
/// networkUtility.request(url: url, method: .get, parameters: ["query": "example"])
///     .sink(receiveCompletion: { completion in
///         switch completion {
///         case .finished:
///             print("Request finished successfully.")
///         case .failure(let error):
///             print("Error occurred: \(error)")
///         }
///     }, receiveValue: { data in
///         print("Received data: \(data)")
///     })
///     .store(in: &cancellables)
///
/// // POST request with body parameters
/// networkUtility.request(url: url, method: .post, parameters: ["key": "value"])
///     .sink(receiveCompletion: { completion in
///         switch completion {
///         case .finished:
///             print("POST request finished successfully.")
///         case .failure(let error):
///             print("Error occurred: \(error)")
///         }
///     }, receiveValue: { data in
///         print("Received data: \(data)")
///     })
///     .store(in: &cancellables)
/// ```
///
/// This example demonstrates how to use `NetworkUtility` to make GET and POST requests, handle responses, and manage errors using `Combine`.
public class NetworkUtility {
    
    /// Performs an HTTP request with the given method, parameters, and headers.
    /// - Parameters:
    ///   - url: The URL for the network request.
    ///   - method: The HTTP method to use (GET, POST, PUT, DELETE, PATCH).
    ///   - parameters: Query parameters for GET requests or body data for other methods (optional).
    ///   - requestHeaderFields: Custom headers for the request (optional).
    /// - Returns: An `AnyPublisher` that publishes the result of the request as `Data` or an error.
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
    
    /// A debugging function to print the response data as a string or JSON object.
    /// This is helpful for visualizing the response from a network request during development.
    /// - Returns: An `AnyPublisher` that logs the response data and passes it downstream.
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
