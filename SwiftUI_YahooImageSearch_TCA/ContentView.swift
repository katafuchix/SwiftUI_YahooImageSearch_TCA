//
//  ContentView.swift
//  SwiftUI_YahooImageSearch_TCA
//
//  Created by cano on 2026/04/23.
//

import SwiftUI
import ComposableArchitecture
import ComposableArchitecture
import QGrid
import ActivityIndicatorView

struct ContentView: View {
    // TCAのStoreを@Bindableで受け取ることでStateの変化をViewに反映する
    @Bindable var store: StoreOf<ImageSearchFeature>
 
    var body: some View {
        ZStack {
            VStack {
                Spacer().frame(height: 20)
 
                // 検索バー
                // $store.searchText.sending(\.searchTextChanged) で
                // テキスト変更をActionとして発火する
                HStack(spacing: 20) {
                    Spacer()
                    TextField("検索キーワード", text: $store.searchText.sending(\.searchTextChanged))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    Spacer()
                }
 
                // 検索ボタン（3文字未満は無効）
                Button(action: {
                    store.send(.searchButtonTapped)
                }) {
                    Text("Search")
                }
                .disabled(!store.isButtonEnabled)
 
                Spacer()
 
                // 検索結果が空の場合
                if store.imageDatas.isEmpty && store.hasSearched && !store.isLoading {
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("\"\(store.searchText)\" に一致する画像は見つかりませんでした")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
 
                } else if !store.imageDatas.isEmpty {
                    ScrollView {
                        // AsyncImageを使うのでLazyVGridでシンプルに3列表示
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                            Section(
                                footer: Group {
                                    if store.hasNextPage {
                                        ActivityIndicatorView(
                                            isVisible: .constant(true),
                                            type: .growingArc(.black)
                                        )
                                        .frame(width: 30.0, height: 30.0)
                                        .onAppear {
                                            store.send(.loadNextPage)
                                        }
                                    }
                                }
                            ) {
                                ForEach(store.imageDatas) { data in
                                    GridCell(imageData: data)
                                        .onTapGesture {
                                            store.send(.imageTapped(data))
                                        }
                                }
                            }
                        }
                        .padding(8)
                    }
                    // 詳細画面
                    .fullScreenCover(isPresented: Binding(
                        get: { store.isShowingDetail },
                        set: { if !$0 { store.send(.detailDismissed) } }
                    )) {
                        ImageDetailView(
                            images: store.imageDatas,
                            selectedImage: Binding(
                                get: { store.selectedImage },
                                set: { store.send(.selectedImageChanged($0)) }
                            )
                        )
                    }
                }
            }
 
            // 初回検索中のみローディングを全面表示
            if store.isLoading && store.imageDatas.isEmpty {
                ActivityIndicatorView(
                    isVisible: .constant(true),
                    type: .growingArc(.black)
                )
                .frame(width: 50.0, height: 50.0)
            }
        }
    }
}

#Preview {
    ContentView(store: Store(initialState: ImageSearchFeature.State()) {
        ImageSearchFeature()
    })
}

