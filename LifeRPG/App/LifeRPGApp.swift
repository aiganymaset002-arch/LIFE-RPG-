//
//  LifeRPGApp.swift
//  LIFE RPG
//
//  Твоя жизнь — твоя игра. Прокачивай себя к легенде.
//

import SwiftUI

@main
struct LifeRPGApp: App {
    /// Единое хранилище игры (все экраны).
    @StateObject private var store = RPGStore()
    @Environment(\.scenePhase) private var scenePhase

    init() { GameFont.register() }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .tint(RPGTheme.gold)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { store.saveNow() }
        }
    }
}
