//
//  Processor.swift
//  Processer
//
//  Created by Woody Liu on 2023/2/2.
//

import Foundation
import Combine

@dynamicMemberLookup
final class Processor<State, Action, PrivateAction, Environment>: Identifiable {
    
    /// for process log
    /// default; UUID().uuidString
    var id: String = UUID().uuidString
    
    /// if Action/PrivateAction has  conformed CustomStringConvertible will be priority description
    /// default is true
    var logActionDescriotionFirst: Bool = true
    
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
        log(obj: action)
        let privatization = reducer.transform(action)
        _send(privateAction: privatization)
    }
    
    private func _send(privateAction privatization: PrivateAction) {
        log(obj: privatization)
        if let publisher = reducer.reducing(state: &_state.value, privateAction: privatization) {
            let uuid = UUID().uuidString
    
            let cancelable = publisher
                .cancellable(id: uuid, in: collection)
                .receive(on: queue)
                .sink(receiveValue: { [weak self] privateAction in
                    guard let self = self else { return }
                    self._send(privateAction: privateAction)
                })
            collection.insert(uuid, cancelable: cancelable)
        } else {
            
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

fileprivate extension Processor {
    
    private var prefix: String {
        return "Processor ID: \(id.prefix(3)) -"
    }
    
 
    func log(obj: Any) {
        if let privateAction = obj as? PrivateAction {
            _log(privateAction: privateAction)
        } else if let action = obj as? Action {
            _log(action: action)
        }
    }
    
    func _log(action: Action) {
      #if DEBUG
        if let act = action as? CustomStringConvertible,
           logActionDescriotionFirst {
            print("\(prefix) - Action - \(act.description) - date: \(Date())")
            return
        }
        
        print("\(prefix) - Action - \(dump(action)) - date: \(Date())")
      #endif
    }
    
    func _log(privateAction: PrivateAction) {
        #if DEBUG
        if let act = privateAction as? CustomStringConvertible,
           logActionDescriotionFirst {
            print("\(prefix) - PrivateAction - \(act.description) - date: \(Date())")
            return
        }
        
        print("\(prefix) - PrivateAction - \(dump(privateAction)) - date: \(Date())")
        #endif
    }
   
    func logDivid() {
        #if DEBUG
        print("\(prefix) -------------------------------------")
        #endif
    }
    
 
}
