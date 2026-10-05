//
//  MapView.swift
//  LIFE RPG
//
//  Карта приключения: извилистая тропа снизу вверх (Точка А → Точка Б), узлы-квесты как уровни,
//  ✓ пройденные — золотые, текущий светится, впереди — камень, Boss — огненный. Сверху DAY 37 / 90.
//

import SwiftUI

struct MapView: View {
    @EnvironmentObject private var store: RPGStore
    @Binding var tab: RPGTab
    @State private var selectedId: String?
    @State private var confirmDelete = false
    @State private var pulse = false

    private var roadmap: Roadmap? {
        let rms = store.state.roadmaps
        return rms.first { $0.id == selectedId } ?? rms.last
    }

    var body: some View {
        if let rm = roadmap {
            content(rm)
        } else {
            VStack(spacing: 18) {
                Spacer()
                OrnatePanel(title: "Карта") {
                    VStack(spacing: 14) {
                        Text("🗺").font(.system(size: 60))
                        Text("У тебя ещё нет дорожной карты. Расскажи Оракулу свою мечту — он построит игру.")
                            .font(GameFont.body(15, .medium)).foregroundStyle(RPGTheme.cream).multilineTextAlignment(.center)
                        Button("✨ К Оракулу") { tab = .gm }.buttonStyle(ChunkyButtonStyle(kind: .purple))
                    }
                    .frame(maxWidth: .infinity)
                }
                Spacer()
            }
            .padding(20)
        }
    }

    private func content(_ rm: Roadmap) -> some View {
        let s = store.state
        let pr = s.progress(of: rm)
        let w = s.world(rm.worldId)
        let wx = s.worldXP(rm.worldId)
        let wr = RPGEngine.rank(for: wx, scale: w?.type.scale ?? .person)
        let quests = s.roadmapQuests(rm)
        let current = s.currentQuest(rm)
        return VStack(spacing: 0) {
            // Шапка карты
            VStack(spacing: 8) {
                if s.roadmaps.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(s.roadmaps) { r in
                                Button { selectedId = r.id } label: {
                                    StoneChip(text: r.title.count > 26 ? String(r.title.prefix(25)) + "…" : r.title, selected: r.id == rm.id)
                                }
                            }
                        }
                    }
                }
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(rm.title).font(GameFont.title(15)).foregroundStyle(RPGTheme.cream).lineLimit(1)
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            GameLabel(text: "DAY \(pr.day)", size: 28, color: RPGTheme.gold)
                            Text("/ \(rm.days)").font(GameFont.display(15)).foregroundStyle(RPGTheme.muted)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(w?.type == .company ? "COMPANY" : (w?.name ?? "").uppercased()).font(GameFont.display(10)).foregroundStyle(RPGTheme.muted).lineLimit(1)
                            RankShield(id: wr.rank.id, size: 26)
                        }
                        Text("\(RPGFormat.xp(wx)) XP · \(wr.rank.name)").font(GameFont.display(12)).foregroundStyle(RPGTheme.cream).outlined(RPGTheme.edgeDark, 0.7)
                        Text(wr.next.map { "\(RPGFormat.xp(wr.toNext)) XP до Rank \($0.id)" } ?? "MAX").font(GameFont.body(11, .bold)).foregroundStyle(RPGTheme.gold)
                    }
                }
                GameBar(progress: pr.timePct, height: 16, label: "\(Int((pr.timePct * 100).rounded()))%  ·  квесты \(pr.done)/\(pr.total)")
            }
            .padding(14)
            .background(PanelBackground(radius: 20))
            .padding(.horizontal, 12)
            .padding(.top, 8)

            // Тропа
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    TrailView(roadmap: rm, quests: quests, currentId: current?.id, today: pr.day, pulse: pulse)
                        .padding(.vertical, 20)
                    HStack(spacing: 10) {
                        Button("＋ Свой квест") { store.open(.add(rm.id)) }.buttonStyle(ChunkyButtonStyle(kind: .purple, size: 15))
                        Button("Удалить карту") { confirmDelete = true }.buttonStyle(ChunkyButtonStyle(kind: .stone, size: 15))
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                    .id("bottom")
                }
                .onAppear { scroll(proxy, to: current?.id) }
                .onChange(of: rm.id) { _, _ in scroll(proxy, to: store.state.currentQuest(rm)?.id) }
            }
        }
        .confirmationDialog("Удалить карту и её невыполненные квесты? Выполненные результаты и XP останутся.", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Удалить", role: .destructive) { store.deleteRoadmap(rm.id); selectedId = nil }
        }
        .onAppear {
            guard !store.calm else { return }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { pulse = true }
        }
    }

    private func scroll(_ proxy: ScrollViewProxy, to id: String?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            if let id { proxy.scrollTo(id, anchor: .center) } else { proxy.scrollTo("bottom", anchor: .bottom) }
        }
    }
}

/// Извилистая тропа: снизу Точка А, сверху замок Точки Б.
struct TrailView: View {
    @EnvironmentObject private var store: RPGStore
    let roadmap: Roadmap
    let quests: [Quest]
    let currentId: String?
    let today: Int
    let pulse: Bool

