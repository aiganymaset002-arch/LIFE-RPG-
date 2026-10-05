//
//  WorldsView.swift
//  LIFE RPG
//
//  Миры: Personal / Academic / Developer / компании. Дерево навыков, этапы компании,
//  слабое место («Чтобы перейти на Rank S, слабое место — Sales. Выполни 3 следующих квеста»).
//

import SwiftUI

struct WorldsView: View {
    @EnvironmentObject private var store: RPGStore
    @State private var openWorld: String?
    @State private var newName = ""
    @State private var newType: WorldType = .company

    var body: some View {
        if let id = openWorld, store.state.world(id) != nil {
            WorldDetailView(worldId: id) { openWorld = nil }
        } else {
            list
        }
    }

    private var list: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                ScreenHeader(title: "Миры")
                Text("Одно достижение может давать XP сразу нескольким мирам.")
                    .font(GameFont.body(13, .medium)).foregroundStyle(RPGTheme.muted).multilineTextAlignment(.center)
                ForEach(store.state.worlds) { w in
                    Button { openWorld = w.id } label: { worldCard(w) }.buttonStyle(.plain)
                }
                OrnatePanel(title: "Новый мир") {
                    GameField(title: "Название", text: $newName, placeholder: "Например, MASHSTROY")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(WorldType.allCases) { t in
                                Button { newType = t } label: { StoneChip(text: "\(t.emoji) \(t.label)", selected: newType == t) }.buttonStyle(.plain)
                            }
                        }
                        .padding(.bottom, 3)
                    }
                    Button("Создать мир") {
                        let n = newName.trimmingCharacters(in: .whitespaces)
                        guard !n.isEmpty else { store.show("Введи название мира"); return }
                        store.addWorld(name: n, type: newType)
                        newName = ""
                    }
                    .buttonStyle(ChunkyButtonStyle(kind: store.calm ? .calm : .gold, size: 17))
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private func worldCard(_ w: World) -> some View {
        let s = store.state
        let x = s.worldXP(w.id)
        let r = RPGEngine.rank(for: x, scale: w.type.scale)
        return HStack(spacing: 12) {
            Medallion(icon: w.emoji, size: 62, gem: w.type == .company ? Color(hex: "C07A16") : Color(hex: "5B2FD1"), emoji: true)
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(w.name).font(GameFont.display(16)).foregroundStyle(RPGTheme.cream).outlined(RPGTheme.edgeDark, 0.9).lineLimit(1)
                    Spacer()
                    RankShield(id: r.rank.id, size: 32)
                }
                Text("\(w.type.label) · \(r.rank.name)\(r.next.map { " → \($0.name)" } ?? "")").font(GameFont.body(11.5, .bold)).foregroundStyle(RPGTheme.muted).lineLimit(1)
                GameBar(progress: r.progress, height: 14, label: "\(RPGFormat.xp(x)) / \(r.next.map { RPGFormat.xp($0.min) } ?? "∞")")
                Text("Verified: \(RPGFormat.xp(s.worldXP(w.id, verifiedOnly: true))) ✓").font(GameFont.body(11, .bold)).foregroundStyle(RPGTheme.ok)
            }
        }
        .padding(16)
        .background(PanelBackground(radius: 20))
    }
}

