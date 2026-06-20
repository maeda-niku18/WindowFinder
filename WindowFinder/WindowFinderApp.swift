//
//  WindowFinderApp.swift
//  WindowFinder
//
//  App: エントリポイント（メニューバー常駐エージェント）
//

import SwiftUI

@main
struct WindowFinderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // 探索 UI も設定ウィンドウも AppDelegate 側で NSWindow/NSPanel として管理する
        // （LSUIElement のエージェントアプリでは Settings シーンが開きにくいため）。
        Settings {
            EmptyView()
        }
    }
}
