//
//  RunningApp.swift
//  WindowFinder
//
//  Domain Entity: 起動中アプリ
//

import Foundation

/// 起動中のアプリケーションを表すドメインエンティティ。
/// AppKit / Accessibility への依存を持たない純粋な値型。
struct RunningApp: Identifiable, Equatable, Hashable {
    /// 一覧内で一意になるプロセスID。
    let id: pid_t
    let bundleIdentifier: String?
    let name: String
    /// このアプリが保持するウィンドウ数
    let windowCount: Int

    var pid: pid_t { id }
}