struct WorldDetailView: View {
    @EnvironmentObject private var store: RPGStore
    let worldId: String
    let back: () -> Void
    @State private var confirmDelete = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                if let w = store.state.world(worldId) { content(w) }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    @ViewBuilder
    private func content(_ w: World) -> some View {
        let s = store.state
        let x = s.worldXP(w.id)
        let r = RPGEngine.rank(for: x, scale: w.type.scale)
        let cx = s.categoryXP(worldId: w.id)
        let ws = s.weakSpot(w.id)
        let openQs = s.quests.filter { q in q.roadmapId == nil && !q.isDone && q.status != .failed && q.mainAward?.worldId == w.id }
        let doneQs = Array(s.quests.filter { q in q.isDone && q.awards.contains { a in a.worldId == w.id } }.prefix(40))

        ScreenHeader(title: w.name, back: back)

        OrnatePanel {
            HStack(spacing: 14) {
                Medallion(icon: w.emoji, size: 70, gem: w.type == .company ? Color(hex: "C07A16") : Color(hex: "5B2FD1"), emoji: true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(w.type == .company ? "COMPANY LEVEL" : "RANK").font(GameFont.display(11)).foregroundStyle(RPGTheme.muted)
                    GameLabel(text: "\(r.rank.id) — \(r.rank.name)", size: 20, color: RPGTheme.rankAccent(r.rank.id))
                    Text(r.next.map { "Next level: \($0.id) — \($0.name)" } ?? "MAX").font(GameFont.body(12, .bold)).foregroundStyle(RPGTheme.cream)
                }
                Spacer()
                RankShield(id: r.rank.id, size: 52)
            }
            GameBar(progress: r.progress, height: 20, label: "\(RPGFormat.xp(x)) / \(r.next.map { RPGFormat.xp($0.min) } ?? "∞") XP")
            Text("Verified \(RPGFormat.xp(s.worldXP(w.id, verifiedOnly: true))) ✓").font(GameFont.body(12, .bold)).foregroundStyle(RPGTheme.ok)
            if w.type == .company { stages(r) }
        }

        OrnatePanel(title: "Дерево навыков") {
            ForEach(w.type.categories, id: \.self) { c in
                SkillRow(cat: c, xp: cx[c] ?? 0, weak: ws?.cat == c)
            }
        }
        .padding(.top, 10)

        if let ws {
            OrnatePanel(title: "Слабое место") {
                Text("💡 Чтобы перейти на \(r.next.map { "Rank \($0.id)" } ?? "следующий уровень"), слабое место — \(RPGData.category(ws.cat).label) (\(ws.rank)). Выполни 3 следующих квеста:")
                    .font(GameFont.body(14, .bold)).foregroundStyle(RPGTheme.cream)
                ForEach(ws.open) { q in
                    Button { store.open(.quest(q.id)) } label: { QuestCard(quest: q) }.buttonStyle(.plain)
                }
                ForEach(Array(ws.suggestions.prefix(Swift.max(0, 3 - ws.open.count))), id: \.self) { sug in
                    Button { store.addSuggestion(sug, worldId: w.id, cat: ws.cat) } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill").foregroundStyle(RPGTheme.gold)
                            Text(sug).font(GameFont.body(14, .bold)).foregroundStyle(RPGTheme.cream).multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "1A1032")))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(RPGTheme.gold.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [5])))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 10)
        }

        if !openQs.isEmpty {
            SectionTitle(text: "Открытые квесты")
            ForEach(openQs) { q in
                Button { store.open(.quest(q.id)) } label: { QuestCard(quest: q) }.buttonStyle(.plain)
            }
        }

        OrnatePanel(title: "Выполнено") {
            if doneQs.isEmpty { Text("Пока пусто").font(GameFont.body(14)).foregroundStyle(RPGTheme.muted) }
            ForEach(doneQs) { q in
                Button { store.open(.quest(q.id)) } label: {
                    HStack(alignment: .top) {
                        Text(s.isVerified(q) ? "✓" : "·").font(GameFont.display(13)).foregroundStyle(RPGTheme.ok)
                        Text(q.title).font(GameFont.body(13.5, .semibold)).foregroundStyle(RPGTheme.cream).multilineTextAlignment(.leading)
                        Spacer()
                        Text("+\(RPGFormat.xp(s.questXP(q, worldId: w.id)))").font(GameFont.display(12)).foregroundStyle(RPGTheme.gold)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            Button("Удалить мир") { confirmDelete = true }
                .buttonStyle(ChunkyButtonStyle(kind: .stone, size: 14))
                .confirmationDialog("Удалить мир? XP, начисленный ему, пропадёт.", isPresented: $confirmDelete, titleVisibility: .visible) {
                    Button("Удалить", role: .destructive) {
                        if s.worlds.count <= 1 { store.show("Нужен хотя бы один мир"); return }
                        back()
                        store.deleteWorld(w.id)
                    }
                }
        }
        .padding(.top, 10)
    }

    private func stages(_ r: RankProgress) -> some View {
        let idx = Swift.min(RPGData.companyStages.count - 1, Int((Double(r.index) * 1.6 + r.progress * 1.6).rounded()))
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(RPGData.companyStages.enumerated()), id: \.offset) { i, st in
                    Text(st)
                        .font(GameFont.display(9.5))
                        .foregroundStyle(i == idx ? Color(hex: "2A1600") : (i < idx ? RPGTheme.ok : RPGTheme.muted))
                        .padding(.horizontal, 7).padding(.vertical, 5)
                        .background(Capsule().fill(i == idx ? AnyShapeStyle(RPGTheme.goldGradient) : AnyShapeStyle(Color(hex: "1A1032"))))
                        .overlay(Capsule().strokeBorder(i < idx ? RPGTheme.ok.opacity(0.5) : Color.black.opacity(0.5), lineWidth: 1))
                    if i < RPGData.companyStages.count - 1 { Image(systemName: "chevron.right").font(.system(size: 8, weight: .black)).foregroundStyle(RPGTheme.muted) }
                }
            }
            .padding(.vertical, 2)
        }
    }
}
