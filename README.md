# Window Finder（ウィンドウ ファインダー）

開いているウィンドウをすばやく探して呼び出すための macOS 用ユーティリティです。
コンセプトは *「どこ行った？をなくす。」* です。

たくさんのアプリやウィンドウを開いていると、「どこにあるか分からない」「Space をまたいで探しにくい」
といった状況になりがちです。Window Finder は、Rectangle や Magnet のようなウィンドウを並べるツールではなく、
**開いているウィンドウを探して呼び出すこと**に特化しています。

## 主な機能

- ⌃⌥Space で画面中央にランチャー風の HUD を表示（ショートカットは変更できます）
- 開いているすべてのウィンドウをサムネイル付きのグリッドで一覧表示（ScreenCaptureKit を使用）
- ↑ ↓ ← → で選択、Enter で呼び出し、Esc で閉じる
- アプリ名やウィンドウタイトルで絞り込み検索
- 最小化の解除、前面表示、フォーカスの付与をワンアクションで実行
- 表示順、サムネイルの大きさ、列数、自動スクロール、ショートカットを設定可能

## 動作環境

- macOS 14.0 以上
- **アクセシビリティ権限**（必須）：ウィンドウの一覧取得・前面化に使用します
- **画面収録権限**（任意）：サムネイル表示に使用します（未許可時はアプリアイコンで代替）

> App Sandbox は無効、Developer ID 署名での配布です。Mac App Store ではなく、
> 公証済みの DMG として配布しています。

## インストール

1. [リリースページ](https://github.com/maeda-niku18/WindowFinder/releases) から最新の DMG をダウンロード
2. DMG を開き、`WindowFinder.app` を「アプリケーション」フォルダへドラッグ
3. 初回起動時に、アクセシビリティ権限（必須）と画面収録権限（任意）を許可
4. ⌃⌥Space でランチャーを表示

> 公証済みのため、通常は警告なしでそのまま起動できます。
> 以降、新しいバージョンが出るとアプリ内で自動的に更新を通知します（Sparkle）。

## 使い方

- **⌃⌥Space**：ランチャーの表示 / 表示中に押すと最新情報へ更新
- **↑ ↓ ← →**：ウィンドウの選択
- **Enter**：選択中のウィンドウを呼び出す
- **Esc**：閉じる
- 検索欄に入力すると、アプリ名・ウィンドウタイトルで絞り込めます

## 開発

プロジェクトは [XcodeGen](https://github.com/yonaskolb/XcodeGen) で生成します（`project.yml` が唯一の真実です）。

```bash
xcodegen generate
open WindowFinder.xcodeproj
```

依存ライブラリ（Swift Package Manager）：

- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) — グローバルショートカット
- [Sparkle](https://github.com/sparkle-project/Sparkle) — 自動アップデート

アーキテクチャなどの詳細は [CLAUDE.md](./CLAUDE.md) を参照してください。

## 配布（メンテナ向け）

バージョンを上げて、リリーススクリプトを実行します。

```bash
# project.yml の MARKETING_VERSION を更新してから
./release.sh 1.1.0
```

署名、DMG 作成、公証、ステープル、appcast 更新、GitHub Releases へのアップロードまでを自動で行います。

## 開発を支援する

このアプリが役に立ったら、開発を支援していただけると嬉しいです。

→ [Buy Me a Coffee](https://buymeacoffee.com/joqnorandev) ☕

## ライセンス

[MIT License](./LICENSE)
