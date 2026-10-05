//
//  AddResultView.swift
//  LIFE RPG
//
//  Добавить реальный результат (XP по стандартной шкале или свои критерии) — сразу в несколько миров.
//  Или новый квест в дорожную карту (день, Boss Battle).
//

import SwiftUI

struct AddResultView: View {
    @EnvironmentObject private var store: RPGStore
    @Environment(\.dismiss) private var dismiss
    var roadmapId: String? = nil

    @State private var title = ""
    @State private var tierId = ""
    @State private var xp: Double = 300
    @State private var customXP = "500"
    @State private var selected: Set<String> = []
    @State private var cats: [String: String] = [:]
    @State private var extraXP: [String: String] = [:]
    @State private var mainWorld = ""
    @State private var proofType = RPGData.proofTypes[0]
    @State private var proof = ""
    @State private var day = 1
    @State private var boss = false

    private var tiers: [XPTier] { (store.isKids || store.isSen) ? RPGData.kidsTiers : RPGData.xpTiers }
    private var isCustom: Bool { tierId == "custom" }
    private var currentTier: XPTier? { RPGData.tier(tierId) }
    private var roadmap: Roadmap? { roadmapId.flatMap { id in store.state.roadmaps.first { $0.id == id } } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(roadmapId == nil ? "Добавить реальный результат" : "Новый квест в карту").font(.title2.bold())
                    RPGField(title: roadmapId == nil ? "Что сделано" : "Что нужно сделать", text: $title, placeholder: "Например: Сертификат Google Data Analytics")

                    Text("Тип результата").font(.system(size: 13, weight: .semibold)).foregroundStyle(RPGTheme.muted)
                    Picker("Тип результата", selection: $tierId) {
                        ForEach(tiers) { t in Text("\(t.label) · +\(t.min)–\(t.max)").tag(t.id) }
                        Text("⚙️ Свои критерии (не входит в Verified)").tag("custom")
                    }
                    .pickerStyle(.menu)
                    .tint(RPGTheme.violet2)
                    .onChange(of: tierId) { _, _ in if let t = currentTier { xp = Double(t.def) } }

                    if isCustom {
                        RPGField(title: "XP (свой вес)", text: $customXP, keyboard: .numberPad)
                    } else if let t = currentTier {
                        HStack {
                            Text("XP").font(.system(size: 13, weight: .semibold)).foregroundStyle(RPGTheme.muted)
                            Spacer()
                            Text("+\(RPGFormat.xp(Int(xp)))").font(.system(size: 17, weight: .heavy)).foregroundStyle(RPGTheme.gold)
                        }
                        Slider(value: $xp, in: Double(t.min)...Double(t.max), step: t.max - t.min >= 1000 ? 50 : 10)
                            .tint(RPGTheme.gold)
                    }

                    Text("Какие миры прокачивает").font(.system(size: 13, weight: .semibold)).foregroundStyle(RPGTheme.muted).padding(.top, 4)
                    ForEach(store.state.worlds) { w in worldRow(w) }
                    Text("Основной мир получает XP со шкалы, остальные — сколько укажешь (по умолчанию половину).")
                        .font(.footnote).foregroundStyle(RPGTheme.muted)

                    if let rm = roadmap {
                        Stepper("День карты: \(day)", value: $day, in: 1...rm.days)
                        Toggle("🔥 Boss Battle", isOn: $boss).tint(RPGTheme.boss)
                    } else if !isCustom {
                        Text("Доказательство → Verified XP").font(.system(size: 13, weight: .semibold)).foregroundStyle(RPGTheme.muted)
                        Picker("Тип доказательства", selection: $proofType) {
                            ForEach(RPGData.proofTypes, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .tint(RPGTheme.violet2)
                        RPGField(title: "", text: $proof, placeholder: "Ссылка / номер сертификата", keyboard: .URL)
                    }

                    Button(roadmapId == nil ? "✓ Начислить XP" : "Добавить квест", action: save)
                        .buttonStyle(PrimaryButtonStyle(calm: store.calm))
                        .padding(.top, 8)
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(RPGTheme.bg2.ignoresSafeArea())
            .foregroundStyle(RPGTheme.text)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Закрыть") { dismiss() }.foregroundStyle(RPGTheme.violet2) }
            }
        }
        .presentationBackground(RPGTheme.bg2)
        .onAppear(perform: setup)
    }

