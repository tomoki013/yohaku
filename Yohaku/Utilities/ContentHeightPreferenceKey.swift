import SwiftUI

// ページ遷移中に高さが変わっても、コンテナの高さをアニメーションさせて
// 中身が瞬間的にジャンプ(上下移動)して見えるのを防ぐ
struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

extension View {
    func measuringContentHeight() -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(key: ContentHeightPreferenceKey.self, value: proxy.size.height)
            }
        )
    }
}
