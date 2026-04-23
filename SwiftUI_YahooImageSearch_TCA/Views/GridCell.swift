//
//  GridCell.swift
//  SwiftUI_YahooImageSearch_MVVM
//
//  Created by cano on 2026/01/31.
//

import SwiftUI
import Combine
import QGrid

struct GridCell: View {
    var imageData: ImageData

    var body: some View {
        CachedImageView(url: imageData.url)
    }
}
