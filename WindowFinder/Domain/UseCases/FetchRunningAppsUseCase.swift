//
//  FetchRunningAppsUseCase.swift
//  WindowFinder
//
//  UseCase: 起動中アプリ一覧の取得（機能1）
//

import Foundation

protocol FetchRunningAppsUseCase {
    func callAsFunction() -> [RunningApp]
}

struct FetchRunningAppsUseCaseImpl: FetchRunningAppsUseCase {
    private let repository: WindowRepositoryProtocol

    init(repository: WindowRepositoryProtocol) {
        self.repository = repository
    }

    func callAsFunction() -> [RunningApp] {
        repository.fetchRunningApps()
            // ウィンドウを持つアプリを優先し、アプリ名で昇順表示
            .sorted { lhs, rhs in
                if lhs.windowCount != rhs.windowCount {
                    return lhs.windowCount > rhs.windowCount
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }
}
