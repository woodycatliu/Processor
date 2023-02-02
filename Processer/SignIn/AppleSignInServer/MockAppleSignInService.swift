//
//  MockAppleSignInService.swift
//  TCAIntroduce
//
//  Created by Woody Liu on 2023/1/31.
//

import Foundation
import Combine

extension AppleSignInServer.Response {
    fileprivate init() {
        self.identityToken = "Test AppleUser identityToken"
        self.user = "Test AppleUser user"
        self.email = "Test AppleUser email"
        self.name = PersonNameComponents()
        self.nonce = "Test AppleUser nonce"
    }
    
    fileprivate static let test: AppleUser = .init()
}

struct MockAppleSignInService: AppleSignInServer {
    
    func tryStart() async throws -> AppleUser {
        try await Task.sleep(for: .seconds(1))
        return Response.test
    }
    
    func tryStart() -> AnyPublisher<AppleUser, Error> {
        return Just<Response>(Response.test)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(1), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
}
