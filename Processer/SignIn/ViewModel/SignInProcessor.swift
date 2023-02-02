//
//  SignInAction.swift
//  TCAIntroduce
//
//  Created by Woody Liu on 2023/1/31.
//

import Combine

struct SignInProcessor {
    
    typealias ProcessorType = Processor<States, Action, PrivateAction, Environment>
    
    static var testProcessor: ProcessorType {
        Processor(initialState: States(stauts: .ready), reducer: Self.reducer, environment: Environment.test)
    }
    
    static var reducer: AnyProcessorReducer<States, Action, PrivateAction, Environment> {
        return AnyProcessorReducer(mutated: { action in
            return action.privateAction
        }, reduce: { states, action, environment -> ProcessorPublisher<SignInProcessor.PrivateAction, Never>? in
            switch action {
                
            case .appleSignIn:
                states.stauts = .isSignIning
                return environment
                    .appleService.tryStart()
                    .catchToResultProcessor(PrivateAction.handleAppleSingIn)
                
            case .signInEmail(with: let email, password: let password):
                states.stauts = .isSignIning
                return environment
                    .firebaseService
                    .signIn(with: email, password: password)
                    .catchToResultProcessor(PrivateAction.handleFirebaseSingIn)
                
            case .signInProviderID(appleUser: let appleUser):
                return environment.signInAppleUser(appleUser)
                    .catchToResultProcessor(PrivateAction.handleProviderIDSignIn)
                
            case .update(response: let response, name: let name, email: let email):
                return environment
                    .firebaseService
                    .update(response, name: name, email: email)
                    .catchToResultProcessor(PrivateAction.handleFirebaseSingIn)
                
            case .fetchKvToken(userFactory: let userFactory, jid: let jid, email: let email, idToken: let idToken):
                return environment.fetchKVToken(userFactory: userFactory
                                                , jid,
                                                email: email,
                                                idToken: idToken)
                .catchToResultProcessor(PrivateAction.handleKVTokenFetch)
                
            case .storeAppleUser(let appleUser):
                return .send(PrivateAction.signInProviderID(appleUser: appleUser))
                
            case .handleAppleSingIn(let .success(response)):
                return .send(.storeAppleUser(response))
                
            case .handleFirebaseSingIn(let .success(response)):
                return .send(.fetchKvToken(userFactory: .init(firebaseResponse: response),
                                           jid: response.email ?? "null",
                                           email: response.email ?? "null",
                                           idToken: response.idToken))
                
            case .updateFirebaseInfoIfNeed(response: let response, appleUser: let appleUser):
                guard response.email == nil || response.name == nil else {
                    return .send(.fetchKvToken(userFactory: .init(firebaseResponse: response),
                                               jid: response.email!,
                                               email: response.email!,
                                               idToken: response.idToken))
                }
                
                let (email, name) = environment.readAppleUser(appleUser.user)
                
                return .send(.update(response: response,
                                     name: name,
                                     email: email))
                
            case .handleProviderIDSignIn(let .success(response)):
                return .send(.updateFirebaseInfoIfNeed(response: response.response,
                                                       appleUser: response.appleUser))
                
            case .handleKVTokenFetch(let .success(response)):
                if let user = response.createUser() {
                    return .send(.updateStauts(.didSignIn(user: user)))
                }
                return .send(.updateStauts(.error(err: SignInError.unknown)))
                
                
            case .handleAppleSingIn(let .failure(error)),
                    .handleKVTokenFetch(let .failure(error)),
                    .handleFirebaseSingIn(let .failure(error)),
                    .handleProviderIDSignIn(let .failure(error)):
                return .send(.updateStauts(.error(err: error)))
                
                
            case .updateStauts(let status):
                print(status)
                states.stauts = status
                return .none
            case .ready:
                return .send(.updateStauts(.ready))
            }
        })
        
    }
}

extension SignInProcessor {
    
    // MARK: Action
    
