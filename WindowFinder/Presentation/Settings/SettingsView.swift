//
//  SettingsView.swift
//  WindowFinder
//
//  Presentation: 設定画面（タブ構成）
//

import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("一般", systemImage: "slider.horizontal.3") }
            ShortcutSettingsView()
                .tabItem { Label("ショートカット", systemImage: "keyboard") }
            MarkdownHelpView(resource: "Help")
                .tabItem { Label("ヘルプ", systemImage: "questionmark.circle") }
            AboutSettingsView()
                .tabItem { Label("について", systemImage: "info.circle") }
        }
        .frame(width: 460, height: 420)
    }
}

// MARK: - 一般

private struct GeneralSettingsView: View {
    @AppStorage(SettingsKey.sortOrder) private var sortOrder: String = WindowSortOrder.windowCount.rawValue
    @AppStorage(SettingsKey.thumbnailHeight) private var thumbnailHeight: Double = SettingsDefault.thumbnailHeight
    @AppStorage(SettingsKey.gridColumns) private var columns: Int = SettingsDefault.gridColumns
    @AppStorage(SettingsKey.autoScroll) private var autoScroll: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Picker("表示順", selection: $sortOrder) {
                ForEach(WindowSortOrder.allCases) { order in
                    Text(order.label).tag(order.rawValue)
                }
            }
            .pickerStyle(.menu)
            .fixedSize()

            VStack(alignment: .leading, spacing: 4) {
                Text("サムネイルの大きさ")
                Slider(value: $thumbnailHeight, in: 90...240, step: 10) {
                    EmptyView()
                } minimumValueLabel: { Text("小") } maximumValueLabel: { Text("大") }
            }

            Stepper("列数: \(columns)", value: $columns, in: 2...6)
                .fixedSize()

            Toggle("選択に合わせて自動スクロールする", isOn: $autoScroll)

            Text("ウィンドウはドラッグでサイズ変更でき、その大きさは記憶されます。")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .font(.title3)
        .controlSize(.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }
}

// MARK: - ショートカット

private struct ShortcutSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("ファインダーを表示:")
                KeyboardShortcuts.Recorder(for: .toggleFinder)
            }
            Text("既定は ⌃⌥Space です（⌘⌥Space は macOS 標準と競合するため避けています）。")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .font(.title3)
        .controlSize(.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }
}

// MARK: - について / ライセンス

private struct AboutSettingsView: View {
    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "macwindow.on.rectangle").font(.largeTitle).foregroundStyle(.tint)
                    VStack(alignment: .leading) {
                        Text("Window Finder").font(.title2.bold())
                        Text("バージョン \(version)").font(.callout).foregroundStyle(.secondary)
                    }
                }

                Divider()

                Link(destination: AppLinks.support) {
                    Label("開発を支援する（Buy Me a Coffee）", systemImage: "cup.and.saucer.fill")
                        .font(.title3.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.orange)

                Divider()

                Text("オープンソースライセンス").font(.title3.bold())
                VStack(alignment: .leading, spacing: 4) {
                    Text("KeyboardShortcuts — MIT License")
                    Text("© Sindre Sorhus")
                        .font(.callout).foregroundStyle(.secondary)
                    Link("https://github.com/sindresorhus/KeyboardShortcuts",
                         destination: URL(string: "https://github.com/sindresorhus/KeyboardShortcuts")!)
                        .font(.callout)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
    }
}
