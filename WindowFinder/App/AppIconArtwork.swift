//
//  AppIconArtwork.swift
//  WindowFinder
//
//  App: メニューバー用「ウィンドウ＋虫眼鏡」アイコンをコードで描画する
//

import AppKit

enum AppIconArtwork {

    /// メニューバー用のテンプレート画像（ウィンドウ＋虫眼鏡）。
    /// 単色で描き `isTemplate = true` にすることで、ライト/ダークに自動追従する。
    /// 他のメニューバーアイコンと馴染むよう、内側に余白を取って小さめに見せる。
    static func menuBarImage(pointSize: CGFloat = 18) -> NSImage {
        let scale: CGFloat = 3   // Retina 向けに高解像度で描く
        let px = pointSize * scale
        let image = NSImage(size: NSSize(width: pointSize, height: pointSize))
        image.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return image
        }
        // pointSize の論理座標へスケール（描画は px 基準で計算）
        ctx.scaleBy(x: pointSize / px, y: pointSize / px)

        // コンテンツは中央 ~74% に収める（上下左右に余白＝小さく見える）
        let pad = px * 0.16
        let line = px * 0.066
        ctx.setStrokeColor(NSColor.black.cgColor)
        ctx.setLineWidth(line)
        ctx.setLineJoin(.round)
        ctx.setLineCap(.round)

        // ウィンドウ（左上寄りの角丸枠＋タイトルバー線）
        let winW = px * 0.50, winH = px * 0.42
        let winX = pad, winY = px - pad - winH
        let winRect = CGRect(x: winX, y: winY, width: winW, height: winH)
        ctx.addPath(CGPath(roundedRect: winRect, cornerWidth: px * 0.05, cornerHeight: px * 0.05, transform: nil))
        ctx.strokePath()
        let barY = winY + winH - px * 0.12
        ctx.move(to: CGPoint(x: winX, y: barY))
        ctx.addLine(to: CGPoint(x: winX + winW, y: barY))
        ctx.strokePath()

        // 虫眼鏡（右下に重ねる。重なり部分を一度くり抜いて見やすく）
        let r = px * 0.16
        let cx = px - pad - r * 1.1
        let cy = pad + r * 1.1
        ctx.saveGState()
        ctx.setBlendMode(.clear)
        ctx.fillEllipse(in: CGRect(x: cx - r - line, y: cy - r - line,
                                   width: (r + line) * 2, height: (r + line) * 2))
        ctx.restoreGState()
        ctx.strokeEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        ctx.move(to: CGPoint(x: cx + r * 0.72, y: cy - r * 0.72))
        ctx.addLine(to: CGPoint(x: cx + r * 1.55, y: cy - r * 1.55))
        ctx.strokePath()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
