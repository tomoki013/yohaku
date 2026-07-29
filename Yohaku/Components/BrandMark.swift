import SwiftUI

// 各画面の左上に静かに置かれるアプリアイコン+セリフ体のワードマーク
struct BrandMark: View {
    var body: some View {
        HStack(spacing: 8) {
            Image("AppIconPreview")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                }
            Text(verbatim: "Yohaku")
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .tracking(1.2)
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
