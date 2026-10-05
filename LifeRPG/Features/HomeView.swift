//
//  HomeView.swift
//  LIFE RPG
//
//  Главная: профиль, общий XP и Verified XP, сегодняшние квесты, направления, миры, события.
//  KIDS — карта приключения и «Сегодня у меня 3 маленьких квеста». SEN — спокойный экран «Сейчас / Потом».
//

import SwiftUI

struct QuestRef: Identifiable, Hashable { let id: String }

struct HomeView: View {
    @EnvironmentObject private var store: RPGStore
    @Binding var tab: RPGTab
    @State private var openQuest: QuestRef?
    @State private var showAdd = false

    var body: some View {
        Group {
            if store.isSen { senHome } else if store.isKids { kidsHome } else { lifeHome }
        }
        .sheet(item: $openQuest) { ref in QuestDetailView(questId: ref.id) }
        .sheet(isPresented: $showAdd) { AddResultView() }
    }

    // MARK: LIFE

    private var lifeHome: some View {
        let s = store.state
        let p = s.playerRank()
        let xp = s.playerXP()
        let vxp = s.playerXP(verifiedOnly: true)
        let cx = s.categoryXP()
        let today = s.todayQuests(3)
        return ZStack(alignment: .bottomTrailing) {
            RPGScreen(title: "LIFE RPG") {
                ProfileHeader()
                VStack(alignment: .leading, spacing: 6) {
                    Text("Общий XP").font(.system(size: 13, weight: .semibold)).foregroundStyle(RPGTheme.muted)
                    (Text(RPGFormat.xp(xp)).font(.system(size: 40, weight: .heavy)).foregroundColor(RPGTheme.gold)
                        + Text("  XP").font(.system(size: 16, weight: .semibold)).foregroundColor(RPGTheme.muted))
                    XPBar(progress: p.progress)
                    HStack {
                        Text("\(RPGFormat.xp(xp)) / \(p.next.map { RPGFormat.xp($0.min) } ?? "∞") XP")
                        Spacer()
                        Text(p.next.map { "→ ранг \($0.id): ещё \(RPGFormat.xp(p.toNext))" } ?? "Максимальный ранг")
                    }
                    .font(.system(size: 12.5)).foregroundStyle(RPGTheme.muted)
                    Divider().overlay(RPGTheme.line).padding(.vertical, 4)
                    HStack {
                        (Text("Verified XP ") + Text("\(RPGFormat.xp(vxp)) ✓").bold().foregroundColor(RPGTheme.ok))
                        Spacer()
                        (Text("Без доказательств ") + Text(RPGFormat.xp(xp - vxp)).bold())
                    }
                    .font(.system(size: 12.5)).foregroundStyle(RPGTheme.muted)
                }
                .rpgCard(padding: 16)

                SectionHeader(title: "Сегодняшние квесты", actionTitle: "Карта →") { tab = .map }
                if today.isEmpty {
                    Button { tab = .gm } label: {
                        Text("Нет активных квестов. Создай цель с AI Game Master →").font(.subheadline).foregroundStyle(RPGTheme.muted)
                            .frame(maxWidth: .infinity).padding(20)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(RPGTheme.line, style: StrokeStyle(lineWidth: 1, dash: [5])))
                    }
                } else {
                    ForEach(today) { q in
                        Button { openQuest = QuestRef(id: q.id) } label: { QuestCard(quest: q) }.buttonStyle(.plain)
                    }
                }

                SectionHeader(title: "Направления")
                ForEach(WorldType.personal.categories, id: \.self) { c in
                    CategoryRow(cat: c, xp: cx[c] ?? 0)
                }

                SectionHeader(title: "Миры", actionTitle: "Все →") { tab = .worlds }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(s.worlds) { w in
                            let r = s.worldRank(w)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(w.emoji).font(.system(size: 22))
                                Text(w.name).font(.system(size: 13, weight: .bold)).lineLimit(1)
                                Text("\(r.rank.id) · \(RPGFormat.xp(s.worldXP(w.id)))").font(.system(size: 12, weight: .bold)).foregroundStyle(RPGTheme.gold)
                            }
                            .frame(width: 112, alignment: .leading)
                            .rpgCard(padding: 12)
                        }
                    }
                }

                SectionHeader(title: "Последние события")
                VStack(spacing: 0) {
                    ForEach(s.log.prefix(6)) { l in
                        HStack(alignment: .top) {
                            Text(l.text).font(.system(size: 13.5))
                            Spacer()
                            if l.xp > 0 { Text("+\(RPGFormat.xp(l.xp))").font(.system(size: 13, weight: .bold)).foregroundStyle(RPGTheme.gold) }
                        }
                        .padding(.vertical, 9)
                        Divider().overlay(RPGTheme.line.opacity(0.6))
                    }
                }
            }
            AddButton { showAdd = true }
        }
    }

    // MARK: KIDS

    private var kidsHome: some View {
        let s = store.state
        let p = s.playerRank()
        let today = s.todayQuests(3)
        let pending = s.quests.filter { $0.status == .pending }
        let path = Array(RPGData.kidsRanks.prefix(5))
        return ZStack(alignment: .bottomTrailing) {
            RPGScreen(title: "Моё приключение") {
                Text("Привет, \(s.profile?.name ?? "")! 👋").font(.system(size: 26, weight: .heavy)).padding(.top, 6)
                HStack(spacing: 0) {
                    ForEach(Array(path.enumerated()), id: \.offset) { i, r in
                        VStack(spacing: 4) {
                            Text(r.icon).font(.system(size: 22))
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(i == p.index ? RPGTheme.gold.opacity(0.2) : RPGTheme.bg2))
                                .overlay(Circle().stroke(i < p.index ? RPGTheme.ok : (i == p.index ? RPGTheme.gold : RPGTheme.line), lineWidth: 2))
                                .scaleEffect(i == p.index ? 1.12 : 1)
                            Text(r.name).font(.system(size: 9.5, weight: .bold))
                        }
                        .opacity(i <= p.index ? 1 : 0.5)
                        if i < path.count - 1 {
                            Rectangle().fill(RPGTheme.line).frame(height: 3).frame(maxWidth: .infinity).padding(.bottom, 14)
                        }
                    }
                }
                .rpgCard(padding: 12, stroke: Color(hex: "2F6B55"), fill: AnyShapeStyle(LinearGradient(colors: [Color(hex: "1F3B2F"), RPGTheme.card], startPoint: .topLeading, endPoint: .bottomTrailing)))

                VStack(alignment: .leading, spacing: 6) {
                    Text("\(RPGFormat.xp(s.playerXP())) ⭐").font(.system(size: 38, weight: .heavy)).foregroundStyle(RPGTheme.gold)
                    XPBar(progress: p.progress)
                    HStack {
                        Text("\(p.rank.icon) \(p.rank.name)")
                        Spacer()
                        Text(p.next.map { "до \($0.icon) \($0.name): \(RPGFormat.xp(p.toNext)) ⭐" } ?? "🏆")
                    }
                    .font(.system(size: 13)).foregroundStyle(RPGTheme.muted)
                }
                .rpgCard(padding: 16)

                Text("Сегодня у меня \(today.count) \(today.count == 1 ? "маленький квест" : "маленьких квеста")")
                    .font(.system(size: 19, weight: .bold)).padding(.top, 14)
                if today.isEmpty { Text("Все квесты выполнены! 🎉").foregroundStyle(RPGTheme.muted) }
                ForEach(today) { q in
                    Button { openQuest = QuestRef(id: q.id) } label: { QuestCard(quest: q, big: true) }.buttonStyle(.plain)
                }
                if !pending.isEmpty {
                    Text("⏳ Ждут подтверждения родителя").font(.system(size: 17, weight: .bold)).padding(.top, 12)
                    ForEach(pending) { q in
                        Button { openQuest = QuestRef(id: q.id) } label: { QuestCard(quest: q) }.buttonStyle(.plain)
                    }
                }
                SectionHeader(title: "Мои награды")
                AchievementGrid(items: Array(s.achievements.prefix(8)))
            }
            AddButton { showAdd = true }
        }
    }

    // MARK: SEN

    private var senHome: some View {
        let s = store.state
        let next2 = s.todayQuests(2)
        let p = s.playerRank()
        return RPGScreen(title: "Мои шаги") {
            Text("Привет, \(s.profile?.name ?? "")").font(.system(size: 24, weight: .bold)).padding(.vertical, 8)
            senLabel("СЕЙЧАС")
            VStack(alignment: .leading, spacing: 10) {
                if let now = next2.first {
                    Text(now.title).font(.system(size: 26, weight: .bold))
                    Text("Награда: \(RPGFormat.xp(now.mainAward?.xp ?? 0)) ⭐").font(.system(size: 17, weight: .bold)).foregroundStyle(Color(hex: "E8D38A"))
                    Button("✓ Готово") { store.complete(now.id) }
                        .buttonStyle(PrimaryButtonStyle(calm: true))
                        .font(.system(size: 22, weight: .bold))
                        .padding(.top, 8)
                } else {
                    Text("Всё сделано ⭐").font(.system(size: 26, weight: .bold))
                }
            }
            .rpgCard(padding: 22, stroke: Color(hex: "2D3B4E"), fill: AnyShapeStyle(RPGTheme.senCard))
            senLabel("ПОТОМ")
            Text(next2.count > 1 ? next2[1].title : "Отдых 🌿")
                .font(.system(size: 24, weight: .bold))
                .rpgCard(padding: 22, stroke: Color(hex: "2D3B4E"), fill: AnyShapeStyle(RPGTheme.senCard))
                .opacity(0.7)
            Text("Мои звёзды: \(RPGFormat.xp(s.playerXP())) ⭐").font(.system(size: 18)).padding(.top, 16)
            XPBar(progress: p.progress, style: AnyShapeStyle(RPGTheme.calm))
        }
    }

    private func senLabel(_ t: String) -> some View {
        Text(t).font(.system(size: 14, weight: .heavy)).tracking(2).foregroundStyle(Color(hex: "8FB3A8")).padding(.top, 10)
    }
}

