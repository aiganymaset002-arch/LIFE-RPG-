//
//  QuestDetailView.swift
//  LIFE RPG
//
//  Карточка квеста: награды по мирам, Boss Battle, доказательство → Verified XP,
//  ✓ Выполнено, ✕ Не получилось → новый маршрут, подтверждение родителя.
//

import SwiftUI

struct QuestDetailView: View {
    @EnvironmentObject private var store: RPGStore
    @Environment(\.dismiss) private var dismiss
    let questId: String

    @State private var proofType = RPGData.proofTypes[0]
    @State private var proof = ""
    @State private var confirmDelete = false
    @State private var confirmParent = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if let q = store.state.quest(questId) {
                    details(q)
                } else {
                    Text("Квест удалён").foregroundStyle(RPGTheme.muted).padding(40)
                }
            }
            .background(RPGTheme.bg2.ignoresSafeArea())
            .foregroundStyle(RPGTheme.text)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Закрыть") { dismiss() }.foregroundStyle(RPGTheme.violet2) }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(RPGTheme.bg2)
        .onAppear {
            if let q = store.state.quest(questId) { proof = q.proof }
        }
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
        VStack(alignment: .leading, spacing: 12) {
            if q.boss {
                Text("🔥 BOSS BATTLE").font(.system(size: 12, weight: .heavy)).tracking(1)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 8).fill(RPGTheme.bossGradient))
            }
            Text(q.title).font(.system(size: 21, weight: .bold)).foregroundStyle(q.boss ? Color(hex: "FFB199") : RPGTheme.text)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    if !q.phase.isEmpty { tag(q.phase) }
                    if let d = q.day { tag("День \(d)") }
                    if let tier { tag(tier.label) } else if q.custom { tag("Свои критерии") }
                    if let b = q.branch { tag("🔄 \(b)") }
                }
            }
            VStack(spacing: 6) {
                ForEach(Array(q.awards.enumerated()), id: \.offset) { _, a in
                    let w = s.world(a.worldId)
                    let c = RPGData.category(a.cat)
                    HStack {
                        Text("\(w?.emoji ?? "") \(w?.name ?? a.worldId) · \(c.emoji) \(c.label)").font(.system(size: 13.5))
                        Spacer()
                        Text("+\(RPGFormat.xp(a.xp)) \(store.unit)").font(.system(size: 14, weight: .bold)).foregroundStyle(RPGTheme.gold)
                    }
                    .rpgCard(padding: 10)
                }
            }

            if locked {
                VStack(alignment: .leading, spacing: 6) {
                    Text("🔒 Сначала выполни подготовительные квесты:").font(.system(size: 14, weight: .semibold))
                    ForEach(q.requires.compactMap { s.quest($0) }.filter { !$0.isDone }) { r in
                        Text("• \(r.title)").font(.system(size: 13.5))
                    }
                }
                .rpgCard(padding: 12, stroke: RPGTheme.violet, fill: AnyShapeStyle(RPGTheme.violet.opacity(0.12)))
            }
            if q.isDone {
                Text(doneText(q, verified: s.isVerified(q)))
                    .font(.system(size: 13.5))
                    .rpgCard(padding: 12, stroke: RPGTheme.ok.opacity(0.45), fill: AnyShapeStyle(RPGTheme.ok.opacity(0.12)))
            }
            if q.status == .failed {
                Text("✕ Не получилось — маршрут перестроен. Это не проигрыш.").font(.system(size: 13.5))
                    .rpgCard(padding: 12, stroke: RPGTheme.bad.opacity(0.45), fill: AnyShapeStyle(RPGTheme.bad.opacity(0.12)))
            }
            if q.status == .pending {
                Text("⏳ Ждёт подтверждения родителя").font(.system(size: 13.5))
                    .rpgCard(padding: 12, stroke: RPGTheme.gold, fill: AnyShapeStyle(RPGTheme.gold.opacity(0.12)))
            }

            if !q.custom && !child {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Доказательство → Verified XP").font(.system(size: 13, weight: .semibold)).foregroundStyle(RPGTheme.muted)
                    Picker("Тип", selection: $proofType) {
                        ForEach(RPGData.proofTypes, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .tint(RPGTheme.violet2)
                    RPGField(title: "", text: $proof, placeholder: "Ссылка / номер сертификата / GitHub", keyboard: .URL)
                }
            }

            VStack(spacing: 10) {
                if !q.isDone && q.status == .open && !locked {
                    Button("✓ Выполнено") {
                        store.complete(q.id, proof: proofText)
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle(calm: store.calm))
                }
                if q.status == .pending {
                    Button("👨‍👩‍👧 Подтвердить (родитель)") { confirmParent = true }
                        .buttonStyle(PrimaryButtonStyle(calm: store.calm))
                        .confirmationDialog("Подтвердить достижение как родитель?", isPresented: $confirmParent, titleVisibility: .visible) {
                            Button("Подтвердить") { store.confirm(q.id); dismiss() }
                        }
                }
                if q.isDone && !q.custom && !child {
                    Button("Сохранить доказательство") { store.setProof(q.id, proofText) }.buttonStyle(SecondaryButtonStyle())
                }
                if !q.isDone && q.status == .open && q.roadmapId != nil && !child {
                    Button("✕ Не получилось → перестроить маршрут") {
                        dismiss()
                        store.fail(q.id)
                    }
                    .buttonStyle(SecondaryButtonStyle(tint: RPGTheme.muted))
                }
                if q.isDone {
                    Button("Отменить выполнение") { store.undo(q.id) }.buttonStyle(SecondaryButtonStyle(tint: RPGTheme.muted))
                }
                Button("Удалить квест", role: .destructive) { confirmDelete = true }
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(RPGTheme.bad).padding(.top, 4)
                    .confirmationDialog("Удалить квест?", isPresented: $confirmDelete, titleVisibility: .visible) {
                        Button("Удалить", role: .destructive) { store.deleteQuest(q.id); dismiss() }
                    }
            }
            .padding(.top, 4)
        }
        .padding(20)
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
        Text(t).font(.system(size: 12)).foregroundStyle(RPGTheme.muted)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 8).fill(RPGTheme.card))
    }
}