    private let step: CGFloat = 118
    private let top: CGFloat = 230
    private let bottomPad: CGFloat = 170

    var body: some View {
        GeometryReader { g in
            let width = g.size.width
            let pts = points(width: width)
            ZStack {
                // дорожка
                Path { p in
                    guard let first = pts.first else { return }
                    p.move(to: first)
                    for i in 1..<Swift.max(1, pts.count) {
                        let a = pts[i - 1], b = pts[i]
                        p.addCurve(to: b, control1: CGPoint(x: a.x, y: (a.y + b.y) / 2), control2: CGPoint(x: b.x, y: (a.y + b.y) / 2))
                    }
                }
                .stroke(Color(hex: "1A0E33").opacity(0.8), style: StrokeStyle(lineWidth: 26, lineCap: .round))
                Path { p in
                    guard let first = pts.first else { return }
                    p.move(to: first)
                    for i in 1..<Swift.max(1, pts.count) {
                        let a = pts[i - 1], b = pts[i]
                        p.addCurve(to: b, control1: CGPoint(x: a.x, y: (a.y + b.y) / 2), control2: CGPoint(x: b.x, y: (a.y + b.y) / 2))
                    }
                }
                .stroke(LinearGradient(colors: [Color(hex: "C9A86A"), Color(hex: "8A6A3A")], startPoint: .top, endPoint: .bottom), style: StrokeStyle(lineWidth: 16, lineCap: .round))
                Path { p in
                    guard let first = pts.first else { return }
                    p.move(to: first)
                    for i in 1..<Swift.max(1, pts.count) {
                        let a = pts[i - 1], b = pts[i]
                        p.addCurve(to: b, control1: CGPoint(x: a.x, y: (a.y + b.y) / 2), control2: CGPoint(x: b.x, y: (a.y + b.y) / 2))
                    }
                }
                .stroke(Color(hex: "FFF0C0").opacity(0.7), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 12]))

                // Точка Б — замок
                VStack(spacing: 6) {
                    Text("🏰").font(.system(size: 64)).shadow(color: RPGTheme.goldLight.opacity(0.8), radius: 16)
                    VStack(spacing: 3) {
                        GameLabel(text: "Точка Б · день \(roadmap.days)", size: 13, color: RPGTheme.gold)
                        if let b = roadmap.pointB {
                            Text(b.prefix(4).joined(separator: " · ")).font(GameFont.body(11, .bold)).foregroundStyle(RPGTheme.cream).multilineTextAlignment(.center).lineLimit(3)
                        } else {
                            Text(roadmap.dream.isEmpty ? roadmap.title : roadmap.dream).font(GameFont.body(11, .bold)).foregroundStyle(RPGTheme.cream).multilineTextAlignment(.center).lineLimit(3)
                        }
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "1A1032").opacity(0.9)))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(RPGTheme.goldGradient, lineWidth: 1.5))
                    .frame(maxWidth: 260)
                }
                .position(x: width / 2, y: 110)

                // Неделя-указатели
                ForEach(Array(quests.enumerated()), id: \.element.id) { i, q in
                    if let label = weekLabel(i) {
                        Text(label)
                            .font(GameFont.display(10))
                            .foregroundStyle(RPGTheme.cream)
                            .outlined(RPGTheme.edgeDark, 0.8)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Capsule().fill(LinearGradient(colors: [Color(hex: "8A5A2A"), Color(hex: "5A3A1A")], startPoint: .top, endPoint: .bottom)))
                            .overlay(Capsule().strokeBorder(RPGTheme.goldGradient, lineWidth: 1))
                            .position(x: pts[i].x < width / 2 ? width - 56 : 56, y: pts[i].y + 4)
                    }
                }

                // Узлы
                ForEach(Array(quests.enumerated()), id: \.element.id) { i, q in
                    Button { store.open(.quest(q.id)) } label: {
                        TrailNode(quest: q, isCurrent: q.id == currentId, locked: store.state.isLocked(q), pulse: pulse)
                    }
                    .buttonStyle(.plain)
                    .position(pts[i])
                }

                // Точка А
                VStack(spacing: 4) {
                    Text("🚩").font(.system(size: 34))
                    GameLabel(text: "Точка А · старт", size: 12, color: RPGTheme.gold)
                    if let a = roadmap.pointA {
                        Text(a).font(GameFont.body(11, .medium)).foregroundStyle(RPGTheme.muted).multilineTextAlignment(.center).lineLimit(3).frame(maxWidth: 260)
                    }
                }
                .position(x: width / 2, y: height - 70)
            }
        }
        .frame(height: height)
        .overlay(alignment: .top) { anchors }
    }

    /// Невидимые якоря на высоте каждого узла — для прокрутки к текущему квесту.
    private var anchors: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: top + step / 2)
            ForEach(quests.reversed()) { q in
                Color.clear.frame(height: step).id(q.id)
            }
        }
        .allowsHitTesting(false)
    }

    private var height: CGFloat { top + CGFloat(Swift.max(1, quests.count)) * step + bottomPad }

    /// Точки узлов: первый квест внизу, последний вверху; змейка.
    private func points(width: CGFloat) -> [CGPoint] {
        let amp = width * 0.27
        return quests.indices.map { i in
            let y = height - bottomPad - CGFloat(i) * step
            let x = width / 2 + amp * CGFloat(sin(Double(i) * 1.15))
            return CGPoint(x: x, y: y)
        }
    }

    private func weekLabel(_ i: Int) -> String? {
        let seg = roadmap.days <= 120 ? 7 : 30
        let d = (quests[i].day ?? 1) - 1
        let cur = d / seg
        let prev = i == 0 ? -1 : ((quests[i - 1].day ?? 1) - 1) / seg
        guard cur != prev else { return nil }
        return seg == 7 ? "НЕДЕЛЯ \(cur + 1)" : "МЕСЯЦ \(cur + 1)"
    }
}

