//
//  ActivateWindowUseCase.swift
//  WindowFinder
//
//  ウィンドウを呼び出すユースケース。
//

import Foundation

protocol ActivateWindowUseCase {
    @discardableResult
    func callAsFunction(_ window: AppWindow) -> Bool
}

struct ActivateWindowUseCaseImpl: ActivateWindowUseCase {
    private let repository: WindowRepositoryProtocol

    init(repository: WindowRepositoryProtocol) {
        self.repository = repository
    }

    @discardableResult
    func callAsFunction(_ window: AppWindow) -> Bool {
        repository.activate(window)
    }
}
