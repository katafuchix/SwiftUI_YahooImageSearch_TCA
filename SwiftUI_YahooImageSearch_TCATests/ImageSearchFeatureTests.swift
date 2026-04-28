//
//  ImageSearchFeatureTests.swift
//  SwiftUI_YahooImageSearch_TCA
//
//  Created by cano on 2026/04/28.
//

import Foundation
import ComposableArchitecture
import Testing
@testable import SwiftUI_YahooImageSearch_TCA// 自分のアプリ名


@MainActor
struct ImageSearchFeatureTests {
 
    // MARK: - テスト用のダミーデータ
    let dummyImages = [
        ImageData(url: URL(string: "https://msp.c.yimg.jp/test1.jpg")!),
        ImageData(url: URL(string: "https://msp.c.yimg.jp/test2.jpg")!),
        ImageData(url: URL(string: "https://msp.c.yimg.jp/test3.jpg")!)
    ]
 
    // MARK: - テキスト変更テスト
 
    @Test
    func searchTextChanged_3文字未満はボタン無効() async throws {
        let store = TestStore(initialState: ImageSearchFeature.State()) {
            ImageSearchFeature()
        }
 
        // 2文字入力 → isButtonEnabledがfalseのまま
        // 3文字未満なのでdebounceのEffectはキャンセルされる（finishは不要）
        await store.send(.searchTextChanged("ab")) {
            $0.searchText = "ab"
        }
        #expect(store.state.isButtonEnabled == false)
    }
 
    @Test
    func searchTextChanged_3文字以上はボタン有効() async throws {
        let store = TestStore(initialState: ImageSearchFeature.State()) {
            ImageSearchFeature()
        }
        // debounceが発火して searchButtonTapped → searchResponse が来るので
        // 余分なActionを無視する設定にする
        store.exhaustivity = .off
 
        // 3文字入力 → isButtonEnabledがtrueになる
        await store.send(.searchTextChanged("abc")) {
            $0.searchText = "abc"
        }
        #expect(store.state.isButtonEnabled == true)
    }
 
    // MARK: - 検索テスト
    // searchTextChangedを送るとdebounceのEffectが残るため
    // initialStateにsearchTextを直接セットしてsearchButtonTappedだけをテストする
 
    @Test
    func searchButtonTapped_検索成功() async throws {
        let dummyImages = self.dummyImages
 
        // searchTextを直接セットしてdebounceを回避
        let initialState = ImageSearchFeature.State(searchText: "ダックス")
        let store = TestStore(initialState: initialState) {
            ImageSearchFeature()
        } withDependencies: {
            // モックのImageSearchClientを注入（本物のAPIは呼ばない）
            $0.imageSearchClient = ImageSearchClient(
                search: { _, _ in dummyImages }
            )
        }
 
        // 検索ボタンタップ → ローディング開始・リセット
        await store.send(.searchButtonTapped) {
            $0.imageDatas  = []
            $0.isLoading   = true
            $0.hasSearched = false
            $0.currentPage = 1
            $0.hasNextPage = true
        }
 
        // 検索結果が返ってくる → imageDatasにセットされる
        await store.receive(\.searchResponse.success) {
            $0.imageDatas  = dummyImages
            $0.isLoading   = false
            $0.hasSearched = true
            $0.hasNextPage = true
        }
    }
 
    @Test
    func searchButtonTapped_検索失敗() async throws {
        let initialState = ImageSearchFeature.State(searchText: "ダックス")
        let store = TestStore(initialState: initialState) {
            ImageSearchFeature()
        } withDependencies: {
            // エラーを投げるモックを注入
            $0.imageSearchClient = ImageSearchClient(
                search: { _, _ in throw ImageError.serverError }
            )
        }
 
        await store.send(.searchButtonTapped) {
            $0.imageDatas  = []
            $0.isLoading   = true
            $0.hasSearched = false
            $0.currentPage = 1
            $0.hasNextPage = true
        }
 
        // エラーが返ってくる → ローディング終了・hasSearchedがtrue
        await store.receive(\.searchResponse.failure) {
            $0.isLoading   = false
            $0.hasSearched = true
        }
    }
 
