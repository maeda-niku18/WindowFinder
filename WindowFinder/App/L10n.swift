//
//  L10n.swift
//  WindowFinder
//
//  アプリ全体で使うローカライズヘルパー。
//

import Foundation

enum L10n {
    static func string(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: Locale.current, arguments: arguments)
    }
}