/// Узел-уровень на тропе.
struct TrailNode: View {
    @EnvironmentObject private var store: RPGStore
    let quest: Quest
    let isCurrent: Bool
    let locked: Bool
    let pulse: Bool

    var body: some View {
        let done = quest.isDone
        let failed = quest.status == .failed
        let size: CGFloat = quest.boss ? 84 : 66
        VStack(spacing: 4) {
            ZStack {
                if isCurrent {
                    Circle().fill(RPGTheme.cyan.opacity(0.35)).frame(width: size + 34, height: size + 34)
                        .scaleEffect(pulse ? 1.12 : 0.9).opacity(pulse ? 0.25 : 0.7)
                }
                Circle().fill(Color.black.opacity(0.45)).frame(width: size, height: size).offset(y: 5)
                Circle()
                    .fill(nodeFill(done: done, failed: failed))
                    .frame(width: size, height: size)
                Circle().fill(LinearGradient(colors: [.white.opacity(0.5), .clear], startPoint: .top, endPoint: .center)).frame(width: size - 10, height: size - 10)
                Circle().strokeBorder(quest.boss ? AnyShapeStyle(RPGTheme.bossGradient) : AnyShapeStyle(RPGTheme.goldGradient), lineWidth: quest.boss ? 5 : 4).frame(width: size, height: size)
                nodeIcon(done: done, failed: failed)
                if done {
                    HStack(spacing: 1) {
                        ForEach(0..<3, id: \.self) { _ in Image(systemName: "star.fill").font(.system(size: 11)).foregroundStyle(RPGTheme.gold).shadow(color: .black, radius: 0, y: 1) }
                    }
                    .offset(y: -size / 2 - 6)
                }
                if isCurrent {
                    Image("AvatarLeopard").resizable().scaledToFit().frame(width: 46, height: 46)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(RPGTheme.goldGradient, lineWidth: 2))
                        .offset(x: size / 2 + 8, y: -size / 2)
                        .shadow(radius: 3)
                }
            }
            if quest.boss { BossRibbon() }
            Text(quest.title)
                .font(GameFont.body(11, .heavy))
                .foregroundStyle(RPGTheme.cream)
                .outlined(RPGTheme.edgeDark, 0.9)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 150)
        }
        .opacity(locked && !done ? 0.75 : 1)
    }

    private func nodeFill(done: Bool, failed: Bool) -> RadialGradient {
        let colors: [Color]
        if done { colors = [Color(hex: "FFE48A"), Color(hex: "E09A20")] }
        else if failed { colors = [Color(hex: "8A3A3A"), Color(hex: "3A1414")] }
        else if quest.boss { colors = [Color(hex: "FF8A5A"), Color(hex: "9A1E10")] }
        else if isCurrent { colors = [Color(hex: "9FF4FF"), Color(hex: "1F7BE0")] }
        else if locked { colors = [Color(hex: "6A6480"), Color(hex: "2E2A40")] }
        else { colors = [Color(hex: "B08CFF"), Color(hex: "4A2A9A")] }
        return RadialGradient(colors: colors, center: .init(x: 0.4, y: 0.3), startRadius: 2, endRadius: 50)
    }

    @ViewBuilder
    private func nodeIcon(done: Bool, failed: Bool) -> some View {
        if done {
            Image(systemName: "checkmark").font(.system(size: 28, weight: .black)).foregroundStyle(.white).shadow(color: Color(hex: "7A4A00"), radius: 0, y: 2)
        } else if failed {
            Image(systemName: "xmark").font(.system(size: 26, weight: .black)).foregroundStyle(.white.opacity(0.8))
        } else if locked {
            Image(systemName: "lock.fill").font(.system(size: 22, weight: .black)).foregroundStyle(.white.opacity(0.85))
        } else if quest.boss {
            Text("🔥").font(.system(size: 36))
        } else {
            Text(quest.day.map { "\($0)" } ?? "•")
                .font(GameFont.display(22))
                .foregroundStyle(.white)
                .outlined(Color(hex: "1A0E50"), 1.4)
        }
    }
}
