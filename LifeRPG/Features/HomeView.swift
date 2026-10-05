//
//  HomeView.swift
//  LIFE RPG
//
//  Лобби как в игре: слева круглые кнопки меню (Награды с уровнем, Квесты, Оракул, Миры),
//  справа герой на островке, внизу баннер текущего квеста и большая кнопка «ИГРАТЬ».
//  KIDS — «Сегодня у меня 3 маленьких квеста». SEN — спокойный экран «Сейчас / Потом».
//

import SwiftUI

struct QuestRef: Identifiable, Hashable { let id: String }

struct HomeView: View {
    @EnvironmentObject private var store: RPGStore
    @Binding var tab: RPGTab

    var body: some View {
        if store.isSen { senHome } else { lobby }
    }

    // MARK: Лобби

    private var lobby: some View {
        let s = store.state
        let p = s.playerRank()
        let xp = s.playerXP()
        let today = s.todayQuests(3)
        let next = today.first
        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                Button { tab = .profile } label: {
                    MenuRow(icon: "trophy.fill", title: store.isKids ? "Мои награды" : "Награды", gem: Color(hex: "7A45E8")) {
                        VStack(alignment: .leading, spacing: 3) {
                            GameBar(progress: p.progress, height: 12)
                                .frame(width: 140)
                            Text("Lv. \(p.rank.id)   \(RPGFormat.xp(xp)) / \(p.next.map { RPGFormat.xp($0.min) } ?? "∞")")
                                .font(GameFont.display(10.5)).foregroundStyle(RPGTheme.cream).outlined(RPGTheme.edgeDark, 0.8)
                        }
                    }
                }
                Button { tab = .map } label: {
                    MenuRow(icon: "map.fill", title: "Квесты", gem: Color(hex: "1F7BC8"), badge: today.isEmpty ? nil : "\(today.count)") {
                        Text(store.isKids ? "Сегодня маленькие квесты" : "Карта на \(s.roadmaps.last?.days ?? 90) дней")
                            .font(GameFont.body(11.5, .bold)).foregroundStyle(RPGTheme.cream).outlined(RPGTheme.edgeDark, 0.7)
                    }
                }
                Button { tab = .gm } label: {
                    MenuRow(icon: "sparkles", title: "Оракул", gem: Color(hex: "B04CFF")) {
                        Text("Мечта → игра").font(GameFont.body(11.5, .bold)).foregroundStyle(RPGTheme.cream).outlined(RPGTheme.edgeDark, 0.7)
                    }
                }
                Button { tab = .worlds } label: {
                    MenuRow(icon: "globe.europe.africa.fill", title: "Миры", gem: Color(hex: "1FA87A")) {
                        Text("\(s.worlds.count) мир(а)").font(GameFont.body(11.5, .bold)).foregroundStyle(RPGTheme.cream).outlined(RPGTheme.edgeDark, 0.7)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 14)

            Spacer()

            if let next {
                Button { store.open(.quest(next.id)) } label: { QuestBanner(quest: next, kids: store.isKids, count: today.count) }
                    .buttonStyle(.plain)
                    .padding(.bottom, 10)
            }

            HStack(spacing: 12) {
                Button { store.open(.add(nil)) } label: {
                    VStack(spacing: 3) {
                        Medallion(icon: "plus", size: 56, gem: Color(hex: "C07A16"))
                        Text("РЕЗУЛЬТАТ").font(GameFont.display(9.5)).foregroundStyle(RPGTheme.cream).outlined(RPGTheme.edgeDark, 0.8)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Добавить реальный результат")
                Button {
                    if let next { store.open(.quest(next.id)) } else { tab = .gm }
                } label: {
                    HStack(spacing: 10) {
                        Text(next == nil ? "Новая игра" : "Играть")
                        Image(systemName: "play.fill").font(.system(size: 20, weight: .black))
                    }
                }
                .buttonStyle(ChunkyButtonStyle(kind: .cyan, size: 26, radius: 20))
            }
            .padding(.bottom, 10)
        }
        .padding(.horizontal, 16)
    }

    // MARK: SEN

    private var senHome: some View {
        let s = store.state
        let next2 = s.todayQuests(2)
        let p = s.playerRank()
        return ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Привет, \(s.profile?.name ?? "")").font(GameFont.title(28)).foregroundStyle(RPGTheme.cream).padding(.top, 12)
                senLabel("СЕЙЧАС")
                VStack(alignment: .leading, spacing: 12) {
                    if let now = next2.first {
                        Text(now.title).font(GameFont.body(28, .bold)).foregroundStyle(RPGTheme.cream)
                        Text("Награда: \(RPGFormat.xp(now.mainAward?.xp ?? 0)) ⭐").font(GameFont.body(18, .bold)).foregroundStyle(Color(hex: "E8D38A"))
                        Button("✓ Готово") { store.complete(now.id) }
                            .buttonStyle(ChunkyButtonStyle(kind: .calm, size: 26))
                    } else {
                        Text("Всё сделано ⭐").font(GameFont.body(28, .bold)).foregroundStyle(RPGTheme.cream)
                    }
                }
                .padding(22)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 22).fill(RPGTheme.senCard))
                .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Color(hex: "2D3B4E"), lineWidth: 2))
                senLabel("ПОТОМ")
                Text(next2.count > 1 ? next2[1].title : "Отдых 🌿")
                    .font(GameFont.body(24, .bold)).foregroundStyle(RPGTheme.cream)
                    .padding(22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 22).fill(RPGTheme.senCard))
                    .opacity(0.7)
                Text("Мои звёзды: \(RPGFormat.xp(s.playerXP())) ⭐").font(GameFont.body(20, .bold)).foregroundStyle(RPGTheme.cream).padding(.top, 10)
                GameBar(progress: p.progress, height: 18, fill: LinearGradient(colors: [Color(hex: "A8D8CB"), RPGTheme.calm], startPoint: .top, endPoint: .bottom))
            }
            .padding(16)
        }
    }

    private func senLabel(_ t: String) -> some View {
        Text(t).font(GameFont.display(15)).tracking(2).foregroundStyle(Color(hex: "8FB3A8"))
    }
}

