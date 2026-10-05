//
//  WorldsView.swift
//  LIFE RPG
//
//  Миры: Personal / Academic / Developer / компании. Дерево развития, этапы компании,
//  слабое место («Чтобы перейти на Rank S, слабое место — Sales. Выполни 3 следующих квеста»).
//

import SwiftUI

struct WorldsView: View {
    @EnvironmentObject private var store: RPGStore
    @State private var newName = ""
    @State private var newType: WorldType = .company
    @State private var showAdd = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RPGScreen(title: "Миры") {
                Text("Одно достижение может давать XP сразу нескольким мирам.")
                    .font(.subheadline).foregroundStyle(RPGTheme.muted).padding(.top, 8)
                ForEach(store.state.worlds) { w in
                    NavigationLink { WorldDetailView(worldId: w.id) } label: { worldCard(w) }
                        .buttonStyle(.plain)
                }
                SectionHeader(title: "Новый мир")
                RPGField(title: "Название", text: $newName, placeholder: "Например, MASHSTROY")
                Picker("Тип", selection: $newType) {
                    ForEach(WorldType.allCases) { t in Text("\(t.emoji) \(t.label)").tag(t) }
                }
                .pickerStyle(.menu)
                .tint(RPGTheme.violet2)
                Button("Создать мир") {
                    let n = newName.trimmingCharacters(in: .whitespaces)
                    guard !n.isEmpty else { store.show("Введи название мира"); return }
                    store.addWorld(name: n, type: newType)
                    newName = ""
                }
                .buttonStyle(PrimaryButtonStyle(calm: store.calm))
            }
            AddButton { showAdd = true }
        }
        .sheet(isPresented: $showAdd) { AddResultView() }
    }

    private func worldCard(_ w: World) -> some View {
        let s = store.state
        let x = s.worldXP(w.id)
        let r = RPGEngine.rank(for: x, scale: w.type.scale)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(w.emoji).font(.system(size: 28))
                VStack(alignment: .leading, spacing: 2) {
                    Text(w.name).font(.system(size: 16, weight: .bold))
                    Text(w.type.label).font(.system(size: 12)).foregroundStyle(RPGTheme.muted)
                }
                Spacer()
                RankBadge(id: r.rank.id)
            }
            HStack {
                Text("\(RPGFormat.xp(x)) / \(r.next.map { RPGFormat.xp($0.min) } ?? "∞") XP")
                Spacer()
                Text(r.rank.name + (r.next.map { " → \($0.id) — \($0.name)" } ?? ""))
            }
            .font(.system(size: 12.5)).foregroundStyle(RPGTheme.muted)
            XPBar(progress: r.progress)
            Text("Verified: \(RPGFormat.xp(s.worldXP(w.id, verifiedOnly: true))) ✓").font(.system(size: 12)).foregroundStyle(RPGTheme.muted)
        }
        .rpgCard(padding: 14)
    }
}

struct WorldDetailView: View {
    @EnvironmentObject private var store: RPGStore
    @Environment(\.dismiss) private var dismiss
    let worldId: String
    @State private var openQuest: QuestRef?
    @State private var confirmDelete = false

    var body: some View {
        RPGScreen(title: store.state.world(worldId)?.name ?? "Мир") {
            if let w = store.state.world(worldId) { content(w) }
        }
        .sheet(item: $openQuest) { ref in QuestDetailView(questId: ref.id) }
    }

