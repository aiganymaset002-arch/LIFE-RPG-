//
//  MapView.swift
//  LIFE RPG
//
//  Центральный экран: интерактивная карта-таймлайн. DAY 37 / 90, XP мира, ранг, текущий квест,
//  Точка А → недели с квест-карточками → Точка Б.
//

import SwiftUI

struct MapView: View {
    @EnvironmentObject private var store: RPGStore
    @Binding var tab: RPGTab
    @State private var selectedId: String?
    @State private var openQuest: QuestRef?
    @State private var addToMap = false
    @State private var confirmDelete = false

    private var roadmap: Roadmap? {
        let rms = store.state.roadmaps
        return rms.first { $0.id == selectedId } ?? rms.last
    }

    var body: some View {
        RPGScreen(title: "Карта") {
            if let rm = roadmap {
                content(rm)
            } else {
                VStack(spacing: 16) {
                    Text("🗺").font(.system(size: 54))
                    Text("У тебя ещё нет дорожной карты.").foregroundStyle(RPGTheme.muted)
                    Button("✨ Создать с AI Game Master") { tab = .gm }.buttonStyle(PrimaryButtonStyle())
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            }
        }
        .sheet(item: $openQuest) { ref in QuestDetailView(questId: ref.id) }
        .sheet(isPresented: $addToMap) {
            if let rm = roadmap { AddResultView(roadmapId: rm.id) }
        }
    }

    @ViewBuilder
    private func content(_ rm: Roadmap) -> some View {
        let s = store.state
        let pr = s.progress(of: rm)
        let w = s.world(rm.worldId)
        let wx = s.worldXP(rm.worldId)
        let wr = RPGEngine.rank(for: wx, scale: w?.type.scale ?? .person)
        let cur = s.currentQuest(rm)

        if s.roadmaps.count > 1 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(s.roadmaps) { r in
                        Button { selectedId = r.id } label: {
                            Chip(text: r.title.count > 28 ? String(r.title.prefix(27)) + "…" : r.title, selected: r.id == rm.id)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }

        VStack(alignment: .leading, spacing: 8) {
            Text(rm.title).font(.system(size: 16, weight: .heavy))
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("DAY \(pr.day)").legendTitle(26)
                Text("/ \(rm.days)").foregroundStyle(RPGTheme.muted)
                Spacer()
                Text("\(Int((pr.timePct * 100).rounded()))%").font(.system(size: 16, weight: .heavy)).foregroundStyle(RPGTheme.gold)
            }
            XPBar(progress: pr.timePct)
            HStack(spacing: 8) {
                statBox(w?.type == .company ? "Company XP" : "\(w?.name ?? "") XP", RPGFormat.xp(wx))
                statBox("Rank", "\(wr.rank.id) — \(wr.rank.name)")
                statBox(wr.next.map { "до Rank \($0.id)" } ?? "Rank", wr.next == nil ? "MAX" : "\(RPGFormat.xp(wr.toNext)) XP")
            }
            Text("Квесты: \(pr.done) / \(pr.total)").font(.system(size: 12.5)).foregroundStyle(RPGTheme.muted).padding(.top, 2)
            XPBar(progress: pr.pct, height: 6, style: AnyShapeStyle(RPGTheme.violetGradient))
        }
        .rpgCard(padding: 16, fill: AnyShapeStyle(LinearGradient(colors: [Color(hex: "241C5C"), RPGTheme.card], startPoint: .top, endPoint: .bottom)))
        .padding(.top, 8)

        if let cur {
            Button { openQuest = QuestRef(id: cur.id) } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("▶ ТЕКУЩИЙ КВЕСТ · день \(cur.day.map { String($0) } ?? "—")")
                        .font(.system(size: 11, weight: .heavy)).tracking(1).foregroundStyle(RPGTheme.gold)
                    Text(cur.title).font(.system(size: 16, weight: .bold)).multilineTextAlignment(.leading)
                    Text("+\(RPGFormat.xp(cur.mainAward?.xp ?? 0)) \(store.unit)").font(.system(size: 14, weight: .heavy)).foregroundStyle(RPGTheme.gold)
                }
                .rpgCard(padding: 14, stroke: RPGTheme.gold, fill: AnyShapeStyle(LinearGradient(colors: [RPGTheme.gold.opacity(0.18), RPGTheme.card], startPoint: .topLeading, endPoint: .bottomTrailing)))
                .shadow(color: RPGTheme.gold.opacity(0.18), radius: 12)
            }
            .buttonStyle(.plain)
        } else {
            Text("🏁 Все квесты пройдены!").font(.headline).frame(maxWidth: .infinity)
                .rpgCard(stroke: RPGTheme.ok, fill: AnyShapeStyle(RPGTheme.ok.opacity(0.12)))
        }

