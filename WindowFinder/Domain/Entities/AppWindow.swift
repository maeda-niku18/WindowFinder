//
//  AppWindow.swift
//  WindowFinder
//
//  Domain Entity: 個々のウィンドウ
//

import Foundation

/// アプリが保持する 1 つのウィンドウを表すドメインエンティティ。
/// 実体（AXUIElement）への参照は Data 層が `id` で解決するため、
/// ここでは UI 層に必要な情報のみを保持する。
struct AppWindow: Identifiable, Equatable, Hashable {
    /// Data 層が AXUIElement を再解決するための安定 ID
    let id: String
    /// 所有アプリのプロセス ID
    let ownerPID: pid_t
    /// 所有アプリ名（検索・グルーピング用）
    let ownerName: String
    /// ウィンドウタイトル（無題のときは空文字）
    let title: String
    /// 最小化されているか
    let isMinimized: Bool
    /// Space 番号（公開 API では取得困難なため現状は nil。将来対応）
    let spaceNumber: Int?
    /// CGWindowID（サムネイル取得・突合に使用。取得不可なら nil）
    let windowID: UInt32?

    /// 表示用タイトル（無題ウィンドウのフォールバック付き）
    var displayTitle: String {
        title.isEmpty ? "（無題のウィンドウ）" : title
    }
}
