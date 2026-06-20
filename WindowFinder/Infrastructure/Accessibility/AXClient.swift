//
//  AXClient.swift
//  WindowFinder
//
//  Infrastructure: Accessibility API (AXUIElement) の薄いラッパー
//

import ApplicationServices
import AppKit

/// AXUIElement に対する低レベル操作をまとめたユーティリティ。
/// Optional / CFType の取り回しをここに隔離し、上位層を素朴に保つ。
enum AXClient {

    // MARK: - 属性取得

    /// 任意の属性を CFTypeRef として取得する。
    static func copyAttribute(_ element: AXUIElement, _ attribute: String) -> CFTypeRef? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        return result == .success ? value : nil
    }

    /// 文字列属性を取得する。
    static func stringAttribute(_ element: AXUIElement, _ attribute: String) -> String? {
        copyAttribute(element, attribute) as? String
    }

    /// Bool 属性を取得する。
    static func boolAttribute(_ element: AXUIElement, _ attribute: String) -> Bool {
        (copyAttribute(element, attribute) as? Bool) ?? false
    }

    /// AXUIElementの配列属性を取得する。
    static func elementArrayAttribute(_ element: AXUIElement, _ attribute: String) -> [AXUIElement] {
        guard let value = copyAttribute(element, attribute) else { return [] }
        // CFArray → [AXUIElement]
        guard CFGetTypeID(value) == CFArrayGetTypeID() else { return [] }
        return (value as? [AXUIElement]) ?? []
    }

    // MARK: - 属性設定 / アクション

    @discardableResult
    static func setBool(_ element: AXUIElement, _ attribute: String, _ value: Bool) -> Bool {
        AXUIElementSetAttributeValue(element, attribute as CFString, value as CFBoolean) == .success
    }

    @discardableResult
    static func perform(_ element: AXUIElement, _ action: String) -> Bool {
        AXUIElementPerformAction(element, action as CFString) == .success
    }

    /// CGWindowIDを公開APIで取得できない場合に備え、取得失敗時はnilを返す。
    /// 公開 API のみで安定 ID を作るため、取得できない場合は呼び出し側でフォールバックする。
    static func windowNumber(_ window: AXUIElement) -> CGWindowID? {
        var windowID: CGWindowID = 0
        let result = _AXUIElementGetWindow(window, &windowID)
        return result == .success ? windowID : nil
    }
}

// `_AXUIElementGetWindow`はSDKに公開宣言がないため、ここでextern宣言する。
// 多くのウィンドウ管理ツールで使われている準公開シンボル。
@_silgen_name("_AXUIElementGetWindow")
private func _AXUIElementGetWindow(_ element: AXUIElement, _ identifier: UnsafeMutablePointer<CGWindowID>) -> AXError