struct ProfileHeader: View {
    @EnvironmentObject private var store: RPGStore
    var body: some View {
        let s = store.state
        let p = s.playerRank()
        let prof = s.profile
        HStack(spacing: 12) {
            Text(String((prof?.name ?? "?").prefix(1)))
                .font(.system(size: 26, weight: .heavy))
                .frame(width: 58, height: 58)
                .background(RoundedRectangle(cornerRadius: 16).fill(RPGTheme.violetGradient))
            VStack(alignment: .leading, spacing: 2) {
                Text((prof?.name ?? "").uppercased()).font(.system(size: 20, weight: .heavy))
                Text([prof?.age.map { "Возраст: \($0)" }, prof?.location].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.system(size: 12.5)).foregroundStyle(RPGTheme.muted)
                (Text("RPG уровень ") + Text("\(p.rank.id) (\(p.rank.name))").bold().foregroundColor(RPGTheme.rankAccent(p.rank.id)))
                    .font(.system(size: 13))
            }
            Spacer()
            NavigationLink { RanksView() } label: {
                Text(p.rank.id)
                    .legendTitle(26)
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 62)
                    .background(ShieldShape().fill(LinearGradient(colors: [RPGTheme.violet2, Color(hex: "4B23B8")], startPoint: .top, endPoint: .bottom)))
                    .shadow(color: RPGTheme.violet.opacity(0.6), radius: 8)
            }
        }
        .rpgCard(padding: 14, fill: AnyShapeStyle(LinearGradient(colors: [RPGTheme.card2, RPGTheme.card], startPoint: .topLeading, endPoint: .bottomTrailing)))
        .padding(.top, 8)
    }
}

struct ShieldShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.15))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.6))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.6))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.15))
        p.closeSubpath()
        return p
    }
}

struct AddButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(Color(hex: "1B1300"))
                .frame(width: 58, height: 58)
                .background(Circle().fill(RPGTheme.goldGradient))
                .shadow(color: RPGTheme.gold.opacity(0.45), radius: 12, y: 6)
        }
        .padding(18)
        .accessibilityLabel("Добавить результат")
    }
}

struct AchievementGrid: View {
    let items: [Achievement]
    var body: some View {
        if items.isEmpty {
            Text("Выполни первый квест — и здесь появятся награды").font(.footnote).foregroundStyle(RPGTheme.muted)
        } else {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(items) { a in
                    VStack(spacing: 4) {
                        Text(a.icon).font(.system(size: 24))
                        Text(a.title).font(.system(size: 10.5)).foregroundStyle(RPGTheme.muted).multilineTextAlignment(.center).lineLimit(3)
                    }
                    .frame(maxWidth: .infinity, minHeight: 78)
                    .padding(.vertical, 8).padding(.horizontal, 4)
                    .background(RoundedRectangle(cornerRadius: 14).fill(RPGTheme.card))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(RPGTheme.line, lineWidth: 1))
                }
            }
        }
    }
}
