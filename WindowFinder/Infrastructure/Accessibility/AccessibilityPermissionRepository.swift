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
/// アクセシビリティ権限を扱う。
struct AccessibilityPermissionRepository: PermissionRepositoryProtocol {

    var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    func requestAccessibility() {
        // 未許可の場合はシステムの権限プロンプトを表示する。
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)

        // ユーザーが迷わないよう、該当する設定画面も開く。
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - 画面収録

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
