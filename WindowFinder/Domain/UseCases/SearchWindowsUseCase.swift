//
//  SearchWindowsUseCase.swift
//  WindowFinder
//
//  アプリ名とウィンドウタイトルで検索するユースケース。
//

import Foundation

/// アプリ単位でグルーピングした検索結果。
struct WindowSearchResult: Identifiable, Equatable {
    let app: RunningApp
    let windows: [AppWindow]
    var id: pid_t { app.id }
}

protocol SearchWindowsUseCase {
    /// - Parameters:
    ///   - query: 検索文字列。空の場合は全件をアプリ単位で返す。
    ///   - apps: 起動中アプリ一覧
    ///   - windows: 全ウィンドウ一覧
    func callAsFunction(query: String, apps: [RunningApp], windows: [AppWindow]) -> [WindowSearchResult]
}

struct SearchWindowsUseCaseImpl: SearchWindowsUseCase {
    func callAsFunction(query: String, apps: [RunningApp], windows: [AppWindow]) -> [WindowSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let bundleByPID = Dictionary(apps.map { ($0.id, $0.bundleIdentifier) }, uniquingKeysWith: { a, _ in a })

        // ウィンドウ単位で判定：
        //   - アプリ名
        //   - ウィンドウタイトル
        //   - バンドルID
        // のいずれかに部分一致すればヒット。
        func matches(_ w: AppWindow) -> Bool {
            guard !trimmed.isEmpty else { return true }
            if w.ownerName.localizedCaseInsensitiveContains(trimmed) { return true }
            if w.title.localizedCaseInsensitiveContains(trimmed) { return true }
            if let bundle = bundleByPID[w.ownerPID] ?? nil,
               bundle.localizedCaseInsensitiveContains(trimmed) { return true }
            return false
        }

        let matched = windows.filter(matches)
        let matchedByPID = Dictionary(grouping: matched, by: { $0.ownerPID })

        // apps の並び順を維持してグルーピング
        return apps.compactMap { app in
            guard let appWindows = matchedByPID[app.id], !appWindows.isEmpty else { return nil }
            return WindowSearchResult(app: app, windows: appWindows)
        }
    }
}
