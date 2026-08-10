# Yohaku 1.0 — App Store提出パック

アプリ内で完了できる提出準備と、App Store Connect / AdMobで必要な作業を分離した資料です。

## 確定している構成

- Bundle ID: `io.tmkch.yohaku`
- 対応: iPhone / iOS 17以降 / 縦向き
- カテゴリ: 仕事効率化（Primary）、ライフスタイル（Secondary）
- 無料、控えめなバナー広告あり
- 非消耗型IAPで広告を永久に削除
- Product ID: `io.tmkch.yohaku.removeads`
- StoreKit 2、購入復元あり、サブスクリプションなし
- Google Mobile Ads 13.7.0以降、UMP、ATTあり
- アカウントなし、余白データは端末内保存
- 独自クラウド同期なし、iPad対象外

Product IDは機能が明確な `removeads` で統一しています。App Store Connectでも完全に同じIDを登録してください。

## このリポジトリに用意済み

- Release専用のAdMob本番IDと、Debug専用のGoogle公式テストID
- ReleaseへテストID・空IDを混入させないビルドチェック
- 購入権利確認後にだけUMP / ATT / Mobile Adsを開始
- UMP失敗時は広告要求を行わない
- ATT拒否時はIDFAなしで広告表示を継続
- 広告削除購入後はATT・広告SDK・広告要求を開始しない
- 広告取得失敗、キーボード、モーダル表示中は広告領域を畳む
- StoreKitの現地価格表示、購入復元、取引更新監視
- Privacy Manifest、ATT目的文（日英）、暗号化輸出コンプライアンス回答
- アプリ内のプライバシーポリシー、利用規約、特商法表記、問い合わせ
- 日本語・英語の提出文案と審査メモ
- iPhone 17 Pro Max実寸（1320×2868）の日本語・英語スクリーンショット各4枚

## App Store Connectで行う作業

1. Appsで新規アプリを作成し、Bundle ID `io.tmkch.yohaku` を選択する。
2. 発行されたApple IDを `project.yml` の `YOHAKU_APP_STORE_ID` に設定し、`xcodegen generate` を実行する。
3. [metadata-ja.md](metadata-ja.md) と [metadata-en.md](metadata-en.md) を登録する。
4. 非消耗型IAP `io.tmkch.yohaku.removeads` を作成する。表示名・説明は [iap.md](iap.md) を使い、価格帯は日本で約300円になるものを選ぶ。
5. IAPの審査スクリーンショットに、設定画面の購入カード（商品名とStoreKit価格が見える状態）を登録する。
6. 初回IAPをアプリ1.0の提出に追加する。
7. [app-privacy.md](app-privacy.md) を元にプライバシー回答を登録する。Privacy Policy URLとPrivacy Choices URLは `https://yohaku.tmkch.io/privacy`。
8. [age-rating.md](age-rating.md) を元に年齢区分を回答する。Kidsカテゴリは選ばない。
9. [review-notes.md](review-notes.md) を審査メモへ貼る。
10. Paid Apps Agreement、銀行口座、税務情報を完了する。
11. EU配信時はDSAのTrader / Non-Traderを自身の法的立場に基づき申告する。収益化アプリのためTrader該当性を専門家に確認する。
12. 自動リリースではなく、初回は「審査後に手動でリリース」を推奨。

## AdMobで行う作業

1. Privacy & messagingでGDPRメッセージを公開する。
2. IDFAメッセージを作成・公開する。アプリ側は、UMPの説明画面後にATTを表示する。
3. 本番アプリID `ca-app-pub-8687520805381056~6166567024` とバナーID `ca-app-pub-8687520805381056/6272975863` がこのアプリのものか再確認する。
4. `app-ads.txt` をサイト側からデプロイし、次の両方が200になることを確認する。
   - `https://tmkch.io/app-ads.txt`
   - `https://yohaku.tmkch.io/app-ads.txt`

## 提出直前

```sh
xcodegen generate
./Scripts/validate-app-store-readiness.sh --online
xcodebuild -project Yohaku.xcodeproj -scheme Yohaku \
  -configuration Release -destination 'generic/platform=iOS' build
```

[qa-checklist.md](qa-checklist.md) を実機・Sandbox/TestFlightで完了してからArchiveをアップロードします。
