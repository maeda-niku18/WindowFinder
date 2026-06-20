//
//  AppContainer.swift
//  WindowFinder
//
//  App: 依存解決（Composition Root）
//

import Foundation

/// 各層の依存を組み立てる合成ルート。
/// ここでのみ具象型を生成し、上位は抽象（プロトコル）に依存する。
@MainActor
final class AppContainer {

    // Data / Infrastructure
    private let windowRepository: WindowRepositoryProtocol
    private let permissionRepository: PermissionRepositoryProtocol
    private let thumbnailProvider: WindowThumbnailProviding

    init() {
        self.windowRepository = AccessibilityWindowRepository()
        self.permissionRepository = AccessibilityPermissionRepository()
        self.thumbnailProvider = WindowThumbnailService()
    }

    /// ファインダー画面の ViewModel を生成する。
    func makeFinderViewModel() -> FinderViewModel {
        FinderViewModel(
            fetchRunningApps: FetchRunningAppsUseCaseImpl(repository: windowRepository),
            fetchWindows: FetchWindowsUseCaseImpl(repository: windowRepository),
            activateWindow: ActivateWindowUseCaseImpl(repository: windowRepository),
            searchWindows: SearchWindowsUseCaseImpl(),
            permission: permissionRepository,
            thumbnailProvider: thumbnailProvider
        )
    }
}