    enum Action {
        case appleSignIn
        
        case emailSignIn(_ email: String, _ password: String)
        
        var privateAction: PrivateAction {
            switch self {
            case .appleSignIn: return .appleSignIn
            case .emailSignIn(let emil, let password): return .signInEmail(with: emil, password: password)
            }
        }
    }
    
    enum PrivateAction {
        
        case appleSignIn
        case signInEmail(with: String,
                         password: String)
        
        case signInProviderID(appleUser: AppleUser)
        case update(response: FirebaseSignInServer.Response,
                    name: String,
                    email: String)
        
        case fetchKvToken(userFactory: User.UserFactory,
                          jid: String,
                          email: String,
                          idToken: String)
        
        case storeAppleUser(_ appleUser: AppleUser)
        case updateFirebaseInfoIfNeed(response: FirebaseSignServerResponse, appleUser: AppleUser)
        
        case handleProviderIDSignIn(_ res: Result<(appleUser: AppleUser, response: FirebaseSignServerResponse), Error>)
        case handleAppleSingIn(_ res: Result<AppleUser, Error>)
        case handleFirebaseSingIn(_ res: Result<FirebaseSignServerResponse, Error>)
        case handleKVTokenFetch(_ res: Result<User.UserFactory, Error>)
        case updateStauts(_ status: SignInStatus)
        case ready
    }
    
    // MARK: States
    
    struct States: Equatable {
        var stauts: SignInStatus
    }
    
    // MARK: Environment
    
    struct Environment {
        
        let appleService: AppleSignInServer
        
        let firebaseService: FirebaseSignInServer
        
        let kvTokenService: KVTokenServer
        
        static let test: Environment = .init(appleService: MockAppleSignInService(),
                                             firebaseService: MockFirebaseSignInService(),
                                             kvTokenService: MockKVTokenService())
        
        func fetchKVToken(userFactory: User.UserFactory, _ jid: String, email: String, idToken: String) -> AnyPublisher<User.UserFactory, Error> {
            print("userFactory:", userFactory)
            return kvTokenService.fetchKVToken(jid, email: email, idToken: idToken)
                .map { response -> User.UserFactory in
                    var userFactory = userFactory
                    userFactory.kvToken = response.kvToken
                    return userFactory
                }.eraseToAnyPublisher()
        }
        
        func signInAppleUser(_ appleUser: AppleUser) -> AnyPublisher<(appleUser: AppleUser, response: FirebaseSignServerResponse), Error> {
            return firebaseService
                .signIn(withProviderID: "apple.com", idToken: appleUser.identityToken, nonce: appleUser.nonce)
                .map { (appleUser, $0) }
                .eraseToAnyPublisher()
        }
        
        func storeAppleUser(appleUser: AppleUser) -> AnyPublisher<AppleUser, Error> {
            return Deferred {
                Future { promise in
                    if let email = appleUser.email {
                        // dosomething
                        print(email)
                    }
                    promise(.success(appleUser))
                }
            }.eraseToAnyPublisher()
        }
        
        func readAppleUser(_ account: String) -> (email: String, name: String) {
            return ("Default@example.com", "Default")
        }
        
    }
    
}

enum SignInStatus: Equatable {
    static func == (lhs: SignInStatus, rhs: SignInStatus) -> Bool {
        switch (lhs, rhs) {
        case (.ready, .ready) :
            return true
        case (.isSignIning, isSignIning):
            return true
        case (.didSignIn(user: let user1), .didSignIn(user: let user2)):
            return user1 != user2
        case (.error(err: let err1), .error(err: let err2)):
            return err1.localizedDescription != err2.localizedDescription
        default:
            return false
        }
    }
    
    case ready
    case isSignIning
    case didSignIn(user: User)
    case error(err: Error)
    
    var user: User? {
        if case Self.didSignIn(user: let user) = self {
            return user
        }
        return nil
    }
}

enum SignInError: Error {
    case unknown
}
