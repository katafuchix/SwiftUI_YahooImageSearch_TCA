//
//  CachedImageView.swift
//  SwiftUI_YahooImageSearch_TCA
//
//  Created by cano on 2026/04/23.
//

import SwiftUI

// MARK: - CachedImageView
// Refererを付けてリクエストし、取得した画像をNSCacheに保存する
struct CachedImageView: View {
    let url: URL
    @State private var uiImage: UIImage? = nil
 
    var body: some View {
        Group {
            if let image = uiImage {
                Image(uiImage: image).toThumbnail()
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
            }
        }
        .task {
            guard uiImage == nil else { return }
 
            // キャッシュにあればネットワーク通信せずに返す
            if let cached = ImageCache.shared.get(url) {
                uiImage = cached
                return
            }
 
            // キャッシュになければRefererを付けてネットワークから取得
            var request = URLRequest(url: url)
            request.addValue("https://search.yahoo.co.jp/", forHTTPHeaderField: "Referer")
            guard let (data, _) = try? await URLSession.shared.data(for: request),
                  let image = UIImage(data: data) else { return }
 
            // 取得した画像をキャッシュに保存
            ImageCache.shared.set(url, image: image)
            uiImage = image
        }
    }
}
