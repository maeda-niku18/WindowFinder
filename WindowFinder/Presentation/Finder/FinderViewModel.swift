//
//  FinderViewModel.swift
//  WindowFinder
//
//  ファインダーの状態と操作を管理するViewModel。
//

import Foundation
import AppKit
import Combine

@MainActor
final class FinderViewModel: ObservableObject {

    // MARK: - 表示状態

    /// 検索クエリ。
    @Published var query: String = ""
    /// グリッドに並べるウィンドウ候補。
    @Published private(set) var items: [AppWindow] = []
    /// キーボードで選択しているitems内の位置。
    @Published var selectedIndex: Int = 0
    /// windowID → サムネイル画像
    @Published private(set) var thumbnails: [UInt32: NSImage] = [:]
    /// アクセシビリティ権限が許可されているか。
    @Published private(set) var isPermitted: Bool = false
    /// 画面収録権限が許可されているか。
    @Published private(set) var isScreenCapturePermitted: Bool = false
    /// 検索欄へフォーカスを戻すためにViewへ通知する値。
    @Published private(set) var focusTrigger: Int = 0

    /// キーボード移動の計算に使うグリッド列数。
    var columns: Int {
        let v = UserDefaults.standard.integer(forKey: SettingsKey.gridColumns)
        return v > 0 ? v : SettingsDefault.gridColumns
    }

    // MARK: - 依存

    private let fetchRunningApps: FetchRunningAppsUseCase
    private let fetchWindows: FetchWindowsUseCase
    private let activateWindow: ActivateWindowUseCase
    private let searchWindows: SearchWindowsUseCase
    private let permission: PermissionRepositoryProtocol
    private let thumbnailProvider: WindowThumbnailProviding

    private var apps: [RunningApp] = []
    private var allWindows: [AppWindow] = []
    private var cancellables = Set<AnyCancellable>()
    private var thumbnailTask: Task<Void, Never>?

    init(
        fetchRunningApps: FetchRunningAppsUseCase,
        fetchWindows: FetchWindowsUseCase,
        activateWindow: ActivateWindowUseCase,
        searchWindows: SearchWindowsUseCase,
        permission: PermissionRepositoryProtocol,
        thumbnailProvider: WindowThumbnailProviding
    ) {
        self.fetchRunningApps = fetchRunningApps
        self.fetchWindows = fetchWindows
        self.activateWindow = activateWindow
        self.searchWindows = searchWindows
        self.permission = permission
        self.thumbnailProvider = thumbnailProvider

        $query
            .removeDuplicates()
            // クエリ変更通知の最中に items を更新すると SwiftUI が再描画を取りこぼすため、
            // ビュー更新と衝突しないよう、次のランループで再計算する。
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in self?.recomputeItems(query: text) }
            .store(in: &cancellables)
    }

    // MARK: - ライフサイクル

    /// パネル表示時に呼ぶ。検索欄リセット → 権限確認 → 一覧再読込 → サムネイル再取得。
    func refresh() {
        // 開くたびに検索をリセットし、検索欄へフォーカスを戻す
        query = ""
        focusTrigger &+= 1

        isPermitted = permission.isAccessibilityTrusted
        isScreenCapturePermitted = permission.isScreenCaptureTrusted

        guard isPermitted else {
            apps = []; allWindows = []
            recomputeItems(query: query)
            return
        }
        apps = sortApps(fetchRunningApps())
        allWindows = apps.flatMap { fetchWindows(pid: $0.id) }
        recomputeItems(query: query)
        loadThumbnails()
    }

    /// 設定の並び順に従ってアプリを並べ替える。
    private func sortApps(_ apps: [RunningApp]) -> [RunningApp] {
        switch UserDefaults.standard.windowSortOrder {
        case .appName:
            return apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .windowCount:
            return apps.sorted {
                $0.windowCount != $1.windowCount
                    ? $0.windowCount > $1.windowCount
                    : $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }
    }

    // MARK: - 権限

    func requestAccessibilityPermission() { permission.requestAccessibility() }
    func requestScreenCapturePermission() { permission.requestScreenCapture() }

    // MARK: - キーボード操作

    func moveSelection(_ direction: MoveDirection) {
        guard !items.isEmpty else { return }
        let count = items.count
        var index = selectedIndex
        switch direction {
        case .left:  index -= 1
        case .right: index += 1
        case .up:    index -= columns
        case .down:  index += columns
        }
        // 端を越えないように選択位置を制限する。
        selectedIndex = min(max(index, 0), count - 1)
    }

    /// 選択中のウィンドウを呼び出す。
    @discardableResult
    func activateSelected() -> Bool {
        guard items.indices.contains(selectedIndex) else { return false }
        return activateWindow(items[selectedIndex])
    }

    /// クリックされたウィンドウを呼び出す。
    @discardableResult
    func activate(_ window: AppWindow) -> Bool {
        activateWindow(window)
    }

    func select(_ window: AppWindow) {
        if let idx = items.firstIndex(of: window) { selectedIndex = idx }
    }

    // MARK: - 派生値

    var isSearching: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func appName(for window: AppWindow) -> String { window.ownerName }

    // MARK: - 内部

    private func recomputeItems(query: String) {
        let results = searchWindows(query: query, apps: apps, windows: allWindows)
        items = results.flatMap { $0.windows }
        // 検索結果の先頭を選択し、Enterですぐ呼び出せるようにする。
        selectedIndex = 0
    }

    /// 表示中ウィンドウのサムネイルを毎回取り直す。
    ///
    /// - 画面上にあるウィンドウは最新画像で上書きする。
    /// - 取得できないウィンドウは前回キャッシュした画像を維持する。
    ///   これにより、一度でも表示したことのあるウィンドウは最小化後もサムネイルを出せる。
    private func loadThumbnails() {
        guard isScreenCapturePermitted else { return }
        thumbnailTask?.cancel()

        // 現在存在しないウィンドウのキャッシュは破棄する。
        let aliveIDs = Set(allWindows.compactMap { $0.windowID })
        thumbnails = thumbnails.filter { aliveIDs.contains($0.key) }

        let targets = items.compactMap { $0.windowID }
        guard !targets.isEmpty else { return }

        thumbnailTask = Task { [weak self, thumbnailProvider] in
            // パネル表示・アプリ切り替えの直後はウィンドウ一覧が安定していないため、
            // 少し待ってから「1 回のスナップショットで全ウィンドウをまとめて」キャプチャする。
            try? await Task.sleep(nanoseconds: 220_000_000)
            guard !Task.isCancelled else { return }

            let captured = await thumbnailProvider.thumbnails(forWindowIDs: targets, maxWidth: 480)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard let self else { return }
                // 取得できたものは最新画像で上書き。
                // 取得できなかったものは前回キャッシュを維持する。
                for (id, cgImage) in captured {
                    self.thumbnails[id] = NSImage(
                        cgImage: cgImage,
                        size: NSSize(width: cgImage.width, height: cgImage.height)
                    )
                }
            }
        }
    }
}

enum MoveDirection { case left, right, up, down }
