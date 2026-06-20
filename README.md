# Window Finder

開いているウィンドウを最速で探して呼び出す macOS ユーティリティ。
*「どこ行った？をなくす。」*

多数のアプリ／ウィンドウを開いた状態で「どこにあるか分からない」「Space を跨いで探せない」
を解決します。ウィンドウを並べるツール（Rectangle / Magnet 等）とは異なり、
**発見・呼び出し**に特化しています。

## 主な機能

- ⌃⌥Space で中央にランチャー風 HUD を表示（ショートカットは変更可）
- 全ウィンドウをサムネイルのグリッドで一覧（ScreenCaptureKit）
- ↑↓←→ で選択 / Enter で呼び出し / Esc で閉じる
- アプリ名・ウィンドウタイトルで絞り込み検索
- 最小化解除・前面化・フォーカス付与をワンアクションで
- 設定: 表示順 / サムネサイズ / 列数 / 自動スクロール / ショートカット変更

## 動作環境

- macOS 14.0 以上
- **アクセシビリティ権限**（必須）/ **画面収録権限**（サムネイル表示・任意）

> App Sandbox 無効・Developer ID 配布。Mac App Store 外で公証済み DMG として配布します。

## ダウンロード

[Releases](https://github.com/maeda-niku18/WindowFinder/releases) から最新の DMG を取得してください。

## 開発

プロジェクトは [XcodeGen](https://github.com/yonaskolb/XcodeGen) で生成します（`project.yml` が真実）。

```bash
xcodegen generate
open WindowFinder.xcodeproj
```

依存（Swift Package Manager）:
- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) — グローバルショートカット
- [Sparkle](https://github.com/sparkle-project/Sparkle) — 自動アップデート

アーキテクチャ等の詳細は [CLAUDE.md](./CLAUDE.md) を参照。

## 支援

開発の支援はこちら → [Buy Me a Coffee](https://buymeacoffee.com/joqnorandev) ☕

## ライセンス

[MIT](./LICENSE)
