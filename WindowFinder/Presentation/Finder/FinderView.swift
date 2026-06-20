//
//  FinderView.swift
//  WindowFinder
//
//  検索欄とサムネイルグリッドを持つファインダーパネル。
//

import SwiftUI

struct FinderView: View {
    @ObservedObject var viewModel: FinderViewModel
    /// ウィンドウを呼び出した後に実行する。
    var onActivated: () -> Void = {}
    /// ウィンドウを呼び出さずにパネルを閉じるときに実行する。
    var onDismiss: () -> Void = {}

    @FocusState private var searchFocused: Bool

    @AppStorage(SettingsKey.thumbnailHeight) private var thumbnailHeight: Double = SettingsDefault.thumbnailHeight
    @AppStorage(SettingsKey.gridColumns) private var columns: Int = SettingsDefault.gridColumns
    @AppStorage(SettingsKey.autoScroll) private var autoScroll: Bool = true

    private var cardWidth: CGFloat {
        FinderMetrics.cardWidth(thumbnailHeight: thumbnailHeight)
    }

    private var panelWidth: CGFloat {
        FinderMetrics.panelWidth(columns: columns, thumbnailHeight: thumbnailHeight)
    }

    private var gridColumns: [GridItem] {
        // カード幅を固定し、キーボード操作とスクロール位置を安定させる。
        Array(repeating: GridItem(.fixed(cardWidth), spacing: FinderMetrics.spacing), count: max(columns, 1))
    }

    var body: some View {
        VStack(spacing: 0) {
            SearchField(text: $viewModel.query, focused: $searchFocused)
            Divider()
            content
        }
        .frame(width: panelWidth)
        .frame(maxHeight: .infinity)
        .onAppear {
            viewModel.refresh()
            searchFocused = true
        }
        // 再表示したパネルでも検索欄へフォーカスを戻す。
        .onChange(of: viewModel.focusTrigger) { _, _ in
            searchFocused = true
        }
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.isPermitted {
            PermissionView(
                title: L10n.string("permission.accessibility.title"),
                message: L10n.string("permission.accessibility.message"),
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
            Text(L10n.string(viewModel.isSearching ? "finder.empty.search" : "finder.empty.windows"))
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
                Text(L10n.string("finder.screenCaptureHint"))
                    .font(.caption)
                Spacer()
                Text(L10n.string("common.allow")).font(.caption.weight(.semibold))
            }
            .padding(8)
            .background(.yellow.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.top, 12)
    }
}
