//
//  PermissionView.swift
//  WindowFinder
//
//  権限の案内画面。
//

import SwiftUI

struct PermissionView: View {
    var title: String
    var message: String
    let onRequest: () -> Void
    let onRecheck: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 44))
                .foregroundStyle(.tint)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button(L10n.string("permission.openSystemSettings"), action: onRequest)
                    .buttonStyle(.borderedProminent)
                Button(L10n.string("permission.recheck"), action: onRecheck)
                    .buttonStyle(.bordered)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
