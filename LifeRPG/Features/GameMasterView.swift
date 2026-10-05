//
//  GameMasterView.swift
//  LIFE RPG
//
//  Оракул (AI Game Master): напиши мечту → получишь игру: главный квест, фазы, квесты по дням, Boss Battles, XP.
//

import SwiftUI

struct GameMasterView: View {
    @EnvironmentObject private var store: RPGStore
    @Binding var tab: RPGTab
    @State private var text = ""
    @State private var plan: GamePlan?
    @State private var worldChoice = ""
    @State private var glow = false

    private let examples = [
        "За 90 дней запустить и масштабировать «AIKEN Fashion House»",
        "IELTS 7.0 за 6 месяцев",
        "Мне 15 лет. Я хочу через три года поступить в MIT и создать технологическую компанию",
        "Хочу поступить в топовый университет и стать AI/software engineer",
        "Опубликовать научную статью в Scopus за 8 месяцев",
        "Стать сильным software engineer за полгода",
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                ZStack {
                    Circle().fill(RadialGradient(colors: [Color(hex: "C9A6FF").opacity(0.6), .clear], center: .center, startRadius: 10, endRadius: 110))
                        .frame(width: 220, height: 220)
                        .scaleEffect(glow ? 1.08 : 0.92)
                    ZStack {
                        Circle().fill(RadialGradient(colors: [Color(hex: "F2E6FF"), Color(hex: "A06BFF"), Color(hex: "3A1A8A")], center: .init(x: 0.35, y: 0.3), startRadius: 4, endRadius: 70))
                        Circle().fill(LinearGradient(colors: [.white.opacity(0.55), .clear], startPoint: .top, endPoint: .center)).padding(10)
                        Text("✨").font(.system(size: 40))
                    }
                    .frame(width: 112, height: 112)
                    .overlay(Circle().strokeBorder(RPGTheme.goldGradient, lineWidth: 4))
                    .shadow(color: RPGTheme.violet, radius: 20)
                }
                .frame(height: 170)
                .padding(.top, 4)

                OrnatePanel(title: "Оракул") {
                    Text("Напиши мечту обычным языком — Оракул превратит её в игру: главный квест, фазы, квесты, Boss Battles и XP.")
                        .font(GameFont.body(14, .medium)).foregroundStyle(RPGTheme.muted).multilineTextAlignment(.center).frame(maxWidth: .infinity)
                    GameField(title: "", text: $text, placeholder: "Например: IELTS 7.0 за 6 месяцев", multiline: true)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(examples, id: \.self) { e in
                                Button { text = e; plan = nil } label: { StoneChip(text: e.count > 34 ? String(e.prefix(33)) + "…" : e) }
                                    .buttonStyle(.plain)
                            }
                        }
                        .padding(.bottom, 3)
                    }
                    Button("✨ Создать игру") {
                        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !t.isEmpty else { store.show("Напиши свою мечту"); return }
                        let p = GameMaster.generate(t, mode: store.state.profile?.mode ?? .life)
                        plan = p
                        worldChoice = defaultWorld(for: p)
                        if store.haptics { Haptics.tap() }
                    }
                    .buttonStyle(ChunkyButtonStyle(kind: store.calm ? .calm : .purple, size: 20))
                }

                if let plan { planView(plan) }

                Text("DREAM → AI ROADMAP → QUESTS → ✓ → XP → LEVEL UP → ACHIEVEMENTS → NEXT WORLD")
                    .font(GameFont.display(10)).foregroundStyle(RPGTheme.muted).multilineTextAlignment(.center)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .onAppear {
            guard !store.calm else { return }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { glow = true }
        }
    }

    private func defaultWorld(for p: GamePlan) -> String {
        let worlds = store.state.worlds
        if let n = p.worldName, let w = worlds.first(where: { $0.name.lowercased() == n.lowercased() }) { return w.id }
        if p.worldName != nil { return "new" }
        return worlds.first { $0.type == p.worldType }?.id ?? worlds.first?.id ?? "new"
    }

    private struct PhaseGroup: Identifiable {
        let id: Int
        let name: String
        var quests: [PlanQuest]
    }

    private func groups(_ plan: GamePlan) -> [PhaseGroup] {
        var out: [PhaseGroup] = []
        for q in plan.quests {
            if let last = out.indices.last, out[last].name == q.phase { out[last].quests.append(q) }
            else { out.append(PhaseGroup(id: out.count, name: q.phase, quests: [q])) }
        }
        return out
    }

    private func planView(_ plan: GamePlan) -> some View {
        OrnatePanel(title: "Главный квест") {
            Text(plan.title).font(GameFont.title(20)).foregroundStyle(RPGTheme.gold).multilineTextAlignment(.center).frame(maxWidth: .infinity)
            HStack(spacing: 6) {
                stat("📅", "\(plan.days) дн.")
                stat("⚔️", "\(plan.quests.count)")
                stat("🔥", "\(plan.bosses)")
                stat("⭐", RPGFormat.xp(plan.totalXP))
            }
            SectionTitle(text: "Мир для игры")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(store.state.worlds) { w in
                        Button { worldChoice = w.id } label: { StoneChip(text: "\(w.emoji) \(w.name)", selected: worldChoice == w.id) }.buttonStyle(.plain)
                    }
                    Button { worldChoice = "new" } label: { StoneChip(text: "＋ \(plan.worldName ?? plan.worldType.label)", selected: worldChoice == "new") }.buttonStyle(.plain)
                }
                .padding(.bottom, 3)
            }
            ForEach(groups(plan)) { g in
                SectionTitle(text: g.name)
                ForEach(Array(g.quests.enumerated()), id: \.offset) { _, q in
                    HStack(alignment: .top, spacing: 8) {
                        Text(q.boss ? "🔥" : "⚔️").font(.system(size: 14))
                        Text(q.title).font(GameFont.body(13.5, q.boss ? .heavy : .semibold)).foregroundStyle(q.boss ? Color(hex: "FFB199") : RPGTheme.cream)
                        Spacer()
                        Text("д.\(q.day) · +\(RPGFormat.xp(q.xp))").font(GameFont.display(11)).foregroundStyle(RPGTheme.gold)
                    }
                    .padding(.vertical, 3)
                }
            }
            Button("Начать игру ▶") {
                store.apply(plan, worldId: worldChoice == "new" ? nil : worldChoice)
                self.plan = nil
                text = ""
                tab = .map
            }
            .buttonStyle(ChunkyButtonStyle(kind: .cyan, size: 22))
            .padding(.top, 6)
        }
    }

    private func stat(_ icon: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(icon).font(.system(size: 18))
            Text(value).font(GameFont.display(13)).foregroundStyle(RPGTheme.cream).outlined(RPGTheme.edgeDark, 0.8).lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "1A1032")))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.black.opacity(0.5), lineWidth: 1.5))
    }
}
