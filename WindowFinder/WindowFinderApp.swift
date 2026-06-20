//
//  WindowFinderApp.swift
//  WindowFinder
//
//  メニューバー常駐アプリのエントリポイント。
//

import SwiftUI

@main
struct WindowFinderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // 探索UIも設定ウィンドウもAppDelegate側でNSWindowまたはNSPanelとして管理する。
        // LSUIElementのエージェントアプリではSettingsシーンを安定して開きにくい。
        Settings {
            EmptyView()
        }
    }
}
