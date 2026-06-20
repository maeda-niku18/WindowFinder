//
//  FinderPanel.swift
//  WindowFinder
//
//  App: ランチャー風の浮遊パネル（ボーダーレス HUD）
//

import AppKit
import SwiftUI

/// グローバルショートカットで中央に出る、⌘Tab 風のフローティング HUD。
/// メニューバーエージェント（LSUIElement）なのでパネル（非アクティブ化対応）を用いる。
final class FinderPanel: NSPanel {

    init(rootView: FinderView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 720),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        minSize = NSSize(width: 720, height: 520)
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
