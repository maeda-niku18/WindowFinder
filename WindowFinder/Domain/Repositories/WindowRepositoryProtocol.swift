//
//  WindowRepositoryProtocol.swift
//  WindowFinder
//
//  ドメイン層が参照するリポジトリの抽象。
//

import Foundation

/// ウィンドウ情報の取得・操作を抽象化するリポジトリ。
/// データ層が実装する。
protocol WindowRepositoryProtocol {
    /// 起動中アプリ一覧を取得する。
    func fetchRunningApps() -> [RunningApp]

    /// 指定アプリが保持するウィンドウ一覧を取得する。
    func fetchWindows(for pid: pid_t) -> [AppWindow]

    /// すべてのアプリのウィンドウを横断して取得する。
    func fetchAllWindows() -> [AppWindow]

    /// 対象ウィンドウを最小化解除・前面化・フォーカスする。
    /// - Returns: 操作に成功したか
    @discardableResult
    func activate(_ window: AppWindow) -> Bool
}

/// アクセシビリティ／画面収録権限の状態を抽象化する。
protocol PermissionRepositoryProtocol {
    /// 現在アクセシビリティ権限が許可されているか。
    var isAccessibilityTrusted: Bool { get }
    /// システム環境設定のアクセシビリティ画面を開き、権限付与を促す。
    func requestAccessibility()

    /// 画面収録権限が許可されているか。
    var isScreenCaptureTrusted: Bool { get }
    /// 画面収録権限を要求し、必要なら設定画面を開く。
    func requestScreenCapture()
}
