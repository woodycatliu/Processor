//
//  MockKVTokenService.swift
//  TCAIntroduce
//
//  Created by Woody Liu on 2023/1/31.
//

import Foundation
import Combine

extension KVTokenServer.Response {
    fileprivate static var test: Self {
        return .init(kvToken: .init(token: "Test KVToken",
                                    refreshToken: "Test KV RefreshToken")
        )
    }
}


struct MockKVTokenService: KVTokenServer {
    
    func fetchKVToken(_ jid: String, email: String, idToken: String) -> AnyPublisher<Response, Error> {
        return Just<Response>(Response.test)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(1), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func fetchKVToken(_ jid: String, email: String, idToken: String) async throws -> Response {
            try await Task.sleep(for: .seconds(1))
            return Response.test
    }
    
}
