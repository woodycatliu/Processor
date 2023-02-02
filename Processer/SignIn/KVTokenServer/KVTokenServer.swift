//
//  KVTokenServer.swift
//  TCAIntroduce
//
//  Created by Woody Liu on 2023/1/31.
//

import Combine

struct KVToken: Hashable {
    var token: String
    var refreshToken: String
}

struct KVTokenServerResponse {
    let kvToken: KVToken
}

protocol KVTokenServer {
    
    typealias Response = KVTokenServerResponse
    
    func fetchKVToken(_ jid: String, email: String, idToken: String) -> AnyPublisher<Response, Error>
    
    func fetchKVToken(_ jid: String, email: String, idToken: String) async throws -> Response
}
