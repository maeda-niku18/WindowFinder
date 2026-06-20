//
//  AppDelegate.swift
//  WindowFinder
//
//  App: メニューバー常駐・ショートカット・パネル制御の中枢
//

import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    private enum Keys {
        static let panelWidth = "panelWidth"
        static let panelHeight = "panelHeight"
    }

    private let container = AppContainer()
    private let hotKeyService = HotKeyService()
    private let updaterService = UpdaterService()

    private var statusItem: NSStatusItem?
    private var panel: FinderPanel?
    private var viewModel: FinderViewModel?
    private var keyMonitor: Any?
    private var settingsWindow: NSWindow?
    /// 表示直後のアクティベーション揺れで即閉じしないための抑制フラグ
    private var suppressAutoHide = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.registerWindowFinderDefaults()
        setupStatusItem()
        setupHotKey()
        setupKeyMonitor()
    }

    // MARK: - メニューバー

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        // ウィンドウ＋虫眼鏡のテンプレート画像（ライト/ダーク自動対応）
        item.button?.image = AppIconArtwork.menuBarImage()

        let menu = NSMenu()
        menu.addItem(
            withTitle: "ウィンドウを探す  (⌃⌥Space)",
            action: #selector(togglePanel),
            keyEquivalent: ""
        ).target = self
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "アップデートを確認…",
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        ).target = self
        menu.addItem(
            withTitle: "☕ 開発を支援する",
            action: #selector(openSupport),
            keyEquivalent: ""
        ).target = self
        menu.addItem(
            withTitle: "設定…",
            action: #selector(openSettings),
            keyEquivalent: ","
        ).target = self
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "終了",
            action: #selector(quit),
            keyEquivalent: "q"
        ).target = self

        item.menu = menu
        statusItem = item
    }

    // MARK: - グローバルショートカット（機能4）

    private func setupHotKey() {
        hotKeyService.onTrigger = { [weak self] in
            self?.togglePanel()
        }
        hotKeyService.registerDefault()
    }

    // MARK: - キーボード操作（ランチャー風ナビゲーション）

    /// パネル表示中の矢印 / Enter / Esc を横取りして ViewModel を駆動する。
    /// 検索フィールドが左右矢印を消費する問題を避けるため、イベント段階で処理する。
    private func setupKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self,
                  let panel = self.panel, panel.isVisible,
                  let vm = self.viewModel
            else { return event }

            switch event.keyCode {
            case 123: vm.moveSelection(.left);  return nil
            case 124: vm.moveSelection(.right); return nil
            case 125: vm.moveSelection(.down);  return nil
            case 126: vm.moveSelection(.up);    return nil
            case 36, 76: // Return / Enter
                if vm.activateSelected() { panel.orderOut(nil) }
                return nil
            case 53: // Escape
                panel.orderOut(nil)
                return nil
            default:
                return event
            }
        }
    }

    // MARK: - パネル制御

    @objc private func togglePanel() {
        // 表示中に押したら「隠す」のではなく「最新情報へ再取得」する。
        // 押した時点の起動中アプリ・ウィンドウ・サムネイルに更新される。（閉じるのは Esc）
        if let panel, panel.isVisible {
            armAutoHide()
            viewModel?.refresh()
            NSApp.activate(ignoringOtherApps: true)
            panel.makeKeyAndOrderFront(nil)
            return
        }
        showPanel()
    }

    private func showPanel() {
        let panel = ensurePanel()
        armAutoHide()
        viewModel?.refresh()

        // 前回選んだサイズを復元（大きいまま使い続けられる）
        let defaults = UserDefaults.standard
        var size = panel.frame.size
        let savedW = defaults.double(forKey: Keys.panelWidth)
        let savedH = defaults.double(forKey: Keys.panelHeight)
        if savedW > 0, savedH > 0 {
            size = NSSize(
                width: max(savedW, panel.minSize.width),
                height: max(savedH, panel.minSize.height)
            )
        }

        // アクティブ Space の中央付近に、復元したサイズで表示
        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            let origin = NSPoint(
                x: frame.midX - size.width / 2,
                y: frame.midY - size.height / 2
            )
            panel.setFrame(NSRect(origin: origin, size: size), display: true)
        } else {
            panel.setContentSize(size)
        }

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    // ユーザーがリサイズしたサイズを記憶する
    func windowDidEndLiveResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window === panel else { return }
        let defaults = UserDefaults.standard
        defaults.set(window.frame.size.width, forKey: Keys.panelWidth)
        defaults.set(window.frame.size.height, forKey: Keys.panelHeight)
    }

    // フォーカスが外れたらファインダーを閉じる（Spotlight 風）。
    func windowDidResignKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window === panel else { return }
        guard !suppressAutoHide else { return }
        panel?.orderOut(nil)
    }

    /// 表示直後の一瞬だけ自動クローズを抑制する。
    private func armAutoHide() {
        suppressAutoHide = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.suppressAutoHide = false
        }
    }

    private func ensurePanel() -> FinderPanel {
        if let panel { return panel }
        let vm = container.makeFinderViewModel()
        let view = FinderView(
            viewModel: vm,
            onActivated: { [weak self] in self?.panel?.orderOut(nil) },
            onDismiss: { [weak self] in self?.panel?.orderOut(nil) }
        )
        let panel = FinderPanel(rootView: view)
        panel.delegate = self
        self.viewModel = vm
        self.panel = panel
        return panel
    }

    @objc private func openSettings() {
        // パネルが開いていれば閉じる（フォーカスが移るため）
        panel?.orderOut(nil)

        if settingsWindow == nil {
            let hosting = NSHostingController(rootView: SettingsView())
            let window = NSWindow(contentViewController: hosting)
            window.title = "Window Finder 設定"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }

        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func checkForUpdates() {
        updaterService.checkForUpdates()
    }

    @objc private func openSupport() {
        NSWorkspace.shared.open(AppLinks.support)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
