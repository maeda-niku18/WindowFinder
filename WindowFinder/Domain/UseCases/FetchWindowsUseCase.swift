//
//  FetchWindowsUseCase.swift
//  WindowFinder
//
//  指定アプリのウィンドウ一覧を取得するユースケース。
//

import Foundation

protocol FetchWindowsUseCase {
    func callAsFunction(pid: pid_t) -> [AppWindow]
}

struct FetchWindowsUseCaseImpl: FetchWindowsUseCase {
    private let repository: WindowRepositoryProtocol

    init(repository: WindowRepositoryProtocol) {
        self.repository = repository
    }

    func callAsFunction(pid: pid_t) -> [AppWindow] {
        repository.fetchWindows(for: pid)
    }
}
