//
//  RootView.swift
//  LIFE RPG
//
//  Игровая оболочка: HUD сверху, док снизу (Лобби · Карта · Оракул · Миры · Герой),
//  всплывающие панели (квест, новый результат, настройки), Level Up, новый маршрут, тосты.
//

import SwiftUI

enum RPGTab: Hashable {
    case home, map, gm, worlds, profile
}

struct RootView: View {
    @EnvironmentObject private var store: RPGStore
    @State private var tab: RPGTab = RootView.launchTab()

    /// Аргумент запуска «-tab map|gm|worlds|profile» (для скриншотов).
    private static func launchTab() -> RPGTab {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-tab"), i + 1 < args.count else { return .home }
        switch args[i + 1] {
        case "map": return .map
        case "gm": return .gm
        case "worlds": return .worlds
        case "profile": return .profile
        default: return .home
        }
    }

    /// Аргумент запуска «-panel quest|settings|add» (для скриншотов).
    private func openLaunchPanel() {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-panel"), i + 1 < args.count else { return }
        switch args[i + 1] {
        case "settings": store.open(.settings)
        case "add": store.open(.add(nil))
        case "quest": if let q = store.state.todayQuests(1).first { store.open(.quest(q.id)) }
        default: break
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            if store.state.profile == nil {
                OnboardingView { tab = .map }
            } else {
                VStack(spacing: 0) {
                    GameHUD()
                    ZStack {
                        switch tab {
                        case .home: HomeView(tab: $tab)
                        case .map: MapView(tab: $tab)
                        case .gm: GameMasterView(tab: $tab)
                        case .worlds: WorldsView()
                        case .profile: ProfileView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    GameDock(tab: $tab)
                }
                .background {
                    if store.isSen {
                        RPGTheme.senBg.ignoresSafeArea()
                    } else {
                        ZStack {
                            GameBackground(dim: tab == .home ? 0 : 0.55)
                            if tab == .home {
                                Sparkles(count: 16, calm: store.calm).ignoresSafeArea()
                                HeroLayer(calm: store.calm)
                            }
                        }
                    }
                }
            }

            if let p = store.panel {
                PanelHost(panel: p)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(4)
            }

            if let e = store.reroute {
                RerouteView(event: e) { store.reroute = nil }
                    .transition(.opacity)
                    .zIndex(5)
            }

            if let e = store.levelUp {
                LevelUpView(event: e, calm: store.calm, unit: store.unit) { store.levelUp = nil }
                    .transition(.opacity)
                    .zIndex(6)
            }

            if let t = store.toast {
                ToastView(toast: t)
                    .padding(.top, 54)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onTapGesture { store.toast = nil }
                    .zIndex(7)
            }
        }
        .onAppear(perform: openLaunchPanel)
        .animation(store.calm ? nil : .spring(response: 0.32, dampingFraction: 0.85), value: store.toast)
        .animation(store.calm ? nil : .easeOut(duration: 0.2), value: store.panel)
        .animation(store.calm ? nil : .easeInOut, value: store.levelUp?.id)
        .animation(store.calm ? nil : .easeInOut, value: store.reroute?.id)
    }
}

// MARK: - HUD

struct GameHUD: View {
    @EnvironmentObject private var store: RPGStore
    var body: some View {
        let s = store.state
        let p = s.playerRank()
        let xp = s.playerXP()
        HStack(spacing: 10) {
            AvatarMedallion(avatar: store.avatar, size: 50, badge: p.rank.id)
            VStack(alignment: .leading, spacing: 4) {
                Text(s.profile?.name ?? "")
                    .font(GameFont.display(15))
                    .foregroundStyle(RPGTheme.cream)
                    .outlined(RPGTheme.edgeDark, 1)
                    .lineLimit(1)
                GameBar(progress: p.progress, height: 13, fill: RPGTheme.xpGradient,
                        label: p.next.map { "\(RPGFormat.xp(xp)) / \(RPGFormat.xp($0.min))" } ?? RPGFormat.xp(xp))
                    .frame(maxWidth: 150)
            }
            Spacer(minLength: 4)
            CurrencyPill(icon: "checkmark.seal.fill", text: RPGFormat.xp(s.playerXP(verifiedOnly: true)), tint: RPGTheme.ok)
            Button { store.open(.settings) } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(RPGTheme.cream)
                    .shadow(color: .black, radius: 0, y: 1.5)
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel("Настройки")
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
        .padding(.bottom, 8)
        .background(
            LinearGradient(colors: [Color(hex: "140A28").opacity(0.95), Color(hex: "140A28").opacity(0.6)], startPoint: .top, endPoint: .bottom)
                .overlay(alignment: .bottom) { Rectangle().fill(RPGTheme.goldGradient).frame(height: 1.5).opacity(0.8) }
                .ignoresSafeArea(edges: .top)
        )
    }
}

// MARK: - Док

struct GameDock: View {
    @EnvironmentObject private var store: RPGStore
    @Binding var tab: RPGTab

    private struct Item: Identifiable { let id: RPGTab; let icon: String; let title: String }
    private let items: [Item] = [
        Item(id: .home, icon: "house.fill", title: "Лобби"),
        Item(id: .map, icon: "map.fill", title: "Карта"),
        Item(id: .gm, icon: "sparkles", title: "Оракул"),
        Item(id: .worlds, icon: "globe.europe.africa.fill", title: "Миры"),
        Item(id: .profile, icon: "trophy.fill", title: "Герой"),
    ]

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(items) { it in
                Button {
                    if store.haptics { Haptics.tap() }
                    tab = it.id
                } label: {
                    VStack(spacing: 2) {
                        Medallion(icon: it.icon, size: it.id == .gm ? 58 : 44,
                                  gem: it.id == .gm ? RPGTheme.violet : (tab == it.id ? Color(hex: "7A45E8") : Color(hex: "2B1C52")),
                                  glow: tab == it.id)
                            .scaleEffect(tab == it.id ? 1.08 : 1)
                        Text(it.title.uppercased())
                            .font(GameFont.display(9.5))
                            .foregroundStyle(tab == it.id ? RPGTheme.gold : RPGTheme.muted)
                            .outlined(RPGTheme.edgeDark, 0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .offset(y: it.id == .gm ? -10 : 0)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(it.title)
            }
        }
        .padding(.horizontal, 6)
        .padding(.top, 6)
        .padding(.bottom, 2)
        .background(
            ZStack(alignment: .top) {
                LinearGradient(colors: [Color(hex: "2E2152"), Color(hex: "140A28")], startPoint: .top, endPoint: .bottom)
                Rectangle().fill(RPGTheme.goldGradient).frame(height: 2)
            }
            .ignoresSafeArea(edges: .bottom)
        )
        .animation(store.calm ? nil : .spring(response: 0.3), value: tab)
    }
}

// MARK: - Всплывающие панели

struct PanelHost: View {
    @EnvironmentObject private var store: RPGStore
    let panel: GamePanel

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea().onTapGesture { store.panel = nil }
            ScrollView {
                Group {
                    switch panel {
                    case .quest(let id): QuestDetailView(questId: id)
                    case .add(let rm): AddResultView(roadmapId: rm)
                    case .settings: SettingsPanel()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 40)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

// MARK: - Тосты

struct ToastView: View {
    let toast: ToastMessage
    var body: some View {
        Text(toast.text)
            .font(toast.isXP ? GameFont.display(22) : GameFont.body(15, .bold))
            .foregroundStyle(.white)
            .outlined(toast.isXP ? Color(hex: "9A5A0C") : RPGTheme.edgeDark, toast.isXP ? 1.6 : 1)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18).padding(.vertical, 12)
            .background(
                ZStack {
                    Capsule().fill(toast.isXP ? AnyShapeStyle(LinearGradient(colors: [Color(hex: "FFE48A"), Color(hex: "F3A92E")], startPoint: .top, endPoint: .bottom))
                                              : AnyShapeStyle(LinearGradient(colors: [Color(hex: "5A4690"), Color(hex: "2E2152")], startPoint: .top, endPoint: .bottom)))
                    Capsule().strokeBorder(RPGTheme.goldGradient, lineWidth: 2)
                }
            )
            .shadow(color: .black.opacity(0.5), radius: 12, y: 6)
            .padding(.horizontal, 20)
    }
}
