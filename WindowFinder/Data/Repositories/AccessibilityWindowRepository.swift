//
//  AccessibilityWindowRepository.swift
//  WindowFinder
//
//  AccessibilityとCGWindowListを併用するウィンドウリポジトリ。
//

import ApplicationServices
import AppKit
import CoreGraphics

/// ウィンドウ情報の取得と呼び出しを行う。
///
/// 基本は Accessibility を使う（最小化状態や正確なタイトルが取れる）。
/// ただし Electron 系（VS Code 等）やプレビューは AX からウィンドウを取得できないため、
/// 「AX が 1 つもウィンドウを返さないアプリ」に限り CGWindowList で補完する。
final class AccessibilityWindowRepository: WindowRepositoryProtocol {

    /// AppWindow.idに対応するAXUIElementのキャッシュ（AXで取得できたウィンドウのみ）。
    private var windowCache: [String: AXUIElement] = [:]

    // MARK: - 起動中のアプリ

    func fetchRunningApps() -> [RunningApp] {
        let cg = cgWindowsByPID()
        return regularApplications().map { app in
            let pid = app.processIdentifier
            let count = mergedWindows(
                forPID: pid,
                appName: app.localizedName ?? "",
                cgWindows: cg[pid] ?? []
            ).count
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
        return mergedWindows(forPID: pid, appName: appName, cgWindows: cgWindowsByPID()[pid] ?? [])
    }

    // MARK: - すべてのウィンドウ

    func fetchAllWindows() -> [AppWindow] {
        windowCache.removeAll(keepingCapacity: true)
        let cg = cgWindowsByPID()
        return regularApplications().flatMap { app -> [AppWindow] in
            mergedWindows(forPID: app.processIdentifier,
                          appName: app.localizedName ?? "",
                          cgWindows: cg[app.processIdentifier] ?? [])
        }
    }

    // MARK: - ウィンドウの呼び出し

    @discardableResult
    func activate(_ window: AppWindow) -> Bool {
        // AX 要素があれば、最小化解除・前面化まで正確に行う。
        if let element = windowCache[window.id] {
            if AXClient.boolAttribute(element, kAXMinimizedAttribute as String) {
                AXClient.setBool(element, kAXMinimizedAttribute as String, false)
            }
            AXClient.perform(element, kAXRaiseAction as String)
        }
        // AX 要素が無い（CGWindowListのみで見つかった）ウィンドウは、
        // 個別の前面化はできないため、所有アプリをアクティブにして前面へ出す。
        return NSRunningApplication(processIdentifier: window.ownerPID)?
            .activate(options: [.activateAllWindows]) ?? false
    }

    // MARK: - ヘルパー

    /// 通常の前面アプリを返す。Window Finder自身は除外する。
    private func regularApplications() -> [NSRunningApplication] {
        let selfPID = ProcessInfo.processInfo.processIdentifier
        return NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && $0.processIdentifier != selfPID
        }
    }

    /// AX を基本とし、AX が空のアプリのみ CGWindowList で補完したウィンドウ一覧。
    private func mergedWindows(forPID pid: pid_t, appName: String, cgWindows: [CGWindowInfo]) -> [AppWindow] {
        // 1) AX 由来（通常ウィンドウのみ）。
        let elements = axWindowElements(forPID: pid)
        let axWindows = elements.enumerated().map { index, element in
            makeAXWindow(element: element, pid: pid, appName: appName, index: index)
        }

        if !axWindows.isEmpty {
            return axWindows
        }

        // 2) AX が 0 のアプリのみ CGWindowList で補完。
        //    実ウィンドウだけを残すため、十分な大きさ（細い帯や小物を除外）で絞る。
        //    さらに「現在画面に出ているウィンドウ」(kCGWindowIsOnscreen) に限定する。
        //    .optionAll はオフスクリーンの内部ウィンドウまで返すため、これを入れないと
        //    テキストエディット等の「閉じたのに残る名前なし幽霊ウィンドウ」を拾ってしまう。
        let fallback = cgWindows
            .filter { $0.isOnScreen && $0.width >= 200 && $0.height >= 200 }
            .map { cg -> AppWindow in
                let title = cg.name.trimmingCharacters(in: .whitespacesAndNewlines)
                return AppWindow(
                    id: "\(pid)-\(cg.id)",
                    ownerPID: pid,
                    ownerName: appName,
                    // CGはタイトルを返さないことが多いので、無ければアプリ名で代用。
                    title: title.isEmpty ? appName : title,
                    isMinimized: false,
                    spaceNumber: nil,
                    windowID: cg.id
                )
            }
        return fallback
    }

    /// 指定プロセスの AX 通常ウィンドウ要素（ポップオーバー等は除外）。
    private func axWindowElements(forPID pid: pid_t) -> [AXUIElement] {
        let appElement = AXUIElementCreateApplication(pid)
        let all = AXClient.elementArrayAttribute(appElement, kAXWindowsAttribute as String)
        return all.filter { element in
            AXClient.stringAttribute(element, kAXSubroleAttribute as String) == (kAXStandardWindowSubrole as String)
        }
    }

    /// AX要素から AppWindow を生成し、AXUIElementのキャッシュを更新する。
    private func makeAXWindow(element: AXUIElement, pid: pid_t, appName: String, index: Int) -> AppWindow {
        let title = AXClient.stringAttribute(element, kAXTitleAttribute as String) ?? ""
        let minimized = AXClient.boolAttribute(element, kAXMinimizedAttribute as String)

        let cgWindowID = AXClient.windowNumber(element)
        let id = cgWindowID.map { "\(pid)-\($0)" } ?? "\(pid)-idx\(index)"
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

    // MARK: - CGWindowList

    /// CGWindowListの1ウィンドウ分の情報。
    private struct CGWindowInfo {
        let id: UInt32
        let name: String
        let width: Double
        let height: Double
        /// 現在いずれかの画面に表示されているか（kCGWindowIsOnscreen）。
        /// オフスクリーンの内部ウィンドウ（閉じたアプリの残骸など）を除外するために使う。
        let isOnScreen: Bool
    }

    /// 画面上の通常ウィンドウ（レイヤー0）を pid 別に集計する。
    private func cgWindowsByPID() -> [pid_t: [CGWindowInfo]] {
        let infoList = CGWindowListCopyWindowInfo([.optionAll, .excludeDesktopElements], kCGNullWindowID)
            as? [[String: Any]] ?? []
        var result: [pid_t: [CGWindowInfo]] = [:]

        for info in infoList {
            guard (info[kCGWindowLayer as String] as? Int) == 0 else { continue }
            guard let pid = info[kCGWindowOwnerPID as String] as? pid_t else { continue }
            guard let number = info[kCGWindowNumber as String] as? UInt32 else { continue }

            let alpha = (info[kCGWindowAlpha as String] as? Double) ?? 1
            guard alpha > 0.1 else { continue }

            var w = 0.0, h = 0.0
            if let bounds = info[kCGWindowBounds as String] as? [String: Any] {
                w = bounds["Width"] as? Double ?? 0
                h = bounds["Height"] as? Double ?? 0
            }
            let name = (info[kCGWindowName as String] as? String) ?? ""
            // kCGWindowIsOnscreen はオフスクリーン時にキー自体が無いため、無ければ false 扱い。
            let isOnScreen = (info[kCGWindowIsOnscreen as String] as? Bool) ?? false
            result[pid, default: []].append(
                CGWindowInfo(id: number, name: name, width: w, height: h, isOnScreen: isOnScreen)
            )
        }
        return result
    }
}
