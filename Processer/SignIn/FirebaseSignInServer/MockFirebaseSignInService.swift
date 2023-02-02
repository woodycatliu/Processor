//
//  MockFirebaseSignInService.swift
//  TCAIntroduce
//
//  Created by Woody Liu on 2023/1/31.
//

import Foundation
import Combine

extension FirebaseSignInServer.Response {
    static var test: Self {
        return .init(idToken: "Test Firebase idToken",
                     refreshToken: "Test Firebase refreshToken",
                     date: Date(),
                     providerID: "Test Firebase provideID",
                     userId: "Test Firebase userID")
    }
}

struct MockFirebaseSignInService: FirebaseSignInServer {
    func signIn(with email: String, password: String) async throws -> Response {
        return try await delayResponse()
    }
    
    func signIn(with email: String, password: String) -> AnyPublisher<Response, Error> {
        return publisherResponse().map { response -> Response in
            var response = response
            response.name = "EmailSignIN"
            response.email = email
            return response
        }.eraseToAnyPublisher()
    }
    
    func signIn(withProviderID id: String, idToken token: String, nonce: String?) async throws -> Response {
        return try await delayResponse()
    }
    
    func signIn(withProviderID id: String, idToken token: String, nonce: String?) -> AnyPublisher<Response, Error> {
        return publisherResponse()
    }
    
    func update(_ response: Response, name: String, email: String) async throws -> Response {
        return try await delayResponse()
    }
    
    func update(_ response: Response, name: String, email: String) -> AnyPublisher<Response, Error> {
        var response = response
        response.name = name
        response.email = email
        return publisherResponse().map { _ in response }.eraseToAnyPublisher()
    }
    
    func signOut() {}
    
    private func delayResponse() async throws -> Response {
        try await Task.sleep(for: .seconds(1))
        return Response.test
    }
    
    private func publisherResponse() -> AnyPublisher<Response, Error> {
        return Just<Response>(Response.test)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(1), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
}
