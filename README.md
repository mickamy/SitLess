# SitLess

macOS メニューバー常駐アプリ。座りすぎを検知してストレッチをリマインドします。

## 機能

- **アイドル検出** — IOKit 経由でシステムのアイドル時間を監視し、座っている／離席中を自動判定
- **ストレッチ通知** — 設定した間隔でストレッチをローテーション通知（8種類のストレッチを内蔵）
- **ダッシュボード** — メニューバーから今日の座り時間・連続座り時間・ストレッチ回数を確認
- **カスタマイズ** — ストレッチ通知間隔（5〜120分）、離席判定しきい値（1〜30分）を調整可能
- **ログイン時自動起動** — SMAppService による起動項目登録

## 要件

- macOS 15.7 以降

## ビルド

```bash
git clone https://github.com/mickamy/SitLess.git
cd SitLess
open SitLess.xcodeproj
```

Xcode でビルド・実行してください。外部依存はありません。

## インストール

### Homebrew

```bash
brew install --cask mickamy/tap/sitless
```

### 手動

[Releases](https://github.com/mickamy/SitLess/releases) から `SitLess.app.zip` をダウンロードし、`/Applications` に配置してください。コード署名なしで配布しているため、初回起動前に Gatekeeper の隔離属性を解除する必要があります:

```bash
xattr -cr /Applications/SitLess.app
```

## アーキテクチャ

```
SitLess/
├── Models/
│   ├── Settings.swift        # 設定（バリデーション付き）
│   ├── DailyRecord.swift     # 日次記録・CalendarDay・SittingSession
│   └── Stretch.swift         # ストレッチデータ
├── Services/
│   ├── IdleDetector.swift    # IOKit アイドル時間取得
│   ├── StorageService.swift  # UserDefaults 永続化
│   ├── StretchNotifier.swift # 通知送信・ローテーション
│   └── SittingTracker.swift  # コアロジック（@Observable）
├── Views/
│   ├── MenuBarLabel.swift    # メニューバー表示
│   ├── DashboardView.swift   # メイン画面
│   ├── SettingsView.swift    # 設定画面
│   └── StretchListView.swift # ストレッチ一覧
├── Resources/
│   └── Stretches.json        # 内蔵ストレッチデータ
└── SitLessApp.swift          # エントリーポイント
```

主要な設計判断:

- 全サービスが protocol で抽象化されており、テスト時にモック差し替え可能
- `@Observable` + SwiftUI で宣言的にUIを構築
- App Sandbox は IOKit アクセスのため無効化、Hardened Runtime は有効

## テスト

```bash
xcodebuild test -scheme SitLess -destination 'platform=macOS'
```

## ライセンス

[MIT](./LICENSE)
