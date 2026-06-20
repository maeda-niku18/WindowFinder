//
//  SettingsView.swift
//  WindowFinder
//
//  設定ウィンドウ。
//

import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label(L10n.string("settings.tab.general"), systemImage: "slider.horizontal.3") }
            ShortcutSettingsView()
                .tabItem { Label(L10n.string("settings.tab.shortcuts"), systemImage: "keyboard") }
            MarkdownHelpView(resource: "Help")
                .tabItem { Label(L10n.string("settings.tab.help"), systemImage: "questionmark.circle") }
            AboutSettingsView()
                .tabItem { Label(L10n.string("settings.tab.about"), systemImage: "info.circle") }
        }
        .frame(width: 560, height: 440)
    }
}

// MARK: - 一般

private struct GeneralSettingsView: View {
    @AppStorage(SettingsKey.sortOrder) private var sortOrder: String = WindowSortOrder.windowCount.rawValue
    @AppStorage(SettingsKey.thumbnailHeight) private var thumbnailHeight: Double = SettingsDefault.thumbnailHeight
    @AppStorage(SettingsKey.gridColumns) private var columns: Int = SettingsDefault.gridColumns
    @AppStorage(SettingsKey.windowHeight) private var windowHeight: Double = SettingsDefault.windowHeight
    @AppStorage(SettingsKey.autoScroll) private var autoScroll: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Picker(L10n.string("settings.sortOrder"), selection: $sortOrder) {
                ForEach(WindowSortOrder.allCases) { order in
                    Text(order.label).tag(order.rawValue)
                }
            }
            .pickerStyle(.menu)
            .fixedSize()

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.string("settings.thumbnailSize"))
                Slider(value: $thumbnailHeight, in: 90...240, step: 10) {
                    EmptyView()
                } minimumValueLabel: { Text(L10n.string("settings.size.small")) } maximumValueLabel: { Text(L10n.string("settings.size.large")) }
            }

            Stepper(L10n.format("settings.columns", columns), value: $columns, in: 2...6)
                .fixedSize()

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.format("settings.windowHeight", Int(windowHeight)))
                Slider(value: $windowHeight,
                       in: FinderMetrics.minHeight...FinderMetrics.maxHeight, step: 20) {
                    EmptyView()
                } minimumValueLabel: { Text(L10n.string("settings.height.low")) } maximumValueLabel: { Text(L10n.string("settings.height.high")) }
            }

            Toggle(L10n.string("settings.autoScroll"), isOn: $autoScroll)

            Text(L10n.string("settings.widthDescription"))
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
                Text(L10n.string("settings.showFinderShortcut"))
                KeyboardShortcuts.Recorder(for: .toggleFinder)
            }
            Text(L10n.string("settings.shortcutDescription"))
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .font(.title3)
        .controlSize(.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }
}

// MARK: - このアプリについて

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
                        Text(L10n.format("settings.version", version)).font(.callout).foregroundStyle(.secondary)
                    }
                }

                Divider()

                Link(destination: AppLinks.support) {
                    Label(L10n.string("settings.supportDevelopment"), systemImage: "cup.and.saucer.fill")
                        .font(.title3.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.orange)

                Divider()

                Text(L10n.string("settings.openSourceLicenses")).font(.title3.bold())
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
