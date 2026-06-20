//
//  HotKeyService.swift
//  WindowFinder
//
//  Infrastructure: グローバルショートカット（機能4）
//  ユーザーが設定画面で変更できるよう KeyboardShortcuts を利用する。
//

import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    /// ファインダー表示のグローバルショートカット。
    /// 既定は ⌃⌥Space（⌘⌥Space は macOS 標準と競合するため避ける）。
    static let toggleFinder = Self(
        "toggleFinder",
        default: .init(.space, modifiers: [.control, .option])
    )
}

/// グローバルショートカットの登録を担うサービス。
/// 実際のキー組み合わせは設定画面（`KeyboardShortcuts.Recorder`）で変更でき、
/// 変更は自動的に永続化・再登録される。
final class HotKeyService {
    /// ショートカット押下時のハンドラ
    var onTrigger: (() -> Void)?

    /// 既定（または保存済み）のショートカットでハンドラを登録する。
    func registerDefault() {
        KeyboardShortcuts.onKeyDown(for: .toggleFinder) { [weak self] in
            self?.onTrigger?()
        }
    }
}
