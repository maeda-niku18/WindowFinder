//
//  ActivateWindowUseCase.swift
//  WindowFinder
//
//  UseCase: ウィンドウ呼び出し（機能3）
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