    @ViewBuilder
    private func content(_ w: World) -> some View {
        let s = store.state
        let x = s.worldXP(w.id)
        let r = RPGEngine.rank(for: x, scale: w.type.scale)
        let cx = s.categoryXP(worldId: w.id)
        let ws = s.weakSpot(w.id)
        let openQs = s.quests.filter { $0.roadmapId == nil && !$0.isDone && $0.status != .failed && $0.mainAward?.worldId == w.id }
        let doneQs = Array(s.quests.filter { q in q.isDone && q.awards.contains { a in a.worldId == w.id } }.prefix(40))

        HStack(spacing: 12) {
            Text(w.emoji).font(.system(size: 40))
            VStack(alignment: .leading) {
                Text(w.name).font(.title2.bold())
                Text(w.type.label).font(.footnote).foregroundStyle(RPGTheme.muted)
            }
        }
        .padding(.top, 8)

        VStack(alignment: .leading, spacing: 6) {
            (Text(w.type == .company ? "Company Level: " : "Rank: ") + Text("\(r.rank.id) — \(r.rank.name)").bold())
                .font(.system(size: 13)).foregroundStyle(RPGTheme.muted)
            (Text(RPGFormat.xp(x)).font(.system(size: 38, weight: .heavy)).foregroundColor(RPGTheme.gold)
                + Text(" / \(r.next.map { RPGFormat.xp($0.min) } ?? "∞") XP").font(.system(size: 16, weight: .semibold)).foregroundColor(RPGTheme.muted))
            XPBar(progress: r.progress)
            HStack {
                Text("Verified \(RPGFormat.xp(s.worldXP(w.id, verifiedOnly: true))) ✓")
                Spacer()
                Text(r.next.map { "Next level: \($0.id) — \($0.name)" } ?? "MAX")
            }
            .font(.system(size: 12.5)).foregroundStyle(RPGTheme.muted)
        }
        .rpgCard(padding: 16)

        if w.type == .company { stages(r) }

        SectionHeader(title: "Дерево развития")
        ForEach(w.type.categories, id: \.self) { c in
            CategoryRow(cat: c, xp: cx[c] ?? 0, weak: ws?.cat == c)
        }

        if let ws {
            VStack(alignment: .leading, spacing: 8) {
                Text("💡 Чтобы перейти на \(r.next.map { "Rank \($0.id)" } ?? "следующий уровень"), слабое место — \(RPGData.category(ws.cat).label) (\(ws.rank)).")
                    .font(.system(size: 15, weight: .bold))
                Text("Выполни 3 следующих квеста:").font(.system(size: 13)).foregroundStyle(RPGTheme.muted)
                ForEach(ws.open) { q in
                    Button { openQuest = QuestRef(id: q.id) } label: { QuestCard(quest: q, compact: true) }.buttonStyle(.plain)
                }
                ForEach(Array(ws.suggestions.prefix(Swift.max(0, 3 - ws.open.count))), id: \.self) { sug in
                    Button { store.addSuggestion(sug, worldId: w.id, cat: ws.cat) } label: {
                        Text("＋ \(sug)").font(.system(size: 14)).frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(RPGTheme.bg2))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(RPGTheme.line, style: StrokeStyle(lineWidth: 1, dash: [4])))
                    }
                    .buttonStyle(.plain)
                }
            }
            .rpgCard(padding: 14, stroke: RPGTheme.bad.opacity(0.4), fill: AnyShapeStyle(LinearGradient(colors: [RPGTheme.bad.opacity(0.12), RPGTheme.card], startPoint: .topLeading, endPoint: .bottomTrailing)))
            .padding(.top, 8)
        }

        if !openQs.isEmpty {
            SectionHeader(title: "Открытые квесты")
            ForEach(openQs) { q in
                Button { openQuest = QuestRef(id: q.id) } label: { QuestCard(quest: q) }.buttonStyle(.plain)
            }
        }

        Group {
        SectionHeader(title: "Выполнено")
        VStack(spacing: 0) {
            ForEach(doneQs) { q in
                Button { openQuest = QuestRef(id: q.id) } label: {
                    HStack(alignment: .top) {
                        Text("\(s.isVerified(q) ? "✓" : "·") \(q.title)").font(.system(size: 13.5)).multilineTextAlignment(.leading)
                        Spacer()
                        Text("+\(RPGFormat.xp(s.questXP(q, worldId: w.id)))").font(.system(size: 13, weight: .bold)).foregroundStyle(RPGTheme.gold)
                    }
                    .padding(.vertical, 9)
                }
                .buttonStyle(.plain)
                Divider().overlay(RPGTheme.line.opacity(0.6))
            }
        }
        if doneQs.isEmpty { Text("Пока пусто").foregroundStyle(RPGTheme.muted) }

        Button("Удалить мир", role: .destructive) { confirmDelete = true }
            .font(.system(size: 14, weight: .semibold)).foregroundStyle(RPGTheme.bad).frame(maxWidth: .infinity).padding(.top, 12)
            .confirmationDialog("Удалить мир? XP, начисленный ему, пропадёт.", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Удалить", role: .destructive) {
                    if s.worlds.count <= 1 { store.show("Нужен хотя бы один мир"); return }
                    dismiss()
                    store.deleteWorld(w.id)
                }
            }
        }
    }

    private func stages(_ r: RankProgress) -> some View {
        let idx = Swift.min(RPGData.companyStages.count - 1, Int((Double(r.index) * 1.6 + r.progress * 1.6).rounded()))
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(RPGData.companyStages.enumerated()), id: \.offset) { i, st in
                    Text(st)
                        .font(.system(size: 10.5, weight: .bold))
                        .padding(.horizontal, 7).padding(.vertical, 4)
                        .foregroundStyle(i == idx ? Color(hex: "1B1300") : (i < idx ? RPGTheme.ok : RPGTheme.muted))
                        .background(RoundedRectangle(cornerRadius: 8).fill(i == idx ? RPGTheme.gold : RPGTheme.card))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(i < idx ? RPGTheme.ok.opacity(0.4) : RPGTheme.line, lineWidth: 1))
                    if i < RPGData.companyStages.count - 1 { Text("→").font(.system(size: 10)).foregroundStyle(RPGTheme.muted) }
                }
            }
        }
        .padding(.top, 6)
    }
}
