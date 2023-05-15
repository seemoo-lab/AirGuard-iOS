//
//  URLSessionExtension.swift
//  AirGuard (iOS)
//
//  Created by Alex - SEEMOO on 24.01.23.
//

import Foundation

@available(macOS 10.15, watchOS 6.0, iOS 13.0, *)
extension URLSession {
    
    func asyncData(for request: URLRequest) async throws -> (Data, URLResponse) {
        return try await withCheckedThrowingContinuation { checkedContinuation in
            let task = dataTask(with: request) { data, response, error in
                if let data, let response {
                    checkedContinuation.resume(returning: (data, response))
                }else if let error {
                    checkedContinuation.resume(throwing: error)
                }else {
                    checkedContinuation.resume(throwing: URLError(.cancelled))
                }
            }
            
            task.resume()
        }
    }
}
