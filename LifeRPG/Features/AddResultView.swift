//
//  AddResultView.swift
//  LIFE RPG
//
//  Панель «Новый результат»: XP по стандартной шкале или свои критерии, сразу в несколько миров,
//  доказательство → Verified XP. Или новый квест в карту (день, Boss Battle).
//

import SwiftUI

struct AddResultView: View {
    @EnvironmentObject private var store: RPGStore
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
        OrnatePanel(title: roadmapId == nil ? "Новый результат" : "Новый квест", onClose: { store.panel = nil }) {
            GameField(title: roadmapId == nil ? "Что сделано" : "Что нужно сделать", text: $title, placeholder: "Например: Сертификат Google Data Analytics")

            SectionTitle(text: "Тип результата")
            VStack(spacing: 6) {
                ForEach(tiers) { t in tierRow(id: t.id, label: t.label, range: "+\(RPGFormat.xp(t.min))–\(RPGFormat.xp(t.max))") }
                tierRow(id: "custom", label: "⚙️ Свои критерии (не входят в Verified)", range: "свой вес")
            }

            if isCustom {
                GameField(title: "XP (свой вес)", text: $customXP, keyboard: .numberPad)
            } else if let t = currentTier {
                HStack {
                    Text("Награда").font(GameFont.body(13, .bold)).foregroundStyle(RPGTheme.muted)
                    Spacer()
                    GameLabel(text: "+\(RPGFormat.xp(Int(xp))) \(store.unit)", size: 22, color: RPGTheme.gold)
                }
                Slider(value: $xp, in: Double(t.min)...Double(t.max), step: t.max - t.min >= 1000 ? 50 : 10)
                    .tint(RPGTheme.gold)
            }

            SectionTitle(text: "Какие миры прокачивает")
            ForEach(store.state.worlds) { w in worldRow(w) }
            Text("Основной мир получает XP со шкалы, остальные — сколько укажешь (по умолчанию половину).")
                .font(GameFont.body(11.5, .medium)).foregroundStyle(RPGTheme.muted)

            if let rm = roadmap {
                InsetCard {
                    Stepper(value: $day, in: 1...rm.days) {
                        Text("День карты: \(day)").font(GameFont.body(15, .bold)).foregroundStyle(RPGTheme.cream)
                    }
                }
                GameToggle(title: "🔥 Boss Battle", icon: "flame.fill", isOn: $boss)
            } else if !isCustom {
                SectionTitle(text: "Доказательство → Verified XP")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(RPGData.proofTypes.filter { $0 != "Подтверждение родителя" }, id: \.self) { t in
                            Button { proofType = t } label: { StoneChip(text: t, selected: proofType == t) }.buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 3)
                }
                GameField(title: "", text: $proof, placeholder: "Ссылка / номер сертификата", keyboard: .URL)
            }

            Button(roadmapId == nil ? "✓ Начислить XP" : "Добавить квест", action: save)
                .buttonStyle(ChunkyButtonStyle(kind: store.calm ? .calm : .green, size: 21))
                .padding(.top, 4)
        }
        .onAppear(perform: setup)
    }

    private func tierRow(id: String, label: String, range: String) -> some View {
        Button {
            tierId = id
            if let t = RPGData.tier(id) { xp = Double(t.def) }
        } label: {
            HStack(spacing: 10) {
                CheckStone(on: tierId == id)
                Text(label).font(GameFont.body(13.5, .bold)).foregroundStyle(RPGTheme.cream).multilineTextAlignment(.leading)
                Spacer()
                Text(range).font(GameFont.display(11)).foregroundStyle(RPGTheme.gold)
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 12).fill(tierId == id ? Color(hex: "4A3878") : Color(hex: "1A1032")))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(tierId == id ? AnyShapeStyle(RPGTheme.goldGradient) : AnyShapeStyle(Color.black.opacity(0.5)), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    private func worldRow(_ w: World) -> some View {
        let on = selected.contains(w.id)
        return VStack(alignment: .leading, spacing: 8) {
            Button {
                if on { selected.remove(w.id) } else { selected.insert(w.id) }
            } label: {
                HStack(spacing: 10) {
                    CheckStone(on: on)
                    Text("\(w.emoji) \(w.name)").font(GameFont.body(14, .bold)).foregroundStyle(RPGTheme.cream)
                    if w.id == mainWorld { Text("основной").font(GameFont.display(9)).foregroundStyle(RPGTheme.gold) }
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            if on {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(w.type.categories, id: \.self) { c in
                            Button { cats[w.id] = c } label: {
                                StoneChip(text: "\(RPGData.category(c).emoji) \(RPGData.category(c).label)", selected: (cats[w.id] ?? w.type.categories[0]) == c)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 3)
                }
                if w.id != mainWorld {
                    GameField(title: "", text: Binding(get: { extraXP[w.id] ?? "" }, set: { extraXP[w.id] = $0 }), placeholder: "XP для этого мира (по умолчанию половина)", keyboard: .numberPad)
                }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "1A1032").opacity(0.85)))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(on ? RPGTheme.gold.opacity(0.6) : Color.black.opacity(0.5), lineWidth: 1.5))
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
        store.panel = nil
        if let rm = roadmap {
            store.addQuest(Quest(title: t, tier: tier, custom: isCustom, awards: awards, boss: boss, roadmapId: rm.id, day: day, phase: "Мой квест"), to: rm.id)
        } else {
            let v = proof.trimmingCharacters(in: .whitespacesAndNewlines)
            let proofText = v.isEmpty ? "" : (v.hasPrefix(proofType) ? v : "\(proofType): \(v)")
            store.addResult(title: t, tier: tier, custom: isCustom, awards: awards, proof: proofText)
        }
    }
}