    @Test
    func searchButtonTapped_検索結果が空() async throws {
        let initialState = ImageSearchFeature.State(searchText: "xyzxyzxyz")
        let store = TestStore(initialState: initialState) {
            ImageSearchFeature()
        } withDependencies: {
            // 空配列を返すモックを注入
            $0.imageSearchClient = ImageSearchClient(
                search: { _, _ in [] }
            )
        }
 
        await store.send(.searchButtonTapped) {
            $0.imageDatas  = []
            $0.isLoading   = true
            $0.hasSearched = false
            $0.currentPage = 1
            $0.hasNextPage = true
        }
 
        // 空配列が返ってくる → hasNextPageがfalseになる
        await store.receive(\.searchResponse.success) {
            $0.imageDatas  = []
            $0.isLoading   = false
            $0.hasSearched = true
            $0.hasNextPage = false
        }
    }
 
    // MARK: - ページングテスト
 
    @Test
    func loadNextPage_次ページ取得成功() async throws {
        let dummyImages = self.dummyImages
        let nextPageImages = [
            ImageData(url: URL(string: "https://msp.c.yimg.jp/test4.jpg")!),
            ImageData(url: URL(string: "https://msp.c.yimg.jp/test5.jpg")!)
        ]
 
        // 初回検索済みの状態からスタート
        let initialState = ImageSearchFeature.State(
            searchText:  "ダックス",
            imageDatas:  dummyImages,
            isLoading:   false,
            hasSearched: true,
            currentPage: 1,
            hasNextPage: true
        )
 
        let store = TestStore(initialState: initialState) {
            ImageSearchFeature()
        } withDependencies: {
            // 次ページの画像を返すモックを注入
            $0.imageSearchClient = ImageSearchClient(
                search: { _, _ in nextPageImages }
            )
        }
 
        // 次ページ取得トリガー → ローディング開始
        await store.send(.loadNextPage) {
            $0.isLoading = true
        }
 
        // 次ページ結果が返ってくる → 既存リストに追加される
        await store.receive(\.loadNextPageResponse.success) {
            $0.isLoading   = false
            $0.currentPage = 2
            $0.imageDatas  = dummyImages + nextPageImages
            $0.hasNextPage = true
        }
    }
 
    @Test
    func loadNextPage_ローディング中はスキップ() async throws {
        // isLoading=trueの状態ではloadNextPageが無視される
        let initialState = ImageSearchFeature.State(
            imageDatas:  dummyImages,
            isLoading:   true,
            hasSearched: true
        )
 
        let store = TestStore(initialState: initialState) {
            ImageSearchFeature()
        }
 
        // Effectが発火しないのでreceiveなし
        await store.send(.loadNextPage)
    }
 
    @Test
    func loadNextPage_検索前はスキップ() async throws {
        // hasSearched=falseの状態ではloadNextPageが無視される
        let store = TestStore(initialState: ImageSearchFeature.State()) {
            ImageSearchFeature()
        }
 
        // Effectが発火しないのでreceiveなし
        await store.send(.loadNextPage)
    }
 
    // MARK: - 詳細画面テスト
 
    @Test
    func imageTapped_詳細画面が開く() async throws {
        let dummyImages = self.dummyImages
        let initialState = ImageSearchFeature.State(
            imageDatas:  dummyImages,
            hasSearched: true
        )
 
        let store = TestStore(initialState: initialState) {
            ImageSearchFeature()
        }
 
        // 画像タップ → selectedImageがセットされ詳細画面が開く
        await store.send(.imageTapped(dummyImages[0])) {
            $0.selectedImage   = dummyImages[0]
            $0.isShowingDetail = true
        }
    }
 
    @Test
    func detailDismissed_詳細画面が閉じる() async throws {
        let dummyImages = self.dummyImages
        // 詳細画面が開いている状態からスタート
        let initialState = ImageSearchFeature.State(
            imageDatas:      dummyImages,
            selectedImage:   dummyImages[0],
            isShowingDetail: true
        )
 
        let store = TestStore(initialState: initialState) {
            ImageSearchFeature()
        }
 
        // 詳細画面を閉じる → isShowingDetailがfalseになる
        await store.send(.detailDismissed) {
            $0.isShowingDetail = false
        }
    }
 
    @Test
    func selectedImageChanged_スワイプで選択画像が変わる() async throws {
        let dummyImages = self.dummyImages
        // 詳細画面で最初の画像を表示している状態からスタート
        let initialState = ImageSearchFeature.State(
            imageDatas:      dummyImages,
            selectedImage:   dummyImages[0],
            isShowingDetail: true
        )
 
        let store = TestStore(initialState: initialState) {
            ImageSearchFeature()
        }
 
        // スワイプ → selectedImageが次の画像に変わる
        await store.send(.selectedImageChanged(dummyImages[1])) {
            $0.selectedImage = dummyImages[1]
        }
    }
}
