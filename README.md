# SwiftUI_YahooImageSearch_TCA


### TCA固有の注意点

- @Reducer マクロの body は some ReducerOf<Self> ではなく some Reducer<State, Action> と書く（Xcode 26 + Swift 6.2の問題）
- @MainActor クラスを Effect.run から直接呼ぶとデッドロックになる → Dependency として切り出す
- debounce用のキャンセルIDは private enum CancelID ではなく private static let で定義する（MainActor隔離問題）
- loadNextPage などの副作用Actionには必ず guard で多重発火を防ぐ

### SwiftUI固有の注意点

- LazyVGrid の ForEach 内で ObservableObject を直接生成するとページ追加時にリセットされる → @State + .task で各セルに持たせる
- AsyncImage はカスタムヘッダー（Referer等）を付けられない → URLSession で自前実装する
- スクロール末尾検知は ScrollView + onAppear より LazyVGrid の Section footer が確実
