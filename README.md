# Yohaku

予定を増やすのではなく、余白だけを置くアプリ。

- Swift / SwiftUI / SwiftData
- 余白データは端末内で完結（ログイン・独自同期なし）
- 外部通信は広告、StoreKit、法務文書、お問い合わせに限定
- 白黒UI
- 18言語対応（String Catalog）

## 構成

```text
Yohaku/
  YohakuApp.swift
  Models/YohakuBlock.swift
  Views/
    RootTabView.swift
    TodayView.swift
    WeekView.swift
    MonthView.swift
    SettingsView.swift
    LegalDocumentView.swift
    AddYohakuView.swift
  Components/
    YohakuBlockCard.swift
    EmptyStateView.swift
    BrandMark.swift
  Services/SupportService.swift
  Utilities/DateHelpers.swift
  Utilities/SupportPurchaseStore.swift
  Resources/Localizable.xcstrings
  Resources/Yohaku.storekit
```

## ビルド方法（Mac + Xcode 15以降）

### 方法1: XcodeGen（推奨）

```sh
brew install xcodegen
xcodegen generate
open Yohaku.xcodeproj
```

### 方法2: 手動

1. Xcodeで新規 iOS App プロジェクト（SwiftUI / Swift）を `Yohaku` という名前で作成
2. 自動生成された `ContentView.swift` などを削除し、この `Yohaku/` フォルダの中身をプロジェクトに追加
3. Deployment Target を iOS 17.0 以上に設定
4. ビルドして実行

## App Store提出

提出用のメタデータ、プライバシー回答、審査メモ、最終チェックは
[`AppStore/README.md`](AppStore/README.md) にまとめています。

```sh
./Scripts/validate-app-store-readiness.sh
./Scripts/validate-app-store-readiness.sh --online # 公開URLも確認
```

## 画面

- **今日** — 一日の余白を見る・置く、終了後に任意でひとこと振り返る
- **週** — 一週間の余白を一覧する
- **月** — 月間カレンダーから余白のある日を見る
- **設定** — 開始前通知・外観・応援購入・お問い合わせ・法的情報
