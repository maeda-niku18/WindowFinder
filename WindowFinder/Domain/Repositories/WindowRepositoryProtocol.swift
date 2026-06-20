//
//  WindowRepositoryProtocol.swift
//  WindowFinder
//
//  Domain: リポジトリ抽象（実装は Data 層）
//

import Foundation

/// ウィンドウ情報の取得・操作を抽象化するリポジトリ。
/// Data 層（Accessibility / NSWorkspace）が実装する。
protocol WindowRepositoryProtocol {
    /// 起動中アプリ一覧を取得する。
    func fetchRunningApps() -> [RunningApp]

    /// 指定アプリ（pid）が保持するウィンドウ一覧を取得する。
    func fetchWindows(for pid: pid_t) -> [AppWindow]

    /// すべてのアプリのウィンドウを横断取得する（検索用）。
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

    /// 画面収録権限（サムネイル取得用）が許可されているか。
    var isScreenCaptureTrusted: Bool { get }
    /// 画面収録権限を要求する（必要なら設定画面を開く）。
    func requestScreenCapture()
}