    private func worldRow(_ w: World) -> some View {
        let on = selected.contains(w.id)
        return VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: Binding(get: { selected.contains(w.id) }, set: { v in if v { selected.insert(w.id) } else { selected.remove(w.id) } })) {
                Text("\(w.emoji) \(w.name)\(w.id == mainWorld ? " · основной" : "")").font(.system(size: 14, weight: .semibold))
            }
            .tint(RPGTheme.gold)
            if on {
                HStack(spacing: 8) {
                    Picker("Направление", selection: Binding(get: { cats[w.id] ?? w.type.categories[0] }, set: { cats[w.id] = $0 })) {
                        ForEach(w.type.categories, id: \.self) { c in Text("\(RPGData.category(c).emoji) \(RPGData.category(c).label)").tag(c) }
                    }
                    .pickerStyle(.menu)
                    .tint(RPGTheme.violet2)
                    Spacer()
                    if w.id != mainWorld {
                        TextField("XP", text: Binding(get: { extraXP[w.id] ?? "" }, set: { extraXP[w.id] = $0 }))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 10).fill(RPGTheme.bg))
                    }
                }
            }
        }
        .rpgCard(padding: 10, stroke: on ? RPGTheme.gold.opacity(0.5) : RPGTheme.line)
    }

    private func setup() {
        guard tierId.isEmpty else { return }
        tierId = tiers.first(where: { $0.id == "cert" })?.id ?? tiers.first?.id ?? "custom"
        xp = Double(currentTier?.def ?? 300)
        mainWorld = roadmap?.worldId ?? store.state.worlds.first?.id ?? ""
        if !mainWorld.isEmpty { selected = [mainWorld] }
        if let rm = roadmap { day = store.state.progress(of: rm).day }
    }

    private func save() {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { store.show(roadmapId == nil ? "Опиши результат" : "Опиши квест"); return }
        let baseXP = isCustom ? (Int(customXP) ?? 0) : Int(xp)
        guard baseXP > 0 else { store.show("Укажи XP"); return }
        var awards: [XPAward] = []
        let chosen = store.state.worlds.filter { selected.contains($0.id) }
        let ordered = chosen.filter { $0.id == mainWorld } + chosen.filter { $0.id != mainWorld }
        for w in ordered {
            let cat = cats[w.id] ?? w.type.categories[0]
            let value = w.id == mainWorld ? baseXP : (Int(extraXP[w.id] ?? "") ?? Int((Double(baseXP) * 0.5).rounded()))
            awards.append(XPAward(worldId: w.id, cat: cat, xp: value))
        }
        if awards.isEmpty, let w = store.state.world(mainWorld) {
            awards = [XPAward(worldId: w.id, cat: cats[w.id] ?? w.type.categories[0], xp: baseXP)]
        }
        let tier: String? = isCustom ? nil : tierId
        if let rm = roadmap {
            store.addQuest(Quest(title: t, tier: tier, custom: isCustom, awards: awards, boss: boss, roadmapId: rm.id, day: day, phase: "Мой квест"), to: rm.id)
        } else {
            let v = proof.trimmingCharacters(in: .whitespacesAndNewlines)
            let proofText = v.isEmpty ? "" : (v.hasPrefix(proofType) ? v : "\(proofType): \(v)")
            dismiss()
            store.addResult(title: t, tier: tier, custom: isCustom, awards: awards, proof: proofText)
            return
        }
        dismiss()
    }
}
