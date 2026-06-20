//
//  AccessibilityWindowRepository.swift
//  WindowFinder
//
//  Data: WindowRepositoryProtocol の Accessibility / NSWorkspace 実装
//

import ApplicationServices
import AppKit

/// Accessibility API と NSWorkspace を用いてウィンドウ情報を取得・操作する。
///
/// AXUIElement はドメイン外の型のため UI 層には渡さず、
/// `AppWindow.id` → `AXUIElement` のマッピングを内部キャッシュで保持する。
final class AccessibilityWindowRepository: WindowRepositoryProtocol {

    /// id → 実体のキャッシュ（fetch のたびに再構築）
    private var windowCache: [String: AXUIElement] = [:]

    // MARK: - 起動中アプリ（機能1）

    func fetchRunningApps() -> [RunningApp] {
        regularApplications().map { app in
            let pid = app.processIdentifier
            let count = windowElements(forPID: pid).count
            return RunningApp(
                id: pid,
                bundleIdentifier: app.bundleIdentifier,
                name: app.localizedName ?? app.bundleIdentifier ?? "不明なアプリ",
                windowCount: count
            )
        }
    }

    // MARK: - 指定アプリのウィンドウ（機能2）

    func fetchWindows(for pid: pid_t) -> [AppWindow] {
        let appName = NSRunningApplication(processIdentifier: pid)?.localizedName ?? ""
        let elements = windowElements(forPID: pid)
        return elements.enumerated().map { index, element in
            makeWindow(element: element, pid: pid, appName: appName, index: index)
        }
    }

    // MARK: - 全ウィンドウ横断（検索用 機能5）

    func fetchAllWindows() -> [AppWindow] {
        windowCache.removeAll(keepingCapacity: true)
        return regularApplications().flatMap { app -> [AppWindow] in
            let pid = app.processIdentifier
            let appName = app.localizedName ?? ""
            return windowElements(forPID: pid).enumerated().map { index, element in
                makeWindow(element: element, pid: pid, appName: appName, index: index)
            }
        }
    }

    // MARK: - ウィンドウ呼び出し（機能3）

    @discardableResult
    func activate(_ window: AppWindow) -> Bool {
        guard let element = windowCache[window.id] else { return false }

        // 1) 最小化されていれば解除
        if AXClient.boolAttribute(element, kAXMinimizedAttribute as String) {
            AXClient.setBool(element, kAXMinimizedAttribute as String, false)
        }

        // 2) ウィンドウを前面化（同一アプリ内で最前面へ）
        AXClient.perform(element, kAXRaiseAction as String)

        // 3) アプリ自体をアクティブ化（別 Space ならシステムが切り替える）
        let activated = NSRunningApplication(processIdentifier: window.ownerPID)?
            .activate(options: [.activateAllWindows]) ?? false

        return activated
    }

    // MARK: - 内部ヘルパー

    /// Dock に出る通常アプリ（メニューバー常駐や自分自身は除外）。
    private func regularApplications() -> [NSRunningApplication] {
        let selfPID = ProcessInfo.processInfo.processIdentifier
        return NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && $0.processIdentifier != selfPID
        }
    }

    /// 指定 pid のアプリが保持する「通常ウィンドウ」要素を取得する。
    ///
    /// 認証ポップアップやツールチップ等（subrole が AXStandardWindow 以外）は
    /// ウィンドウ探索のノイズになるため除外する。これにより各アプリの
    /// 「ウィンドウ」メニューの件数とも一致しやすくなる。
    private func windowElements(forPID pid: pid_t) -> [AXUIElement] {
        let appElement = AXUIElementCreateApplication(pid)
        let all = AXClient.elementArrayAttribute(appElement, kAXWindowsAttribute as String)
        return all.filter { element in
            AXClient.stringAttribute(element, kAXSubroleAttribute as String) == (kAXStandardWindowSubrole as String)
        }
    }

    /// AXUIElement から `AppWindow` を生成し、id → 実体のキャッシュを更新する。
    private func makeWindow(element: AXUIElement, pid: pid_t, appName: String, index: Int) -> AppWindow {
        let title = AXClient.stringAttribute(element, kAXTitleAttribute as String) ?? ""
        let minimized = AXClient.boolAttribute(element, kAXMinimizedAttribute as String)

        // CGWindowID が取れれば安定 ID、取れなければ pid+index でフォールバック
        let cgWindowID = AXClient.windowNumber(element)
        let id: String
        if let number = cgWindowID {
            id = "\(pid)-\(number)"
        } else {
            id = "\(pid)-idx\(index)"
        }
        windowCache[id] = element

        return AppWindow(
            id: id,
            ownerPID: pid,
            ownerName: appName,
            title: title,
            isMinimized: minimized,
            spaceNumber: nil,
            windowID: cgWindowID
        )
    }
}
