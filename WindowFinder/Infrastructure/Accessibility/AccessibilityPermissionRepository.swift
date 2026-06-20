//
//  AccessibilityPermissionRepository.swift
//  WindowFinder
//
//  Infrastructure / Data: アクセシビリティ権限の取得・要求
//

import ApplicationServices
import AppKit
import CoreGraphics

/// `PermissionRepositoryProtocol` の実装。
/// アクセシビリティ権限（システム設定 > プライバシーとセキュリティ > アクセシビリティ）を扱う。
struct AccessibilityPermissionRepository: PermissionRepositoryProtocol {

    var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    func requestAccessibility() {
        // プロンプト付きで権限要求（既に許可済みなら何もしない）
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)

        // 併せて設定画面を直接開く（ユーザー導線を明確化）
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - 画面収録（サムネイル取得用）

    var isScreenCaptureTrusted: Bool {
        CGPreflightScreenCaptureAccess()
    }

    func requestScreenCapture() {
        // システムの権限ダイアログを表示。許可後はアプリ再起動が必要な場合がある。
        if !CGRequestScreenCaptureAccess() {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
