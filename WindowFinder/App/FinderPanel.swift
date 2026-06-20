//
//  FinderPanel.swift
//  WindowFinder
//
//  ファインダーを表示する浮遊パネル。
//

import AppKit
import SwiftUI

/// グローバルショートカットで中央に出る、⌘Tab 風のフローティング HUD。
/// メニューバーエージェントでも前面表示できるようNSPanelを使う。
final class FinderPanel: NSPanel {

    init(rootView: FinderView) {
        // .resizable を付けないことでユーザーのドラッグによるリサイズを禁止する。
        // サイズは設定値から決まり、ユーザー操作では変更させない。
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 720),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        // 全 Space で前面に出し、フルスクリーンアプリ上にも重ねる
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        animationBehavior = .utilityWindow

        // 角丸 + 半透明マテリアル背景の上に SwiftUI を載せる
        let blur = NSVisualEffectView()
        blur.material = .hudWindow
        blur.state = .active
        blur.blendingMode = .behindWindow
        blur.wantsLayer = true
        blur.layer?.cornerRadius = 16
        blur.layer?.masksToBounds = true

        let hosting = NSHostingView(rootView: rootView)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        blur.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: blur.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: blur.bottomAnchor),
            hosting.leadingAnchor.constraint(equalTo: blur.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: blur.trailingAnchor)
        ])

        contentView = blur
    }

    // 検索フィールド入力のためキーウィンドウになれるようにする
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
