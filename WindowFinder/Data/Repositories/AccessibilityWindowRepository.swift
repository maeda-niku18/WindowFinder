//
//  AccessibilityWindowRepository.swift
//  WindowFinder
//
//  AccessibilityとNSWorkspaceを使うウィンドウリポジトリ。
//

import ApplicationServices
import AppKit

/// Accessibility APIを使ってウィンドウ情報の取得と呼び出しを行う。
final class AccessibilityWindowRepository: WindowRepositoryProtocol {

    /// AppWindow.idに対応するAXUIElementのキャッシュ。
    private var windowCache: [String: AXUIElement] = [:]

    // MARK: - 起動中のアプリ

    func fetchRunningApps() -> [RunningApp] {
        regularApplications().map { app in
            let pid = app.processIdentifier
            let count = windowElements(forPID: pid).count
            return RunningApp(
                id: pid,
                bundleIdentifier: app.bundleIdentifier,
                name: app.localizedName ?? app.bundleIdentifier ?? L10n.string("app.unknown"),
                windowCount: count
            )
        }
    }

    // MARK: - アプリ別のウィンドウ

    func fetchWindows(for pid: pid_t) -> [AppWindow] {
        let appName = NSRunningApplication(processIdentifier: pid)?.localizedName ?? ""
        let elements = windowElements(forPID: pid)
        return elements.enumerated().map { index, element in
            makeWindow(element: element, pid: pid, appName: appName, index: index)
        }
    }

    // MARK: - すべてのウィンドウ

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

    // MARK: - ウィンドウの呼び出し

    @discardableResult
    func activate(_ window: AppWindow) -> Bool {
        guard let element = windowCache[window.id] else { return false }

        // 最小化されている場合は、前面に出す前に復元する。
        if AXClient.boolAttribute(element, kAXMinimizedAttribute as String) {
            AXClient.setBool(element, kAXMinimizedAttribute as String, false)
        }

        // 所有アプリの中で対象ウィンドウを前面に出す。
        AXClient.perform(element, kAXRaiseAction as String)

        // 所有アプリをアクティブにし、必要ならmacOSにSpaceを切り替えさせる。
        let activated = NSRunningApplication(processIdentifier: window.ownerPID)?
            .activate(options: [.activateAllWindows]) ?? false

        return activated
    }

    // MARK: - ヘルパー

    /// 通常の前面アプリを返す。Window Finder自身は除外する。
    private func regularApplications() -> [NSRunningApplication] {
        let selfPID = ProcessInfo.processInfo.processIdentifier
        return NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && $0.processIdentifier != selfPID
        }
    }

    /// 指定したプロセスが持つ通常ウィンドウを返す。
    ///
    /// ポップオーバーやツールチップなどは呼び出し対象として扱わない。
    private func windowElements(forPID pid: pid_t) -> [AXUIElement] {
        let appElement = AXUIElementCreateApplication(pid)
        let all = AXClient.elementArrayAttribute(appElement, kAXWindowsAttribute as String)
        return all.filter { element in
            AXClient.stringAttribute(element, kAXSubroleAttribute as String) == (kAXStandardWindowSubrole as String)
        }
    }

    /// AppWindowを生成し、対応するAXUIElementのキャッシュを更新する。
    private func makeWindow(element: AXUIElement, pid: pid_t, appName: String, index: Int) -> AppWindow {
        let title = AXClient.stringAttribute(element, kAXTitleAttribute as String) ?? ""
        let minimized = AXClient.boolAttribute(element, kAXMinimizedAttribute as String)

        // 取得できる場合はCGWindowIDを使い、取得できない場合は現在の一覧内の番号で代用する。
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
