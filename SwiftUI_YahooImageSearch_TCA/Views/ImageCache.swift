//
//  ImageCache.swift
//  SwiftUI_YahooImageSearch_TCA
//
//  Created by cano on 2026/04/23.
//

import SwiftUI

// MARK: - ImageCache
// NSCacheを使ったアプリ全体で共有するメモリキャッシュ
final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSURL, UIImage>()
 
    func get(_ url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }
 
    func set(_ url: URL, image: UIImage) {
        cache.setObject(image, forKey: url as NSURL)
    }
}
 
