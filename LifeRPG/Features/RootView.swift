//
//  RootView.swift
//  LIFE RPG
//
//  Онбординг или игра: вкладки Главная / Карта / Game Master / Миры / Профиль + Level Up, тосты, новый маршрут.
//

import SwiftUI

enum RPGTab: Hashable {
    case home, map, gm, worlds, profile
}

struct RootView: View {
    @EnvironmentObject private var store: RPGStore
    @State private var tab: RPGTab = .home
    @State private var openQuest: Quest?

    var body: some View {
        ZStack(alignment: .top) {
            if store.state.profile == nil {
                OnboardingView { tab = .map }
            } else {
                TabView(selection: $tab) {
                    NavigationStack { HomeView(tab: $tab) }
                        .tabItem { Label("Главная", systemImage: "house.fill") }
                        .tag(RPGTab.home)
                    NavigationStack { MapView(tab: $tab) }
                        .tabItem { Label("Карта", systemImage: "map.fill") }
                        .tag(RPGTab.map)
                    NavigationStack { GameMasterView(tab: $tab) }
                        .tabItem { Label("Game Master", systemImage: "sparkles") }
                        .tag(RPGTab.gm)
                    NavigationStack { WorldsView() }
                        .tabItem { Label("Миры", systemImage: "globe.europe.africa.fill") }
                        .tag(RPGTab.worlds)
                    NavigationStack { ProfileView() }
                        .tabItem { Label("Профиль", systemImage: "trophy.fill") }
                        .tag(RPGTab.profile)
                }
                .tint(store.isSen ? RPGTheme.calm : RPGTheme.gold)
            }

            if let t = store.toast {
                ToastView(toast: t)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onTapGesture { store.toast = nil }
                    .zIndex(2)
            }

            if let e = store.levelUp {
                LevelUpView(event: e, calm: store.calm, unit: store.unit) { store.levelUp = nil }
                    .transition(.opacity)
                    .zIndex(3)
            }
        }
        .animation(store.calm ? nil : .spring(response: 0.35), value: store.toast)
        .animation(store.calm ? nil : .easeInOut, value: store.levelUp?.id)
        .sheet(item: $store.reroute) { e in RerouteView(event: e) }
        .transaction { if store.calm { $0.animation = nil } }
    }
}

/// Фон экрана с прокруткой.
struct RPGScreen<Content: View>: View {
    @EnvironmentObject private var store: RPGStore
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) { content }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background {
            if store.isSen { RPGTheme.senBg.ignoresSafeArea() } else { RPGTheme.background }
        }
        .foregroundStyle(RPGTheme.text)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(RPGTheme.bg.opacity(0.9), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { TopRankBadge() }
        }
    }
}

struct TopRankBadge: View {
    @EnvironmentObject private var store: RPGStore
    var body: some View {
        let p = store.state.playerRank()
        HStack(spacing: 6) {
            Text("\(RPGFormat.xp(store.state.playerXP())) \(store.unit)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(RPGTheme.gold)
            RankBadge(id: p.rank.id, size: 26)
        }
    }
}
