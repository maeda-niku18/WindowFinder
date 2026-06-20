//
//  AppWindow.swift
//  WindowFinder
//
//  アプリケーションウィンドウのドメインエンティティ。
//

import Foundation

/// アプリで扱うウィンドウ情報を保持する値型。
struct AppWindow: Identifiable, Equatable, Hashable {
    /// データ層でAXUIElementを再取得するための安定ID。
    let id: String
    /// 所有アプリのプロセスID。
    let ownerPID: pid_t
    /// 所有アプリの表示名。
    let ownerName: String
    /// ウィンドウタイトル。無題の場合は空文字になる。
    let title: String
    /// 最小化されているかどうか。
    let isMinimized: Bool
    /// 取得できた場合のSpace番号。
    let spaceNumber: Int?
    /// サムネイル取得に使うCGWindowID。
    let windowID: UInt32?

    /// 画面に表示するタイトル。
    var displayTitle: String {
        title.isEmpty ? L10n.string("window.untitled") : title
    }
}
