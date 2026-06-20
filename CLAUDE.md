# CLAUDE.md

このファイルは、本リポジトリで作業する際の Claude Code 向けガイドです。

## プロジェクト概要

**Window Finder** は macOS 専用のウィンドウ「発見・呼び出し」ユーティリティ。
多数のアプリ／ウィンドウを開いた状態で「どこにあるか分からない」「Space を跨いで探せない」
という課題を解決する。既存の「ウィンドウを並べる」ツール（Rectangle / Magnet 等）とは異なり、
**「開いているウィンドウを最速で探して呼び出す」** ことに特化する。

コンセプト: *「どこ行った？をなくす。」*

## 技術スタック

- Swift 5 / SwiftUI + AppKit
- Accessibility API（`AXUIElement`）／ `NSWorkspace` ／ CGWindow
- **ScreenCaptureKit**（ウィンドウのサムネイル取得）
- プロジェクト生成: **XcodeGen**（`project.yml` が唯一の真実）
- 依存管理: **Swift Package Manager**
  - [`soffes/HotKey`](https://github.com/soffes/HotKey) — グローバルショートカット
- 対応 OS: macOS 14.0 以上

## 重要な前提

- **App Sandbox は無効**（`ENABLE_APP_SANDBOX: NO`）。
  他アプリのウィンドウを Accessibility API で操作するため、サンドボックス内では動作しない。
  配布は Mac App Store ではなく **Developer ID** 署名を想定。
- **アクセシビリティ権限が必須**。未許可時は権限案内画面（`PermissionView`）を表示する。
- **画面収録権限は任意**。サムネイル表示に使用し、未許可時はアプリアイコンで代替する。
- **メニューバー常駐エージェント**（`LSUIElement = true`）。Dock アイコンは出さず、
  メニューバーアイコンとグローバルショートカット（⌃⌥Space）で起動する。
- **UI はランチャー風 HUD**。中央に出るボーダーレスの `NSPanel`（`FinderPanel`）に
  ウィンドウのサムネイルをグリッド表示し、↑↓←→で移動・Enter で呼び出し・Esc で閉じる。
  キー操作は検索欄のフォーカスに奪われないよう `AppDelegate` のローカルイベントモニタで横取りする。

## ビルド / 開発フロー

`.xcodeproj` と `Info.plist` は **生成物**（`.gitignore` 済み）。直接編集しない。
ビルド設定・Info.plist・SPM 依存はすべて `project.yml` を編集する。

```bash
# project.yml から Xcode プロジェクトを生成（依存追加・ファイル追加のたびに実行）
xcodegen generate

# コマンドラインビルド
xcodebuild -project WindowFinder.xcodeproj -scheme WindowFinder \
  -configuration Debug -destination 'platform=macOS' build

# Xcode で開く
open WindowFinder.xcodeproj
```

> 新しい Swift ファイルを追加したら `xcodegen generate` を再実行する
> （ソースはディレクトリ単位で自動収集される）。

## アーキテクチャ（Clean Architecture + MVVM）

依存方向は **Presentation → Domain ← Data**。Domain は他層・フレームワークに依存しない。
具象の生成は合成ルート `App/AppContainer.swift` に集約する。

```
WindowFinder/
├── App/                         # 合成ルート・アプリ起動・常駐制御
│   ├── WindowFinderApp.swift    #   @main エントリ（Settings シーンのみ）
│   ├── AppDelegate.swift        #   メニューバー / ショートカット / パネル / キー操作
│   ├── AppContainer.swift       #   DI（ここでのみ具象を生成）
│   └── FinderPanel.swift        #   ランチャー風 HUD（ボーダーレス NSPanel）
│
├── Domain/                      # ビジネスルール（フレームワーク非依存）
│   ├── Entities/                #   RunningApp / AppWindow
│   ├── Repositories/            #   WindowRepositoryProtocol 等（抽象）
│   └── UseCases/                #   FetchRunningApps / FetchWindows /
│                                #   ActivateWindow / SearchWindows
│
├── Data/                        # リポジトリ実装
│   └── Repositories/
│       └── AccessibilityWindowRepository.swift
│
├── Infrastructure/              # OS / 外部ライブラリへの薄いラッパー
│   ├── Accessibility/           #   AXClient / 権限リポジトリ（AX + 画面収録）
│   ├── Capture/                 #   WindowThumbnailService（ScreenCaptureKit）
│   └── HotKey/                  #   HotKeyService（SPM の HotKey をラップ）
│
└── Presentation/                # MVVM（SwiftUI）
    ├── Finder/                  #   FinderView（サムネイルグリッド）+ FinderViewModel
    ├── Components/              #   WindowCardView / AppIconImage / SearchField
    └── Permission/             #   権限案内 View
```

### レイヤの責務

- **Domain**: `Entity` と `UseCase`、`Repository` プロトコルを定義。AppKit / AX に依存しない。
  - `AppWindow` は実体（`AXUIElement`）を持たず、`id` だけを保持。実体への再解決は Data 層が担う。
- **Data**: `WindowRepositoryProtocol` を Accessibility API / `NSWorkspace` で実装。
  `id → AXUIElement` のマッピングを内部キャッシュで保持し、`AXUIElement` を上位層へ漏らさない。
- **Infrastructure**: `AXClient`（AX 呼び出しの隔離）、権限取得、グローバルショートカット。
- **Presentation**: `FinderViewModel`（`@MainActor` / `ObservableObject`）が UseCase 経由で
  ドメインを呼び、View は状態を購読するだけ（MVVM）。

### データフローの例（ウィンドウ呼び出し）

`FinderView` → `FinderViewModel.activate(window)` → `ActivateWindowUseCase`
→ `WindowRepository.activate` → 最小化解除 → `kAXRaiseAction` → `NSRunningApplication.activate`

## 実装状況（仕様書ベース）

### MVP（実装済み）
- 機能1/2: 全ウィンドウをサムネイルのグリッドで一覧（各カードにアプリ名・最小化バッジ）
- 機能3: ウィンドウ呼び出し（最小化解除・前面化・フォーカス）
- 機能4: グローバルショートカット（⌃⌥Space）でランチャー表示
- 機能5: 検索（アプリ名 / ウィンドウタイトル）＋ キーボード操作（↑↓←→ / Enter / Esc）

### 既知の制約 / TODO
- **Space 番号**は公開 API では安定取得が困難なため現状 `nil`（`AppWindow.spaceNumber`）。将来対応。
- 一覧は手動更新（パネル表示時に `refresh()`）。ウィンドウ変化の自動追従は未実装。

### ロードマップ
- v1.1: 最近使用したウィンドウ（機能6） / お気に入り（機能7）
- v1.2: ワークスペース保存・復元（機能8・9）
- v2: レイアウト保存・復元（機能10・11）

## コーディング規約

- 新機能は対応するレイヤに配置し、依存方向（Presentation → Domain ← Data）を守る。
- ドメイン層に AppKit / Accessibility を import しない。OS 依存は Data / Infrastructure に閉じ込める。
- ViewModel は UseCase にのみ依存し、Repository 実装を直接参照しない。
- コメントは日本語。AX / private シンボル利用箇所は意図を明記する。
