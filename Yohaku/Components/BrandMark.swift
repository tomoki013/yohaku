import SwiftUI

// 各画面の左上に静かに置かれるワードマーク。墨の一滴+セリフ体
struct BrandMark: View {
    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(Color.primary)
                .frame(width: 6, height: 6)
            Text(verbatim: "Yohaku")
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .tracking(1.5)
                .foregroundStyle(.primary)
        }
        .fixedSize()
        .accessibilityHidden(true)
    }
}

// ガラス背景なしで左上に置くためのツールバー項目(押せる見た目にしない)
struct BrandToolbarItem: ToolbarContent {
    var body: some ToolbarContent {
        // sharedBackgroundVisibility は iOS 26 SDK(Swift 6.2)以降にのみ存在する
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            ToolbarItem(placement: .topBarLeading) {
                BrandMark()
            }
            .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: .topBarLeading) {
                BrandMark()
            }
        }
        #else
        ToolbarItem(placement: .topBarLeading) {
            BrandMark()
        }
        #endif
    }
}

// 右上の設定ボタン。BrandToolbarItem とガラス背景の扱いを揃え、
// 画面遷移のたびに背景カプセルが組み直されてちらつくのを防ぐ
struct SettingsToolbarItem: ToolbarContent {
    @Binding var isShowingSettings: Bool

    var body: some ToolbarContent {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            ToolbarItem(placement: .topBarTrailing) {
                settingsButton
            }
            .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: .topBarTrailing) {
                settingsButton
            }
        }
        #else
        ToolbarItem(placement: .topBarTrailing) {
            settingsButton
        }
        #endif
    }

    private var settingsButton: some View {
        Button {
            isShowingSettings = true
        } label: {
            Image(systemName: "gearshape")
                .foregroundStyle(.primary)
        }
        .accessibilityLabel(Text("settings.title"))
    }
}
