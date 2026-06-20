//
//  WindowThumbnailService.swift
//  WindowFinder
//
//  Infrastructure: ScreenCaptureKit によるウィンドウ画像（サムネイル）取得
//

import ScreenCaptureKit
import CoreGraphics

/// ウィンドウ画像の取得を抽象化するプロバイダ。
/// 画像は CoreGraphics の `CGImage` で返し、AppKit への依存は呼び出し側に委ねる。
protocol WindowThumbnailProviding {
    /// 指定した複数ウィンドウを **1 回のスナップショット**でまとめてキャプチャする。
    /// - Returns: windowID → 画像。取得できなかったウィンドウは含まれない。
    func thumbnails(forWindowIDs ids: [UInt32], maxWidth: CGFloat) async -> [UInt32: CGImage]
}

/// ScreenCaptureKit（macOS 14+）でウィンドウを一括キャプチャする実装。
/// 画面収録権限が無い／最小化・オフスクリーンのものは結果に含まれない。
final class WindowThumbnailService: WindowThumbnailProviding {

    func thumbnails(forWindowIDs ids: [UInt32], maxWidth: CGFloat = 480) async -> [UInt32: CGImage] {
        guard !ids.isEmpty else { return [:] }

        // 共有可能コンテンツを 1 度だけ取得（=その時点の一貫したスナップショット）
        guard let content = try? await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        ) else { return [:] }

        let wanted = Set(ids)
        let windows = content.windows.filter { wanted.contains($0.windowID) }
        guard !windows.isEmpty else { return [:] }

        var result: [UInt32: CGImage] = [:]
        await withTaskGroup(of: (UInt32, CGImage?).self) { group in
            for scWindow in windows {
                group.addTask {
                    (scWindow.windowID, await Self.capture(scWindow, maxWidth: maxWidth))
                }
            }
            for await (id, image) in group {
                if let image { result[id] = image }
            }
        }
        return result
    }

    private static func capture(_ scWindow: SCWindow, maxWidth: CGFloat) async -> CGImage? {
        let filter = SCContentFilter(desktopIndependentWindow: scWindow)

        // 元サイズを maxWidth に収まるよう等比縮小（負荷軽減）
        let srcWidth = max(scWindow.frame.width, 1)
        let srcHeight = max(scWindow.frame.height, 1)
        let scale = min(1, maxWidth / srcWidth)

        let config = SCStreamConfiguration()
        config.width = Int(srcWidth * scale)
        config.height = Int(srcHeight * scale)
        config.showsCursor = false
        config.ignoreShadowsSingleWindow = true

        return try? await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        )
    }
}
