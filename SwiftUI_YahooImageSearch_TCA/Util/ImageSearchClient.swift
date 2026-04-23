//
//  ImageSearchClient.swift
//  SwiftUI_YahooImageSearch_TCA
//
//  Created by cano on 2026/04/23.
//

import Foundation
import ComposableArchitecture
 
// MARK: - ImageSearchClient
// TCAのDependencyとして定義することでテスト時にモックに差し替えられる
struct ImageSearchClient {
    var search: (_ query: String, _ page: Int) async throws -> [ImageData]
}
 
// MARK: - DependencyKey
// TCAのDependencyシステムに登録する
extension ImageSearchClient: DependencyKey {
    // 本番用の実装
    static let liveValue = ImageSearchClient(
        search: { query, page in
            let start = (page - 1) * 40 + 1
            let urlStr = "https://search.yahoo.co.jp/image/search?ei=UTF-8&p=\(query)&n=40&b=\(start)"
            guard let encodedStr = urlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: encodedStr) else {
                throw ImageError.noData
            }
            var request = URLRequest(url: url)
            request.addValue(Constants.mail, forHTTPHeaderField: "User-Agent")
 
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw ImageError.serverError
            }
            guard let html = String(data: data, encoding: .utf8) else {
                throw ImageError.noData
            }
            return parseHTML(html)
        }
    )
 
    // テスト用の実装（空配列を返すだけ）
    static let testValue = ImageSearchClient(
        search: { _, _ in [] }
    )
}
 
// MARK: - DependencyValues
// DependencyValuesに追加することでReducer内で @Dependency として使える
extension DependencyValues {
    var imageSearchClient: ImageSearchClient {
        get { self[ImageSearchClient.self] }
        set { self[ImageSearchClient.self] = newValue }
    }
}
 
// MARK: - HTML Parser
// HTMLから画像URLを正規表現で抽出（Flutter版と同じロジック）
private func parseHTML(_ html: String) -> [ImageData] {
    let pattern = #"(https?)://msp.c.yimg.jp/([A-Z0-9a-z._%+\-/]{2,1024}).jpg"#
    guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
 
    let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))
    let urls = matches.compactMap { match -> String? in
        guard let range = Range(match.range, in: html) else { return nil }
        return String(html[range])
    }
 
    // 重複除外してImageDataに変換
    return Array(Set(urls)).compactMap { urlString in
        URL(string: urlString).map { ImageData(url: $0) }
    }
}
