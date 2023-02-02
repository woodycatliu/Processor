//
//  AnyProcessorReducer.swift
//  Processer
//
//  Created by Woody Liu on 2023/2/2.
//

struct AnyProcessorReducer<State, Action, PrivateAction, Environment> {
        
    let mutated: Mutated
    
    let reduce: Reduce
    
    typealias Reduce = (_ state: inout State, _ privateAction: PrivateAction, _ envi: Environment) -> ProcessorPublisher<PrivateAction, Never>?
    
    typealias Mutated = (_ action: Action) -> PrivateAction

}

struct ProcessorReducer<State, Action, PrivateAction>: ProcessorReducerProtocol {
    
    typealias Mutated = (_ action: Action) -> PrivateAction
    
    typealias Reduce = (_ state: inout State, _ privateAction: PrivateAction) -> ProcessorPublisher<PrivateAction, Never>?
    
    init(mutated: @escaping Mutated, reduce: @escaping Reduce) {
        self.mutated = mutated
        self.reduce = reduce
    }
    
    func transform(_ action: Action) -> PrivateAction {
        return mutated(action)
    }

    func reducing(state: inout State, privateAction privatization: PrivateAction) -> ProcessorPublisher<PrivateAction, Never>? {
        return reduce(&state, privatization)
    }
    
    private let mutated: Mutated
    
    private let reduce: Reduce
}
