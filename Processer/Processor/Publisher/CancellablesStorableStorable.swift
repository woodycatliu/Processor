//
//  CancellablesStorableStorable.swift
//  Processer
//
//  Created by Woody Liu on 2023/2/2.
//

import Foundation
import Combine

public protocol CancellablesStorableStorable: AnyObject {
    var storage: [String: Set<AnyCancellable>] { get set }
    func insert(_ id: String, cancelable: AnyCancellable?)
}

class CancellablesCollection: CancellablesStorableStorable {
    private let lock: NSRecursiveLock = NSRecursiveLock()
    var storage: [String: Set<AnyCancellable>] {
        set  {
            lock.lock()
            defer {
                lock.unlock()
            }
            _storage = newValue
        }
        
        get {
            return _storage
        }
    }
    
    private var _storage: [String: Set<AnyCancellable>] = [:]
    
    public func insert(_ id: String, cancelable: AnyCancellable?) {
        guard let cancelable = cancelable else { return }
        if storage[id] == nil {
           storage[id] = []
        }
        storage[id]?.insert(cancelable)
    }
    
    public func cancel(id: String) {
        storage[id]?.forEach {
            $0.cancel()
        }
        storage[id] = nil
    }
}
