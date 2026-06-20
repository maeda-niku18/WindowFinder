//
//  FinderMetrics.swift
//  WindowFinder
//
//  ファインダーのレイアウト寸法を定義する。
//

import CoreGraphics

/// グリッドのカード幅・パネル幅を一元的に計算する。
/// 横幅はサムネイルの大きさと列数から導出し、高さのみユーザーが調整する。
enum FinderMetrics {
    /// グリッドのカード間隔
    static let spacing: CGFloat = 12
    /// グリッド外周の余白
    static let gridPadding: CGFloat = 12
    /// カード内側の余白。WindowCardViewのpaddingと合わせる。
    static let cardInset: CGFloat = 8
    /// 横長ウィンドウを想定したサムネイルのアスペクト比。
    static let thumbnailAspect: CGFloat = 1.6

    /// 高さの調整範囲
    static let minHeight: CGFloat = 360
    static let maxHeight: CGFloat = 1300
    static let defaultHeight: CGFloat = 720

    /// サムネイル幅と内側余白を含めたカード全体の幅。
    static func cardWidth(thumbnailHeight: CGFloat) -> CGFloat {
        thumbnailHeight * thumbnailAspect + cardInset * 2
    }

    /// 列数、カード幅、間隔、外周余白からパネル幅を計算する。
    static func panelWidth(columns: Int, thumbnailHeight: CGFloat) -> CGFloat {
        let cols = max(columns, 1)
        let cards = cardWidth(thumbnailHeight: thumbnailHeight) * CGFloat(cols)
        let gaps = spacing * CGFloat(cols - 1)
        return cards + gaps + gridPadding * 2
    }
}
