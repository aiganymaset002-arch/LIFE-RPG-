//
//  QuestDetailView.swift
//  LIFE RPG
//
//  Панель квеста: награды по мирам, Boss Battle, доказательство → Verified XP,
//  ✓ Выполнено, ✕ Не получилось → новый маршрут, подтверждение родителя.
//

import SwiftUI

struct QuestDetailView: View {
    @EnvironmentObject private var store: RPGStore
    let questId: String

    @State private var proofType = RPGData.proofTypes[0]
    @State private var proof = ""
    @State private var confirmDelete = false
    @State private var confirmParent = false

    private func close() { store.panel = nil }

    var body: some View {
        Group {
            if let q = store.state.quest(questId) {
                OrnatePanel(title: q.boss ? "Boss Battle" : "Квест", onClose: close) { details(q) }
            } else {
                OrnatePanel(title: "Квест", onClose: close) {
                    Text("Квест удалён").font(GameFont.body(15)).foregroundStyle(RPGTheme.muted)
                }
            }
        }
        .onAppear { if let q = store.state.quest(questId) { proof = q.proof } }
    }

    private var proofText: String {
        let v = proof.trimmingCharacters(in: .whitespacesAndNewlines)
        if v.isEmpty { return "" }
        return v.hasPrefix(proofType) ? v : "\(proofType): \(v)"
    }

    @ViewBuilder
    private func details(_ q: Quest) -> some View {
        let s = store.state
        let locked = s.isLocked(q)
        let tier = RPGData.tier(q.tier)
        let child = store.isKids || store.isSen

        HStack(alignment: .top, spacing: 12) {
            Medallion(icon: q.boss ? "🔥" : RPGData.category(q.mainAward?.cat ?? "growth").emoji, size: 64,
                      gem: q.boss ? RPGTheme.boss : RPGTheme.category(q.mainAward?.cat ?? "growth"), emoji: true, glow: q.boss)
            VStack(alignment: .leading, spacing: 6) {
                Text(q.title).font(GameFont.body(19, .heavy)).foregroundStyle(q.boss ? Color(hex: "FFC4B0") : RPGTheme.cream)
                    .fixedSize(horizontal: false, vertical: true)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        if !q.phase.isEmpty { tag(q.phase) }
                        if let d = q.day { tag("День \(d)") }
                        if let tier { tag(tier.label) } else if q.custom { tag("Свои критерии") }
                        if let b = q.branch { tag("🔄 \(b)") }
                    }
                }
            }
        }

        SectionTitle(text: "Награда")
        ForEach(Array(q.awards.enumerated()), id: \.offset) { _, a in
            let w = s.world(a.worldId)
            let c = RPGData.category(a.cat)
            HStack(spacing: 10) {
                Text(w?.emoji ?? "🌐").font(.system(size: 22))
                VStack(alignment: .leading, spacing: 1) {
                    Text(w?.name ?? a.worldId).font(GameFont.body(14, .bold)).foregroundStyle(RPGTheme.cream)
                    Text("\(c.emoji) \(c.label)").font(GameFont.body(12, .medium)).foregroundStyle(RPGTheme.muted)
                }
                Spacer()
                GameLabel(text: "+\(RPGFormat.xp(a.xp)) \(store.unit)", size: 16, color: RPGTheme.gold)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "1A1032")))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.black.opacity(0.5), lineWidth: 1.5))
        }

        if locked {
            InsetCard(stroke: RPGTheme.violet) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("🔒 Сначала выполни подготовительные квесты:").font(GameFont.body(14, .bold)).foregroundStyle(RPGTheme.cream)
                    ForEach(q.requires.compactMap { s.quest($0) }.filter { !$0.isDone }) { r in
                        Text("• \(r.title)").font(GameFont.body(13, .medium)).foregroundStyle(RPGTheme.muted)
                    }
                }
            }
        }
        if q.isDone {
            InsetCard(stroke: RPGTheme.ok.opacity(0.6), tint: RPGTheme.ok) {
                Text(doneText(q, verified: s.isVerified(q))).font(GameFont.body(14, .bold)).foregroundStyle(RPGTheme.cream)
            }
        }
        if q.status == .failed {
            InsetCard(stroke: RPGTheme.bad.opacity(0.6), tint: RPGTheme.bad) {
                Text("✕ Не получилось — маршрут перестроен. Это не проигрыш.").font(GameFont.body(14, .bold)).foregroundStyle(RPGTheme.cream)
            }
        }
        if q.status == .pending {
            InsetCard(stroke: RPGTheme.gold, tint: RPGTheme.gold) {
                Text("⏳ Ждёт подтверждения родителя").font(GameFont.body(14, .bold)).foregroundStyle(RPGTheme.cream)
            }
        }

        if !q.custom && !child {
            SectionTitle(text: "Доказательство → Verified XP")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(RPGData.proofTypes.filter { $0 != "Подтверждение родителя" }, id: \.self) { t in
                        Button { proofType = t } label: { StoneChip(text: t, selected: proofType == t) }.buttonStyle(.plain)
                    }
                }
            }
            GameField(title: "", text: $proof, placeholder: "Ссылка / номер сертификата / GitHub", keyboard: .URL)
        }

        Group {
            if !q.isDone && q.status == .open && !locked {
                Button("✓ Выполнено") {
                    store.complete(q.id, proof: proofText)
                    close()
                }
                .buttonStyle(ChunkyButtonStyle(kind: store.calm ? .calm : .green, size: 22))
            }
            if q.status == .pending {
                Button("👨‍👩‍👧 Подтвердить (родитель)") { confirmParent = true }
                    .buttonStyle(ChunkyButtonStyle(kind: .gold, size: 17))
                    .confirmationDialog("Подтвердить достижение как родитель?", isPresented: $confirmParent, titleVisibility: .visible) {
                        Button("Подтвердить") { store.confirm(q.id); close() }
                    }
            }
            if q.isDone && !q.custom && !child {
                Button("Сохранить доказательство") { store.setProof(q.id, proofText) }.buttonStyle(ChunkyButtonStyle(kind: .cyan, size: 15))
            }
            HStack(spacing: 10) {
                if !q.isDone && q.status == .open && q.roadmapId != nil && !child {
                    Button("✕ Не вышло") {
                        close()
                        store.fail(q.id)
                    }
                    .buttonStyle(ChunkyButtonStyle(kind: .red, size: 14))
                }
                if q.isDone {
                    Button("Отменить") { store.undo(q.id) }.buttonStyle(ChunkyButtonStyle(kind: .stone, size: 14))
                }
                Button("Удалить") { confirmDelete = true }
                    .buttonStyle(ChunkyButtonStyle(kind: .stone, size: 14))
                    .confirmationDialog("Удалить квест?", isPresented: $confirmDelete, titleVisibility: .visible) {
                        Button("Удалить", role: .destructive) { store.deleteQuest(q.id); close() }
                    }
            }
        }
    }

    private func doneText(_ q: Quest, verified: Bool) -> String {
        var t = "✓ Выполнено"
        if let d = q.doneAt { t += " · " + d.formatted(date: .abbreviated, time: .omitted) }
        if verified { t += " · Verified ✓" }
        else if q.custom { t += " · свои критерии (не входят в Verified XP)" }
        else { t += " · без доказательства" }
        return t
    }

    private func tag(_ t: String) -> some View {
        Text(t).font(GameFont.body(11, .bold)).foregroundStyle(RPGTheme.cream)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Capsule().fill(Color(hex: "1A1032")))
            .overlay(Capsule().strokeBorder(RPGTheme.edgeMid, lineWidth: 1))
    }
}
