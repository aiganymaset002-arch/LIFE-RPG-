//
//  GameMasterView.swift
//  LIFE RPG
//
//  AI Game Master: напиши мечту → получишь игру (главный квест, фазы, квесты по дням, Boss Battles, XP).
//

import SwiftUI

struct GameMasterView: View {
    @EnvironmentObject private var store: RPGStore
    @Binding var tab: RPGTab
    @State private var text = ""
    @State private var plan: GamePlan?
    @State private var worldChoice = ""

    private let examples = [
        "За 90 дней запустить и масштабировать «AIKEN Fashion House»",
        "IELTS 7.0 за 6 месяцев",
        "Мне 15 лет. Я хочу через три года поступить в MIT и создать технологическую компанию",
        "Хочу поступить в топовый университет и стать AI/software engineer",
        "Опубликовать научную статью в Scopus за 8 месяцев",
        "Стать сильным software engineer за полгода",
    ]

    var body: some View {
        RPGScreen(title: "Game Master") {
            VStack(spacing: 8) {
                Text("✨")
                    .font(.system(size: 34))
                    .frame(width: 72, height: 72)
                    .background(Circle().fill(RadialGradient(colors: [Color(hex: "D9B8FF"), RPGTheme.violet, Color(hex: "2B1680")], center: .topLeading, startRadius: 4, endRadius: 70)))
                    .shadow(color: RPGTheme.violet.opacity(0.6), radius: 20)
                Text("AI Game Master").font(.title2.bold())
                Text("Напиши мечту обычным языком — получишь игру: главный квест, фазы, квесты, Boss Battles и XP.")
                    .font(.subheadline).foregroundStyle(RPGTheme.muted).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 10)

            RPGTextArea(title: "", text: $text, placeholder: "Например: IELTS 7.0 за 6 месяцев")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(examples, id: \.self) { e in
                        Button { text = e; plan = nil } label: { Chip(text: e.count > 40 ? String(e.prefix(39)) + "…" : e) }
                    }
                }
            }
            Button("Сгенерировать игру") {
                let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !t.isEmpty else { store.show("Напиши свою мечту"); return }
                let p = GameMaster.generate(t, mode: store.state.profile?.mode ?? .life)
                plan = p
                worldChoice = defaultWorld(for: p)
            }
            .buttonStyle(PrimaryButtonStyle(calm: store.calm))

            if let plan { planView(plan) }

            Text("DREAM → AI ROADMAP → QUESTS → ✓ → XP → LEVEL UP → ACHIEVEMENTS → NEXT WORLD")
                .font(.system(size: 11)).foregroundStyle(RPGTheme.muted).frame(maxWidth: .infinity).multilineTextAlignment(.center).padding(.top, 8)
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

    @ViewBuilder
    private func planView(_ plan: GamePlan) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ГЛАВНЫЙ QUEST").font(.system(size: 11, weight: .heavy)).tracking(1).foregroundStyle(RPGTheme.gold)
            Text(plan.title).font(.system(size: 18, weight: .bold))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    statTag("📅 \(plan.days) дней")
                    statTag("⚔️ \(plan.quests.count) квестов")
                    statTag("🔥 \(plan.bosses) боссов")
                    statTag("⭐ \(RPGFormat.xp(plan.totalXP)) XP")
                }
            }
            Text("В каком мире играть").font(.system(size: 13, weight: .semibold)).foregroundStyle(RPGTheme.muted)
            Picker("Мир", selection: $worldChoice) {
                ForEach(store.state.worlds) { w in Text("\(w.emoji) \(w.name)").tag(w.id) }
                Text("＋ Новый мир: \(plan.worldName ?? plan.worldType.label)").tag("new")
            }
            .pickerStyle(.menu)
            .tint(RPGTheme.violet2)

            ForEach(groups(plan)) { g in
                VStack(alignment: .leading, spacing: 0) {
                    Text(g.name.uppercased()).font(.system(size: 12, weight: .heavy)).tracking(1).foregroundStyle(RPGTheme.violet2).padding(.bottom, 4)
                    ForEach(Array(g.quests.enumerated()), id: \.offset) { _, q in
                        HStack(alignment: .top) {
                            Text("\(q.boss ? "🔥" : "☐") \(q.title)")
                                .font(.system(size: 13.5, weight: q.boss ? .bold : .regular))
                                .foregroundStyle(q.boss ? Color(hex: "FFB199") : RPGTheme.text)
                            Spacer()
                            Text("д.\(q.day) · +\(RPGFormat.xp(q.xp))").font(.system(size: 12, weight: .bold)).foregroundStyle(RPGTheme.gold)
                        }
                        .padding(.vertical, 7)
                        Divider().overlay(RPGTheme.line.opacity(0.6))
                    }
                }
                .padding(.top, 4)
            }

            Button("Начать игру ▶") {
                let rm = store.apply(plan, worldId: worldChoice == "new" ? nil : worldChoice)
                _ = rm
                self.plan = nil
                text = ""
                tab = .map
            }
            .buttonStyle(PrimaryButtonStyle(calm: store.calm))
            .padding(.top, 6)
        }
        .rpgCard(padding: 14, stroke: RPGTheme.violet)
        .padding(.top, 10)
    }

    private func statTag(_ t: String) -> some View {
        Text(t).font(.system(size: 12.5)).padding(.horizontal, 8).padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 8).fill(RPGTheme.bg2))
    }
}