/// Кнопка меню лобби: медальон + название + подпись.
struct MenuRow<Sub: View>: View {
    let icon: String
    let title: String
    var gem: Color = Color(hex: "2B1C52")
    var badge: String? = nil
    @ViewBuilder var sub: Sub

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                Medallion(icon: icon, size: 58, gem: gem)
                if let badge {
                    Text(badge)
                        .font(GameFont.display(12))
                        .foregroundStyle(.white)
                        .frame(minWidth: 22, minHeight: 22)
                        .background(Circle().fill(RPGTheme.bossGradient))
                        .overlay(Circle().strokeBorder(RPGTheme.goldGradient, lineWidth: 1.5))
                        .offset(x: 4, y: -4)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                GameLabel(text: title, size: 21)
                sub
            }
        }
        .contentShape(Rectangle())
    }
}

/// Баннер внизу лобби (как «Fates Pass»): текущий квест или Boss Battle.
struct QuestBanner: View {
    @EnvironmentObject private var store: RPGStore
    let quest: Quest
    var kids = false
    var count = 1

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(quest.boss ? AnyShapeStyle(RPGTheme.bossGradient) : AnyShapeStyle(LinearGradient(colors: [Color(hex: "3FD8FF"), Color(hex: "1F5FD1")], startPoint: .top, endPoint: .bottom)))
                Text(quest.boss ? "🔥" : (kids ? "⭐" : "⚔️")).font(.system(size: 26))
            }
            .frame(width: 52, height: 60)
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(RPGTheme.goldGradient, lineWidth: 2))
            VStack(alignment: .leading, spacing: 3) {
                Text(kids ? "Сегодня у меня \(count) \(count == 1 ? "маленький квест" : "маленьких квеста")" : (quest.boss ? "BOSS BATTLE" : "Следующий квест"))
                    .font(GameFont.display(12.5)).foregroundStyle(quest.boss ? Color(hex: "FFB199") : RPGTheme.gold).outlined(RPGTheme.edgeDark, 0.8)
                Text(quest.title).font(GameFont.body(14, .bold)).foregroundStyle(RPGTheme.cream).lineLimit(2).multilineTextAlignment(.leading)
                Text("+\(RPGFormat.xp(quest.mainAward?.xp ?? 0)) \(store.unit)").font(GameFont.display(12)).foregroundStyle(RPGTheme.gold)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(LinearGradient(colors: [Color(hex: "2E5A8A").opacity(0.95), Color(hex: "1E1440").opacity(0.95)], startPoint: .topLeading, endPoint: .bottomTrailing))
                RoundedRectangle(cornerRadius: 14).strokeBorder(RPGTheme.goldGradient, lineWidth: 2)
            }
        )
        .shadow(color: .black.opacity(0.5), radius: 8, y: 4)
    }
}
