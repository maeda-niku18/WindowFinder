//
//  SearchField.swift
//  WindowFinder
//
//  ファインダーパネルの検索欄。
//

import SwiftUI

struct SearchField: View {
    @Binding var text: String
    var focused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField(L10n.string("search.placeholder"), text: $text)
                .textFieldStyle(.plain)
                .focused(focused)
                .onSubmit { }

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
