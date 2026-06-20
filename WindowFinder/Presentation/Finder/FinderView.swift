//
//  FinderView.swift
//  WindowFinder
//
//  Presentation: ランチャー風ファインダー（サムネイルグリッド + キーボード操作）
//

import SwiftUI

struct FinderView: View {
    @ObservedObject var viewModel: FinderViewModel
    /// ウィンドウ呼び出し後にパネルを閉じるためのコールバック
    var onActivated: () -> Void = {}
    /// Esc などで閉じるためのコールバック
    var onDismiss: () -> Void = {}

    @FocusState private var searchFocused: Bool

    @AppStorage(SettingsKey.thumbnailHeight) private var thumbnailHeight: Double = SettingsDefault.thumbnailHeight
    @AppStorage(SettingsKey.gridColumns) private var columns: Int = SettingsDefault.gridColumns
    @AppStorage(SettingsKey.autoScroll) private var autoScroll: Bool = true

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: max(columns, 1))
    }

    var body: some View {
        VStack(spacing: 0) {
            SearchField(text: $viewModel.query, focused: $searchFocused)
            Divider()
            content
        }
        .frame(minWidth: 720, idealWidth: 1000, maxWidth: .infinity,
               minHeight: 520, idealHeight: 720, maxHeight: .infinity)
        .onAppear {
            viewModel.refresh()
            searchFocused = true
        }
        // 開くたび（パネル再利用時）に検索欄へフォーカスを戻す
        .onChange(of: viewModel.focusTrigger) { _, _ in
            searchFocused = true
        }
        // 矢印 / Enter / Esc は AppDelegate のローカルイベントモニタで横取りして駆動する
        // （単一行 TextField が左右矢印を消費してしまう問題を回避するため）
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.isPermitted {
            PermissionView(
                title: "アクセシビリティ権限が必要です",
                message: "他アプリのウィンドウを一覧表示・前面化するために、\nアクセシビリティ権限を許可してください。",
                onRequest: { viewModel.requestAccessibilityPermission() },
                onRecheck: { viewModel.refresh() }
            )
        } else if viewModel.items.isEmpty {
            emptyState
        } else {
            grid
        }
    }

    private var grid: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if !viewModel.isScreenCapturePermitted {
                    screenCaptureHint
                }
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, window in
                        WindowCardView(
                            window: window,
                            thumbnail: window.windowID.flatMap { viewModel.thumbnails[$0] },
                            thumbnailHeight: thumbnailHeight,
                            isSelected: index == viewModel.selectedIndex,
                            onActivate: {
                                if viewModel.activate(window) { onActivated() }
                            },
                            onHover: { viewModel.selectedIndex = index }
                        )
                        .id(index)
                    }
                }
                .padding(12)
            }
            .onChange(of: viewModel.selectedIndex) { _, newValue in
                // 自動スクロールが有効なときだけ、かつ画面外に出た時だけ最小限スクロールする
                // （anchor を指定しないと、可視範囲にあれば動かず、端で隠れた時だけ送られる）。
                guard autoScroll else { return }
                withAnimation(.easeOut(duration: 0.12)) {
                    proxy.scrollTo(newValue)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: viewModel.isSearching ? "magnifyingglass" : "macwindow.on.rectangle")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text(viewModel.isSearching ? "一致するウィンドウがありません" : "表示できるウィンドウがありません")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var screenCaptureHint: some View {
        Button {
            viewModel.requestScreenCapturePermission()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "photo.badge.exclamationmark")
                Text("サムネイルを表示するには画面収録権限を許可してください")
                    .font(.caption)
                Spacer()
                Text("許可").font(.caption.weight(.semibold))
            }
            .padding(8)
            .background(.yellow.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.top, 12)
    }
}
