//
//  AppSettings.swift
//  WindowFinder
//
//  設定キー、既定値、アプリ共通の定数。
//

import Foundation

/// 設定画面と実行時の画面で共有するUserDefaultsキー。
enum SettingsKey {
    static let sortOrder = "sortOrder"
    static let thumbnailHeight = "thumbnailHeight"
    static let gridColumns = "gridColumns"
    /// 設定で管理するファインダーパネルの高さ。
    static let windowHeight = "panelHeight"
    static let autoScroll = "autoScroll"
}

/// 外部リンク。
enum AppLinks {
    /// 開発支援ページ。
    static let support = URL(string: "https://buymeacoffee.com/joqnorandev")!
}

/// 既定値。
enum SettingsDefault {
    static let thumbnailHeight: Double = 130
    static let gridColumns: Int = 4
    static let windowHeight: Double = 720
}

/// ウィンドウ一覧の並び順。
enum WindowSortOrder: String, CaseIterable, Identifiable {
    case windowCount
    case appName

    var id: String { rawValue }

    var label: String {
        switch self {
        case .windowCount: return L10n.string("sort.windowCount")
        case .appName: return L10n.string("sort.appName")
        }
    }
}

extension UserDefaults {
    /// 初回起動時に使う既定値を登録する。
    func registerWindowFinderDefaults() {
        register(defaults: [
            SettingsKey.sortOrder: WindowSortOrder.windowCount.rawValue,
            SettingsKey.thumbnailHeight: SettingsDefault.thumbnailHeight,
            SettingsKey.gridColumns: SettingsDefault.gridColumns,
            SettingsKey.windowHeight: SettingsDefault.windowHeight,
            SettingsKey.autoScroll: true,
        ])
    }

    var windowSortOrder: WindowSortOrder {
        WindowSortOrder(rawValue: string(forKey: SettingsKey.sortOrder) ?? "") ?? .windowCount
    }
}
