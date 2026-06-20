//
//  UpdaterService.swift
//  WindowFinder
//
//  Infrastructure: 自動アップデート（Sparkle）
//

import Foundation
import Sparkle

/// Sparkle の更新コントローラを保持するサービス。
/// フィード（appcast）と公開鍵は Info.plist（SUFeedURL / SUPublicEDKey）で設定する。
final class UpdaterService {
    private let controller: SPUStandardUpdaterController

    init() {
        // startingUpdater: true で起動時に自動チェックを開始する
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    /// ユーザー操作による手動チェック（「アップデートを確認…」）。
    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}
