//
//  AppIconArtwork.swift
//  WindowFinder
//
//  App: メニューバー用「ウィンドウ＋虫眼鏡」アイコンをコードで描画する
//

import AppKit

enum AppIconArtwork {

    /// ウィンドウと虫眼鏡を組み合わせたメニューバー用テンプレート画像。
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
        // ピクセル基準で計算した描画をpointSizeの論理座標へ変換する。
        ctx.scaleBy(x: pointSize / px, y: pointSize / px)

        // 他のメニューバーアイコンと揃えるため、外周に余白を残す。
        let pad = px * 0.16
        let line = px * 0.066
        ctx.setStrokeColor(NSColor.black.cgColor)
        ctx.setLineWidth(line)
        ctx.setLineJoin(.round)
        ctx.setLineCap(.round)

        // 左上寄りにウィンドウ枠とタイトルバーを描く。
        let winW = px * 0.50, winH = px * 0.42
        let winX = pad, winY = px - pad - winH
        let winRect = CGRect(x: winX, y: winY, width: winW, height: winH)
        ctx.addPath(CGPath(roundedRect: winRect, cornerWidth: px * 0.05, cornerHeight: px * 0.05, transform: nil))
        ctx.strokePath()
        let barY = winY + winH - px * 0.12
        ctx.move(to: CGPoint(x: winX, y: barY))
        ctx.addLine(to: CGPoint(x: winX + winW, y: barY))
        ctx.strokePath()

        // 右下に虫眼鏡を重ね、交差部分はくり抜いて視認性を保つ。
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