        if let a = rm.pointA {
            VStack(alignment: .leading, spacing: 4) {
                Text("ТОЧКА А · День 1").font(.system(size: 13, weight: .bold))
                Text(a).font(.system(size: 13)).foregroundStyle(RPGTheme.muted)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(RPGTheme.violet, style: StrokeStyle(lineWidth: 1, dash: [5])))
        }

        timeline(rm, progress: pr)

        Text("← листай карту → · нажми на карточку, чтобы выполнить квест")
            .font(.footnote).foregroundStyle(RPGTheme.muted).frame(maxWidth: .infinity)
        Button("＋ Добавить свой квест в карту") { addToMap = true }.buttonStyle(SecondaryButtonStyle())
        Button("Удалить карту", role: .destructive) { confirmDelete = true }
            .font(.system(size: 14, weight: .semibold)).foregroundStyle(RPGTheme.bad).frame(maxWidth: .infinity).padding(.top, 4)
            .confirmationDialog("Удалить карту и её невыполненные квесты? Выполненные результаты и XP останутся.", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Удалить", role: .destructive) { store.deleteRoadmap(rm.id); selectedId = nil }
            }
    }

    private func statBox(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.system(size: 11)).foregroundStyle(RPGTheme.muted).lineLimit(1)
            Text(value).font(.system(size: 13.5, weight: .bold)).lineLimit(1).minimumScaleFactor(0.7)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.25)))
    }

    private struct Segment: Identifiable {
        let id: Int
        let from: Int
        let to: Int
        var quests: [Quest]
    }

    private func timeline(_ rm: Roadmap, progress pr: RoadmapProgress) -> some View {
        let segLen = rm.days <= 120 ? 7 : 30
        let count = Swift.max(1, Int(ceil(Double(rm.days) / Double(segLen))))
        var segs = (0..<count).map { i in Segment(id: i, from: i * segLen + 1, to: Swift.min(rm.days, (i + 1) * segLen), quests: []) }
        for q in store.state.roadmapQuests(rm) {
            let i = Swift.min(count - 1, Swift.max(0, ((q.day ?? 1) - 1) / segLen))
            segs[i].quests.append(q)
        }
        let current = Swift.min(count - 1, (pr.day - 1) / segLen)
        let finalSegs = segs
        return ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(finalSegs) { seg in
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(alignment: .firstTextBaseline) {
                                Text("\(segLen == 7 ? "Неделя" : "Месяц") \(seg.id + 1)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(seg.id == current ? RPGTheme.gold : RPGTheme.text)
                                Spacer()
                                Text("Дни \(seg.from)–\(seg.to)").font(.system(size: 11)).foregroundStyle(RPGTheme.muted)
                            }
                            dot(past: seg.id < current, now: seg.id == current)
                            VStack(spacing: 8) {
                                if seg.quests.isEmpty {
                                    Text("—").foregroundStyle(RPGTheme.muted).frame(maxWidth: .infinity).padding(.vertical, 20)
                                }
                                ForEach(seg.quests) { q in
                                    Button { openQuest = QuestRef(id: q.id) } label: { QuestCard(quest: q, compact: true, rmDay: pr.day) }
                                        .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(width: 210)
                        .id(seg.id)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("ТОЧКА Б").font(.system(size: 13, weight: .bold))
                            Spacer()
                            Text("День \(rm.days)").font(.system(size: 11)).foregroundStyle(RPGTheme.muted)
                        }
                        dot(past: false, now: false)
                        VStack(alignment: .leading, spacing: 4) {
                            if let b = rm.pointB {
                                ForEach(b, id: \.self) { Text("✓ \($0)").font(.system(size: 13)) }
                            } else {
                                Text("🏆 \(rm.dream.isEmpty ? rm.title : rm.dream)").font(.system(size: 13))
                            }
                        }
                        .rpgCard(padding: 12, stroke: RPGTheme.gold, fill: AnyShapeStyle(LinearGradient(colors: [RPGTheme.gold.opacity(0.15), RPGTheme.card], startPoint: .topLeading, endPoint: .bottomTrailing)))
                    }
                    .frame(width: 230)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
            .padding(.horizontal, -16)
            .onAppear { proxy.scrollTo(current, anchor: .leading) }
            .onChange(of: rm.id) { _, _ in proxy.scrollTo(current, anchor: .leading) }
        }
        .padding(.top, 8)
    }

    private func dot(past: Bool, now: Bool) -> some View {
        ZStack(alignment: .leading) {
            Rectangle().fill(past ? RPGTheme.ok : RPGTheme.line).frame(height: 2).padding(.leading, -10)
            Circle()
                .fill(now ? RPGTheme.gold : (past ? RPGTheme.ok : RPGTheme.card2))
                .frame(width: 14, height: 14)
                .overlay(Circle().stroke(now ? Color(hex: "FFF3C4") : (past ? RPGTheme.ok : RPGTheme.line), lineWidth: 2))
                .shadow(color: now ? RPGTheme.gold.opacity(0.6) : .clear, radius: 6)
                .padding(.leading, 8)
        }
        .frame(height: 24)
    }
}
