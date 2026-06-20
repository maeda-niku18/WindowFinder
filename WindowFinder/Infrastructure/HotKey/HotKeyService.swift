//
//  HotKeyService.swift
//  WindowFinder
//
//  グローバルショートカットを管理する。
//  ユーザーが設定画面で変更できるよう KeyboardShortcuts を利用する。
//

import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    /// ファインダー表示のグローバルショートカット。
    /// 既定は⌃⌥Space。⌘⌥SpaceはmacOS標準ショートカットと競合するため使わない。
    static let toggleFinder = Self(
        "toggleFinder",
        default: .init(.space, modifiers: [.control, .option])
    )
}

/// グローバルショートカットの登録を担うサービス。
/// 実際のキー組み合わせは設定画面の`KeyboardShortcuts.Recorder`で変更でき、
/// 変更は自動的に永続化・再登録される。
final class HotKeyService {
    /// ショートカット押下時のハンドラ
    var onTrigger: (() -> Void)?

    /// 既定または保存済みのショートカットでハンドラを登録する。
    func registerDefault() {
        KeyboardShortcuts.onKeyDown(for: .toggleFinder) { [weak self] in
            self?.onTrigger?()
        }
    }
}
