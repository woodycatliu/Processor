//
//  FirebaseSignInServer.swift
//  TCAIntroduce
//
//  Created by Woody Liu on 2023/1/31.
//

import Foundation
import Combine

struct FirebaseSignServerResponse {
    let idToken: String
    let refreshToken: String?
    let date: Date
    let providerID: String
    var name: String?
    var email: String?
    let userId: String
}

protocol FirebaseSignInServer {
    
    typealias Response = FirebaseSignServerResponse
    
    func signIn(with email: String, password: String) async throws -> Response
    
    func signIn(with email: String, password: String) -> AnyPublisher<Response, Error>
    
    func signIn(withProviderID id: String, idToken token: String, nonce: String?) async throws -> Response
    
    func signIn(withProviderID id: String, idToken token: String, nonce: String?) -> AnyPublisher<Response, Error>
    
    func update(_ response: Response, name: String, email: String) async throws -> Response
    
    func update(_ response: Response, name: String, email: String) -> AnyPublisher<Response, Error>
    
    func signOut()
}
