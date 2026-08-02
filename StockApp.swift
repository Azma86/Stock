//
//  StockApp.swift
//  Stock
//
//  Created by Mitsuki Kimura on 2026/08/01.
//

import SwiftUI
import SwiftData

@main
struct StockApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: JobHuntSchema.allModels)
    }
}
