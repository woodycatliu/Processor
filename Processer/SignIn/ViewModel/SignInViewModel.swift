//
//  SignInViewModel.swift
//  Processer
//
//  Created by Woody Liu on 2023/2/2.
//

import Combine

class SignInViewModel {
    
    var publisher: AnyPublisher<SignInProcessor.States, Never> {
        return processor.publisher
    }
    
    func send(_ action: SignInProcessor.Action) {
        processor.send(action)
    }
    
    init(processor: ProcessorType = SignInProcessor.testProcessor) {
        self.processor = processor
    }
    
    
    private let processor: ProcessorType

    typealias ProcessorType = SignInProcessor.ProcessorType
}
