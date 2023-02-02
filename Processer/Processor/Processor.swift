//
//  Processor.swift
//  Processer
//
//  Created by Woody Liu on 2023/2/2.
//

import Foundation
import Combine

@dynamicMemberLookup
final class Processor<State, Action, PrivateAction, Environment> {
    
    var publisher: AnyPublisher<State, Never> {
        return _state.eraseToAnyPublisher()
    }
    
    typealias Mutated = (_ action: Action) -> PrivateAction
    
    convenience init(initialState: State,
                     reducer: AnyProcessorReducer<State, Action, PrivateAction, Environment>,
                        environment: Environment) {
        self.init(initialState: initialState,
                  reducer: ProcessorReducer(mutated: reducer.mutated,
                                               reduce: { state, privateAction in
            reducer.reduce(&state, privateAction, environment)
        }))
    }
    
    init<R: ProcessorReducerProtocol>(initialState: State ,reducer: R)
    where R.State == State, R.Action == Action, R.PrivateAction == PrivateAction {
        self.reducer = reducer
        self._state = .init(initialState)
    }
    
    func send(_ action: Action) {
        let privatization = reducer.transform(action)
        _send(privateAction: privatization)
    }
    
    private func _send(privateAction privatization: PrivateAction) {
        if let publisher = reducer.reducing(state: &_state.value, privateAction: privatization) {
            let uuid = UUID().uuidString
    
            let cancelable = publisher
                .cancellable(id: uuid, in: collection)
                .receive(on: queue)
                .sink(receiveValue: { [weak self] privateAction in
                    guard let self = self else { return }
                    self._send(privateAction: privateAction)
                })
            collection.storage[uuid] = [cancelable]
        }
    }
    
    private let reducer: any ProcessorReducerProtocol<State, Action, PrivateAction>
    
    private let _state: CurrentValueSubject<State, Never>
    
    private let collection: CancellablesCollection = CancellablesCollection()
    
    private let queue: DispatchQueue = {
        DispatchQueue(label: "com.AnyProcessor.\(UUID().uuidString)")
    }()
    
}

extension Processor {
    subscript<Value>(dynamicMember keyPath: KeyPath<State, Value>) -> Value {
        return self._state.value[keyPath: keyPath]
    }
}
