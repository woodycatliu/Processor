//
//  AppleSignInServer.swift
//  TCAIntroduce
//
//  Created by Woody Liu on 2023/1/31.
//

import Foundation
import Combine

struct AppleUser {
    let identityToken: String
    let user: String
    let email: String?
    let name: PersonNameComponents?
    let nonce: String
}

protocol AppleSignInServer {
    
    typealias Response = AppleUser
    
    func tryStart() async throws -> Response
    
    func tryStart() -> AnyPublisher<Response, Error>
}
