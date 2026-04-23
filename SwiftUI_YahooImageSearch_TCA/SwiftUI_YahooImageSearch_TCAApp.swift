//
//  SwiftUI_YahooImageSearch_TCAApp.swift
//  SwiftUI_YahooImageSearch_TCA
//
//  Created by cano on 2026/04/23.
//

import SwiftUI
import ComposableArchitecture

@main
struct SwiftUI_YahooImageSearch_TCAApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                store: Store(initialState: ImageSearchFeature.State()) {
                    ImageSearchFeature()
                }
            )
        }
    }
}

/*
 ImageSearchView(
     store: Store(initialState: ImageSearchFeature.State()) {
         ImageSearchFeature()
     }
 )
 */
