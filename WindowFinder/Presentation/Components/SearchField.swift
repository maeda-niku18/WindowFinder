//
//  SearchField.swift
//  WindowFinder
//
//  Presentation: 検索入力フィールド（機能5）
//

import SwiftUI

struct SearchField: View {
    @Binding var text: String
    var focused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("アプリ名・ウィンドウタイトルで検索", text: $text)
                .textFieldStyle(.plain)
                .focused(focused)
                .onSubmit { /* Enter は将来「先頭候補を開く」に割当 */ }

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }
}
