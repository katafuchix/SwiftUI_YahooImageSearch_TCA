# SwiftUI_YahooImageSearch_TCA
- [SwiftUI + TCA版](https://github.com/katafuchix/SwiftUI_YahooImageSearch_TCA)
- [SwiftUI + MVVM版](https://github.com/katafuchix/SwiftUI_YahooImageSearch_MVVM)
- [RxSwift + Action版](https://github.com/katafuchix/YahooImageSearchAction)
- [RxSwift + Wireframe版](https://github.com/katafuchix/YahooImageSearchWireframe)
- [RxSwift簡易MVVM版](https://github.com/katafuchix/ImageSearchSample)
- [Flutter + Cubit版](https://github.com/katafuchix/flutter_yahoo_image_search_cubit)
- [Flutter + ChangeNotifier版](https://github.com/katafuchix/flutter_yahoo_image_search)
- [Kotlin版](https://github.com/katafuchix/ImageSearchSampleKotlin)

## データフローのイメージ
```
[View] ---(Action)---> [Store/Reducer] ---(新しいState)---> [View]
                              |
                         [Effect]
                         (API通信など)
```
- Effect = Reducerの外側で起きる処理を返すもの, 具体的には return .run { } で返すものが全部Effect


### TCA固有の注意点

- @Reducer マクロの body は some ReducerOf<Self> ではなく some Reducer<State, Action> と書く（Xcode 26 + Swift 6.2の問題）
- @MainActor クラスを Effect.run から直接呼ぶとデッドロックになる → Dependency として切り出す
- debounce用のキャンセルIDは private enum CancelID ではなく private static let で定義する（MainActor隔離問題）
- loadNextPage などの副作用Actionには必ず guard で多重発火を防ぐ

### SwiftUI固有の注意点

- LazyVGrid の ForEach 内で ObservableObject を直接生成するとページ追加時にリセットされる → @State + .task で各セルに持たせる
- AsyncImage はカスタムヘッダー（Referer等）を付けられない → URLSession で自前実装する
- スクロール末尾検知は ScrollView + onAppear より LazyVGrid の Section footer が確実

### TCAの概要
- **State**（状態）: アプリの状態を表すデータモデル。
- **Action**（アクション）: ユーザー操作やイベントを定義する。
- **Reducer**（リデューサー）: Actionに応じてStateを更新する。
- **Store**（ストア）: State、Action、Reducerを管理する中心的な役割。

### よくある比較

|	|素のMVVM	|RxMVVM + Action	|TCA|
| ------------- | ------------- |------------- | ------------- |
|状態変更の自由度	|高い（危険）	|中（Actionで制限）	|低い（厳格）|
|フォーマットの統一	|バラバラ	|ある程度統一	|完全統一|
|学習コスト	|低い	|中	|高い|
|テストのしやすさ	|低い	|中	|高い|
|ボイラープレート	|少ない	|中	|多い|
