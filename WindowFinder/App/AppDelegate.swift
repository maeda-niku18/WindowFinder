//
//  AppDelegate.swift
//  WindowFinder
//
//  メニューバー、ショートカット、各ウィンドウを管理する。
//

import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    /// 設定値からパネルサイズを計算する。
    private var computedPanelSize: NSSize {
        let defaults = UserDefaults.standard
        let th = defaults.double(forKey: SettingsKey.thumbnailHeight)
        let cols = defaults.integer(forKey: SettingsKey.gridColumns)
        let h = defaults.double(forKey: SettingsKey.windowHeight)
        let width = FinderMetrics.panelWidth(
            columns: cols > 0 ? cols : SettingsDefault.gridColumns,
            thumbnailHeight: th > 0 ? th : SettingsDefault.thumbnailHeight
        )
        let height = h > 0 ? h : SettingsDefault.windowHeight
        return NSSize(width: width, height: height)
    }

    private let container = AppContainer()
    private let hotKeyService = HotKeyService()
    private let updaterService = UpdaterService()

    private var statusItem: NSStatusItem?
    private var panel: FinderPanel?
    private var viewModel: FinderViewModel?
    private var keyMonitor: Any?
    private var settingsWindow: NSWindow?
    /// 表示直後のアプリ切り替え中にパネルが閉じないようにする。
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
        // 現在の外観に追従するテンプレート画像を使う。
        item.button?.image = AppIconArtwork.menuBarImage()

        let menu = NSMenu()
        menu.addItem(
            withTitle: L10n.string("menu.findWindows"),
            action: #selector(togglePanel),
            keyEquivalent: ""
        ).target = self
        menu.addItem(.separator())
        menu.addItem(
            withTitle: L10n.string("menu.checkForUpdates"),
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        ).target = self
        menu.addItem(
            withTitle: L10n.string("menu.supportDevelopment"),
            action: #selector(openSupport),
            keyEquivalent: ""
        ).target = self
        menu.addItem(
            withTitle: L10n.string("menu.settings"),
            action: #selector(openSettings),
            keyEquivalent: ","
        ).target = self
        menu.addItem(.separator())
        menu.addItem(
            withTitle: L10n.string("menu.quit"),
            action: #selector(quit),
            keyEquivalent: "q"
        ).target = self

        item.menu = menu
        statusItem = item
    }

    // MARK: - グローバルショートカット

    private func setupHotKey() {
        hotKeyService.onTrigger = { [weak self] in
            self?.togglePanel()
        }
        hotKeyService.registerDefault()
    }

    // MARK: - キーボード操作

    /// パネル表示中の矢印キー、Enter、Escapeを処理する。
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
        // 表示中にショートカットを押した場合は、パネルを閉じずに一覧を更新する。
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

        let size = computedPanelSize

        // アクティブな画面の中央付近に表示する。
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

    // 他のウィンドウにフォーカスが移ったらパネルを閉じる。
    func windowDidResignKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window === panel else { return }
        guard !suppressAutoHide else { return }
        panel?.orderOut(nil)
    }

    /// macOSのアプリ切り替えが落ち着くまで自動クローズを一時停止する。
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
        // 設定ウィンドウへフォーカスが移るため、先にファインダーパネルを閉じる。
        panel?.orderOut(nil)

        if settingsWindow == nil {
            let hosting = NSHostingController(rootView: SettingsView())
            let window = NSWindow(contentViewController: hosting)
            window.title = L10n.string("settings.windowTitle")
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
