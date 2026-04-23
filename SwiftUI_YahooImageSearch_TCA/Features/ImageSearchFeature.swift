//
//  ImageSearchFeature.swift
//  SwiftUI_YahooImageSearch_TCA
//
//  Created by cano on 2026/04/23.
//

import SwiftUI
import ComposableArchitecture
 
@Reducer
struct ImageSearchFeature {
 
    // MARK: - Dependency
    // ImageSearchClientをDependencyとして注入
    // テスト時はtestValueに自動で差し替わる
    @Dependency(\.imageSearchClient) var imageSearchClient
 
    // MARK: - State
    @ObservableState
    struct State: Equatable {
        var searchText       = ""
        var imageDatas       = [ImageData]()
        var isLoading        = false
        var hasSearched      = false
        var selectedImage: ImageData? = nil
        var isShowingDetail  = false
        var currentPage      = 1
        var hasNextPage      = true
 
        // 3文字以上入力されたらボタン有効
        var isButtonEnabled: Bool { searchText.count >= 3 }
    }
 
    // MARK: - Action
    enum Action {
        case searchTextChanged(String)        // テキストフィールドの変更
        case searchButtonTapped               // 検索ボタンタップ
        case searchResponse(Result<[ImageData], Error>)       // 初回検索の結果
        case loadNextPage                     // 次ページ取得トリガー
        case loadNextPageResponse(Result<[ImageData], Error>) // 次ページ取得の結果
        case imageTapped(ImageData)           // 画像タップ → 詳細表示
        case selectedImageChanged(ImageData?) // PhotoBrowserのスワイプで選択画像が変わった
        case detailDismissed                  // 詳細画面を閉じた
    }
 
    // debounce用のキャンセルID
    private static let debounceID = "debounce"
 
    // MARK: - Reducer
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
 
            // テキスト変更 → 0.5秒debounceして自動検索
            case .searchTextChanged(let text):
                state.searchText = text
                guard state.isButtonEnabled else {
                    return .cancel(id: Self.debounceID)
                }
                return .run { send in
                    try await Task.sleep(for: .milliseconds(500))
                    await send(.searchButtonTapped)
                }
                .cancellable(id: Self.debounceID, cancelInFlight: true)
 
            // 1ページ目を取得して既存リストをリセット
            case .searchButtonTapped:
                state.imageDatas  = []
                state.isLoading   = true
                state.hasSearched = false
                state.currentPage = 1
                state.hasNextPage = true
                let query = state.searchText
                return .run { [imageSearchClient] send in
                    do {
                        let images = try await imageSearchClient.search(query, 1)
                        await send(.searchResponse(.success(images)))
                    } catch {
                        await send(.searchResponse(.failure(error)))
                    }
                }
                .cancellable(id: Self.debounceID, cancelInFlight: true)
 
            // 初回検索結果をStateにセット
            case .searchResponse(.success(let images)):
                state.imageDatas  = images
                state.isLoading   = false
                state.hasSearched = true
                state.hasNextPage = !images.isEmpty
                return .none
 
            case .searchResponse(.failure(let error)):
                print("Search error: \(error)")
                state.isLoading   = false
                state.hasSearched = true
                return .none
 
            // ローディング中・次ページなし・検索前はスキップ
            case .loadNextPage:
                guard !state.isLoading && state.hasNextPage && state.hasSearched else { return .none }
                state.isLoading = true
                let query = state.searchText
                let nextPage = state.currentPage + 1
                return .run { [imageSearchClient] send in
                    do {
                        let images = try await imageSearchClient.search(query, nextPage)
                        await send(.loadNextPageResponse(.success(images)))
                    } catch {
                        await send(.loadNextPageResponse(.failure(error)))
                    }
                }
 
            // 次ページ結果を既存リストに追加（URLベースで重複除外）
            case .loadNextPageResponse(.success(let images)):
                state.isLoading = false
                if images.isEmpty {
                    state.hasNextPage = false
                } else {
                    state.currentPage += 1
                    let existingURLs = Set(state.imageDatas.map { $0.url })
                    let newImages = images.filter { !existingURLs.contains($0.url) }
                    state.imageDatas += newImages
                    state.hasNextPage = !newImages.isEmpty
                }
                return .none
 
            case .loadNextPageResponse(.failure(let error)):
                print("LoadNextPage error: \(error)")
                state.isLoading = false
                return .none
 
            // 画像タップ → 選択画像をセットして詳細画面を開く
            case .imageTapped(let image):
                state.selectedImage   = image
                state.isShowingDetail = true
                return .none
 
            // PhotoBrowserのスワイプで選択画像が変わった
            case .selectedImageChanged(let image):
                state.selectedImage = image
                return .none
 
            // 詳細画面を閉じる
            case .detailDismissed:
                state.isShowingDetail = false
                return .none
            }
        }
    }
}
