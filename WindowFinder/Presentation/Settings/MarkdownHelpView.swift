//
//  MarkdownHelpView.swift
//  WindowFinder
//
//  バンドルしたMarkdownヘルプを表示する。
//

import SwiftUI

struct MarkdownHelpView: View {
    let resource: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(blocks.enumerated()), id: \.offset) { _, line in
                    render(line)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
    }

    private var blocks: [String] {
        let localization = Bundle.main.preferredLocalizations.first
        guard let url = Bundle.main.url(forResource: resource, withExtension: "md", subdirectory: nil, localization: localization),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return [L10n.string("help.loadFailed")]
        }
        return text.components(separatedBy: "\n")
    }

    @ViewBuilder
    private func render(_ line: String) -> some View {
        if line.hasPrefix("# ") {
            Text(String(line.dropFirst(2))).font(.title2.bold()).padding(.top, 4)
        } else if line.hasPrefix("## ") {
            Text(String(line.dropFirst(3))).font(.headline).padding(.top, 6)
        } else if line.hasPrefix("- ") {
            HStack(alignment: .top, spacing: 6) {
                Text("•")
                Text(inline(String(line.dropFirst(2))))
            }
        } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
            Spacer().frame(height: 2)
        } else {
            Text(inline(line))
        }
    }

    private func inline(_ s: String) -> AttributedString {
        (try? AttributedString(markdown: s)) ?? AttributedString(s)
    }
}
