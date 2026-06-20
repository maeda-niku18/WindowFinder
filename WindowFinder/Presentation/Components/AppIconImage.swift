//
//  AppIconImage.swift
//  WindowFinder
//
//  Presentation: pid からアプリアイコンを解決して表示する
//

import SwiftUI
import AppKit

/// プロセス ID から `NSRunningApplication.icon` を解決して表示する。
/// アイコン解決は AppKit 依存のため Presentation 層に閉じ込める。
struct AppIconImage: View {
    let pid: pid_t
    var size: CGFloat = 20

    var body: some View {
        Group {
            if let icon = NSRunningApplication(processIdentifier: pid)?.icon {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
            } else {
                Image(systemName: "app.dashed")
                    .resizable()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
    }
}
