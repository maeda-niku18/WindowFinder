//
//  WindowCardView.swift
//  WindowFinder
//
//  ファインダーグリッドに表示するウィンドウカード。
//

import SwiftUI

struct WindowCardView: View {
    let window: AppWindow
    let thumbnail: NSImage?
    var thumbnailHeight: CGFloat = 130
    let isSelected: Bool
    let onActivate: () -> Void
    let onHover: () -> Void

    var body: some View {
        Button(action: onActivate) {
            VStack(spacing: 6) {
                thumbnailArea
                    .frame(height: thumbnailHeight)
                    .frame(maxWidth: .infinity)
                    .background(.black.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(alignment: .topLeading) { minimizedBadge }
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 5) {
                    AppIconImage(pid: window.ownerPID, size: 16)
                    Text(window.displayTitle)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(window.ownerName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(8)
            .background(selectionBackground)
            .overlay(selectionRing)
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .onHover { if $0 { onHover() } }
    }

    @ViewBuilder
    private var thumbnailArea: some View {
        if let thumbnail {
            Image(nsImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            // サムネイル未取得時はアプリアイコンで代替
            AppIconImage(pid: window.ownerPID, size: 44)
                .opacity(0.85)
        }
    }

    @ViewBuilder
    private var minimizedBadge: some View {
        if window.isMinimized {
            Image(systemName: "minus.circle.fill")
                .font(.caption)
                .foregroundStyle(.orange)
                .padding(4)
        }
    }

    private var selectionBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
    }

    @ViewBuilder
    private var selectionRing: some View {
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
    }
}
