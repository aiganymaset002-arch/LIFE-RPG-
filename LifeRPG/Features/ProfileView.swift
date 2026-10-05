//
//  ProfileView.swift
//  LIFE RPG
//
//  Профиль: результат, итоговая шкала уровней, следующий уровень, достижения,
//  результаты по направлениям, настройки, экспорт/импорт. Экран рангов E → SSS.
//

import SwiftUI
import UniformTypeIdentifiers

struct ProfileView: View {
    @EnvironmentObject private var store: RPGStore
    @State private var name = ""
    @State private var age = ""
    @State private var location = ""
    @State private var mode: GameMode = .life
    @State private var calm = false
    @State private var parent = false
    @State private var openQuest: QuestRef?
    @State private var showAdd = false
    @State private var importing = false
    @State private var confirmReset = false
    @State private var exportURL: URL?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RPGScreen(title: "Профиль") {
                summary
                achievementsAndGroups
                settings
            }
            AddButton { showAdd = true }
        }
        .sheet(item: $openQuest) { ref in QuestDetailView(questId: ref.id) }
        .sheet(isPresented: $showAdd) { AddResultView() }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            if case .success(let url) = result {
                store.show(store.importFile(url) ? "Игра загружена" : "Не удалось прочитать файл")
            }
        }
        .onAppear(perform: loadSettings)
    }

    private func loadSettings() {
        guard let p = store.state.profile else { return }
        name = p.name
        age = p.age.map { String($0) } ?? ""
        location = p.location
        mode = p.mode
        calm = store.state.settings.calm
        parent = store.state.settings.parentConfirm
        exportURL = store.exportFile()
    }

    @ViewBuilder
    private var summary: some View {
        let s = store.state
        let p = s.playerRank()
        let xp = s.playerXP()
        let scale = RPGData.ranks(s.playerScale)
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("РЕЗУЛЬТАТ · Общий XP").font(.system(size: 12, weight: .semibold)).foregroundStyle(RPGTheme.muted)
                (Text(RPGFormat.xp(xp)).font(.system(size: 38, weight: .heavy)).foregroundColor(RPGTheme.gold)
                    + Text(" \(store.unit)").font(.system(size: 16, weight: .semibold)).foregroundColor(RPGTheme.muted))
                Text("Verified \(RPGFormat.xp(s.playerXP(verifiedOnly: true))) ✓ · \(s.quests.filter(\.isDone).count) результатов")
                    .font(.system(size: 12.5)).foregroundStyle(RPGTheme.muted)
            }
            Spacer()
            Text("🏆").font(.system(size: 56)).shadow(color: RPGTheme.gold.opacity(0.55), radius: 16)
        }
        .rpgCard(padding: 16, stroke: RPGTheme.gold.opacity(0.35), fill: AnyShapeStyle(LinearGradient(colors: [Color(hex: "2A1D10"), RPGTheme.card], startPoint: .topLeading, endPoint: .bottomTrailing)))
        .padding(.top, 8)

        HStack {
            Text("ИТОГОВАЯ ШКАЛА УРОВНЕЙ").font(.system(size: 13, weight: .bold)).tracking(1).foregroundStyle(RPGTheme.gold)
            Spacer()
            NavigationLink("Подробно →") { RanksView() }.font(.system(size: 14, weight: .semibold)).foregroundStyle(RPGTheme.violet2)
        }
        .padding(.top, 16)
        HStack(spacing: 4) {
            ForEach(scale) { r in
                VStack(spacing: 2) {
                    Text(r.id).font(.system(size: 15, weight: .heavy, design: .serif))
                    Text(compact(r.min)).font(.system(size: 8.5)).foregroundStyle(RPGTheme.muted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 10).fill(r.id == p.rank.id ? AnyShapeStyle(LinearGradient(colors: [Color(hex: "6B3DF0"), Color(hex: "3A1D9A")], startPoint: .top, endPoint: .bottom)) : AnyShapeStyle(RPGTheme.card)))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(r.id == p.rank.id ? RPGTheme.violet2 : RPGTheme.line, lineWidth: 1))
                .shadow(color: r.id == p.rank.id ? RPGTheme.violet.opacity(0.5) : .clear, radius: 8)
            }
        }
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("СЛЕДУЮЩИЙ УРОВЕНЬ").font(.system(size: 11, weight: .bold)).tracking(1).foregroundStyle(RPGTheme.muted)
                Text(p.next.map { "До ранга \($0.id) (\($0.name)) осталось" } ?? "Максимальный ранг").font(.system(size: 13, weight: .semibold))
            }
            Spacer()
            Text(p.next == nil ? "∞" : RPGFormat.xp(p.toNext)).font(.system(size: 28, weight: .heavy)).foregroundStyle(RPGTheme.gold)
        }
        .rpgCard(padding: 14)
    }

    private func compact(_ n: Int) -> String {
        n >= 1000 ? "\(n / 1000)k+" : "\(n)+"
    }

    @ViewBuilder
    private var achievementsAndGroups: some View {
        let s = store.state
        let cx = s.categoryXP()
        let done = s.quests.filter(\.isDone)
        let grouped = Dictionary(grouping: done) { $0.mainAward?.cat ?? "growth" }
        let order = grouped.keys.sorted { (cx[$0] ?? 0) > (cx[$1] ?? 0) }

        SectionHeader(title: "Достижения")
        AchievementGrid(items: s.achievements)

        SectionHeader(title: "Результаты по направлениям")
        ForEach(order, id: \.self) { c in
            let qs = grouped[c] ?? []
            DisclosureGroup {
                VStack(spacing: 0) {
                    ForEach(qs) { q in
                        Button { openQuest = QuestRef(id: q.id) } label: {
                            HStack(alignment: .top) {
                                Text("\(s.isVerified(q) ? "✓" : "·") \(q.title)").font(.system(size: 13.5)).multilineTextAlignment(.leading)
                                Spacer()
                                Text("+\(RPGFormat.xp(s.questXP(q)))").font(.system(size: 13, weight: .bold)).foregroundStyle(RPGTheme.gold)
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } label: {
                HStack {
                    Text("\(RPGData.category(c).emoji) \(RPGData.category(c).label)").font(.system(size: 14, weight: .bold))
                    Spacer()
                    Text("\(RPGFormat.xp(qs.reduce(0) { $0 + s.questXP($1) })) XP").font(.system(size: 13, weight: .bold)).foregroundStyle(RPGTheme.category(c))
                }
                .foregroundStyle(RPGTheme.text)
            }
            .tint(RPGTheme.muted)
            .rpgCard(padding: 12)
        }
    }

    @ViewBuilder
    private var settings: some View {
        SectionHeader(title: "Настройки")
        RPGField(title: "Имя", text: $name)
        HStack(spacing: 10) {
            RPGField(title: "Возраст", text: $age, keyboard: .numberPad)
            RPGField(title: "Город", text: $location)
        }
        Picker("Режим", selection: $mode) {
            ForEach(GameMode.allCases) { m in Text("\(m.emoji) \(m.label)").tag(m) }
        }
        .pickerStyle(.menu)
        .tint(RPGTheme.violet2)
        Toggle("Спокойный экран (без анимаций)", isOn: $calm).tint(RPGTheme.violet)
        Toggle("Подтверждение достижений родителем", isOn: $parent).tint(RPGTheme.violet)
        Button("Сохранить") {
            store.updateProfile(name: name.trimmingCharacters(in: .whitespaces), age: Int(age), location: location, mode: mode, calm: calm, parentConfirm: parent)
            exportURL = store.exportFile()
        }
        .buttonStyle(SecondaryButtonStyle())
        HStack(spacing: 10) {
            if let exportURL {
                ShareLink(item: exportURL) { Label("Экспорт", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity) }
                    .buttonStyle(SecondaryButtonStyle())
            }
            Button { importing = true } label: { Label("Импорт", systemImage: "square.and.arrow.down") }
                .buttonStyle(SecondaryButtonStyle())
        }
        Button("Начать заново", role: .destructive) { confirmReset = true }
            .font(.system(size: 14, weight: .semibold)).foregroundStyle(RPGTheme.bad).frame(maxWidth: .infinity).padding(.top, 4)
            .confirmationDialog("Стереть игру и начать заново?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Стереть", role: .destructive) { store.reset() }
            }
        Text("You don’t play a character. You build yourself.\nYou don’t build a virtual empire. You build a real one.")
            .font(.system(size: 13, design: .serif)).foregroundStyle(RPGTheme.muted).multilineTextAlignment(.center)
            .frame(maxWidth: .infinity).padding(.top, 16)
    }
}

struct RanksView: View {
    @EnvironmentObject private var store: RPGStore

    var body: some View {
        let current = store.state.playerRank().rank.id
        let list = RPGData.personRanks
        RPGScreen(title: "Ранги") {
            Text("AIGANYM LIFE RPG").legendTitle(26).foregroundStyle(RPGTheme.gold).frame(maxWidth: .infinity).padding(.top, 10)
            Text("Твоя жизнь — твоя игра. Прокачивай себя к легенде.").font(.footnote).foregroundStyle(RPGTheme.muted).frame(maxWidth: .infinity)
            Text("Ранг показывает не «сколько задач выполнено», а насколько далеко ты продвинулась в реальной жизненной траектории.")
                .font(.subheadline).foregroundStyle(RPGTheme.muted).padding(.top, 6)
            ForEach(Array(list.enumerated()), id: \.offset) { i, r in
                let info = RPGData.rankInfo[r.id]
                let next: RankDef? = i + 1 < list.count ? list[i + 1] : nil
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        RankBadge(id: r.id, size: 52)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(r.name).font(.system(size: 18, weight: .bold, design: .serif))
                            Text("\(RPGFormat.xp(r.min))\(next.map { "–" + RPGFormat.xp($0.min - 1) } ?? "+") XP").font(.footnote).foregroundStyle(RPGTheme.muted)
                        }
                        Spacer()
                        if r.id == current {
                            Text("ТЫ ЗДЕСЬ").font(.system(size: 10, weight: .heavy)).padding(.horizontal, 8).padding(.vertical, 4)
                                .background(RoundedRectangle(cornerRadius: 6).fill(RPGTheme.violet))
                        }
                    }
                    if let info {
                        Text("Цель: \(info.goal)").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(hex: r.colorHex))
                        VStack(alignment: .leading, spacing: 3) {
                            ForEach(info.needs, id: \.self) { n in Text("• \(n)").font(.system(size: 13.5)).foregroundStyle(Color(hex: "D6D1F5")) }
                        }
                        Text(info.motto).font(.system(size: 12.5).italic()).foregroundStyle(RPGTheme.muted)
                    }
                }
                .rpgCard(padding: 14, stroke: r.id == current ? RPGTheme.violet2 : RPGTheme.line)
                .shadow(color: r.id == current ? RPGTheme.violet.opacity(0.35) : .clear, radius: 12)
            }
            SectionHeader(title: "Как получать XP (стандартная шкала)")
            ForEach(RPGData.xpTiers) { t in
                HStack {
                    Text(t.label).font(.system(size: 13.5))
                    Spacer()
                    Text("+\(RPGFormat.xp(t.min))–\(RPGFormat.xp(t.max))").font(.system(size: 13.5, weight: .bold)).foregroundStyle(RPGTheme.gold)
                }
                .rpgCard(padding: 10)
            }
            Text("Свои критерии и веса можно создавать — они входят в Total XP, но не в Verified XP. Verified XP подтверждается сертификатами, GitHub, публикациями, дипломами, ссылками и портфолио.")
                .font(.footnote).foregroundStyle(RPGTheme.muted).padding(.top, 6)
        }
    }
}
