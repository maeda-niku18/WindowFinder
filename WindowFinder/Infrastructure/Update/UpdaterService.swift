//
//  UpdaterService.swift
//  WindowFinder
//
//  Sparkleによる自動アップデートを管理する。
//

import Foundation
import Sparkle

/// Sparkle の更新コントローラを保持するサービス。
/// フィードと公開鍵はInfo.plistで設定する。
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

    /// ユーザー操作による手動チェック。
    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}
