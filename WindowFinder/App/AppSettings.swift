//
//  AppSettings.swift
//  WindowFinder
//
//  App: 設定値のキー・列挙・既定値
//

import Foundation

/// UserDefaults のキー。設定画面と各画面で共有する。
enum SettingsKey {
    static let sortOrder = "sortOrder"
    static let thumbnailHeight = "thumbnailHeight"
    static let gridColumns = "gridColumns"
    static let panelWidth = "panelWidth"
    static let panelHeight = "panelHeight"
    static let autoScroll = "autoScroll"
}

/// 外部リンク
enum AppLinks {
    /// 開発支援（Buy Me a Coffee）
    static let support = URL(string: "https://buymeacoffee.com/joqnorandev")!
}

/// 既定値
enum SettingsDefault {
    static let thumbnailHeight: Double = 130
    static let gridColumns: Int = 4
    static let panelWidth: Double = 1000
    static let panelHeight: Double = 720
}

/// 一覧の並び順
enum WindowSortOrder: String, CaseIterable, Identifiable {
    case windowCount   // ウィンドウ数が多いアプリ順
    case appName       // アプリ名順

    var id: String { rawValue }

    var label: String {
        switch self {
        case .windowCount: return "ウィンドウ数が多い順"
        case .appName: return "アプリ名順"
        }
    }
}

extension UserDefaults {
    /// 既定値を登録する（初回起動時の値）。
    func registerWindowFinderDefaults() {
        register(defaults: [
            SettingsKey.sortOrder: WindowSortOrder.windowCount.rawValue,
            SettingsKey.thumbnailHeight: SettingsDefault.thumbnailHeight,
            SettingsKey.gridColumns: SettingsDefault.gridColumns,
            SettingsKey.autoScroll: true,
        ])
    }

    var windowSortOrder: WindowSortOrder {
        WindowSortOrder(rawValue: string(forKey: SettingsKey.sortOrder) ?? "") ?? .windowCount
    }
}
