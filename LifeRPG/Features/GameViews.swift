//
//  GameViews.swift
//  LIFE RPG
//
//  Общие игровые экраны: герой в лобби, карточка квеста, строка навыка, достижения, LEVEL UP, новый маршрут.
//

import SwiftUI

/// Снежный барс-рыцарь на островке (слой фона лобби), с лёгким покачиванием.
struct HeroLayer: View {
    var calm = false
    @State private var bob = false

    var body: some View {
        GeometryReader { g in
            let w = g.size.width * 0.64
            let h = w / 0.857
            ZStack {
                Ellipse()
                    .fill(RadialGradient(colors: [RPGTheme.goldLight.opacity(0.35), .clear], center: .center, startRadius: 0, endRadius: w * 0.6))
                    .frame(width: w * 1.2, height: w * 0.9)
                    .position(x: g.size.width * 0.66, y: g.size.height * 0.622 - h * 0.45)
                    .opacity(calm ? 0.4 : (bob ? 0.9 : 0.5))
                Image("HeroLeopard")
                    .resizable()
                    .scaledToFit()
                    .frame(width: w, height: h)
                    .offset(y: bob ? -6 : 0)
                    .position(x: g.size.width * 0.70, y: g.size.height * 0.622 - h * 0.454)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            guard !calm else { return }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) { bob = true }
        }
    }
}

// MARK: - Карточка квеста

/// Квест-карточка: ✓ выполненные светятся, Boss — огненная рамка, закрытые — камень с замком.
struct QuestCard: View {
    @EnvironmentObject private var store: RPGStore
    let quest: Quest
    var big = false

    var body: some View {
        let s = store.state
        let main = quest.mainAward
        let cat = RPGData.category(main?.cat ?? "growth")
        let done = quest.isDone
        let locked = s.isLocked(quest)
        let failed = quest.status == .failed
        let pending = quest.status == .pending
        HStack(spacing: 12) {
            questMedallion(done: done, locked: locked, failed: failed, emoji: cat.emoji, cat: main?.cat ?? "growth")
            VStack(alignment: .leading, spacing: 5) {
                if quest.boss { BossRibbon() }
                Text(quest.title)
                    .font(GameFont.body(big ? 18 : 15, .bold))
                    .foregroundStyle(failed ? RPGTheme.muted : RPGTheme.cream)
                    .strikethrough(failed)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    Text("+\(RPGFormat.xp(main?.xp ?? 0)) \(store.unit)")
                        .font(GameFont.display(13))
                        .foregroundStyle(RPGTheme.gold)
                        .outlined(RPGTheme.edgeDark, 0.8)
                    if quest.awards.count > 1 { Text("🪐+\(quest.awards.count - 1)").font(GameFont.body(11, .heavy)).foregroundStyle(RPGTheme.violet2) }
                    if s.isVerified(quest) { Text("✓ VERIFIED").font(GameFont.display(10)).foregroundStyle(RPGTheme.ok) }
                    if pending { Text("⏳ ждёт родителя").font(GameFont.body(11, .bold)).foregroundStyle(RPGTheme.gold) }
                    if quest.branch != nil { Text("🔄").font(.system(size: 12)) }
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .black)).foregroundStyle(RPGTheme.muted.opacity(0.7))
        }
        .padding(big ? 14 : 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: done ? [Color(hex: "1E5A44"), Color(hex: "1A1032")] : (quest.boss ? [Color(hex: "6A2218"), Color(hex: "241848")] : [Color(hex: "3A2A6A"), Color(hex: "1E1440")]),
                                     startPoint: .top, endPoint: .bottom))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(quest.boss ? AnyShapeStyle(RPGTheme.bossGradient) : (done ? AnyShapeStyle(RPGTheme.ok.opacity(0.7)) : AnyShapeStyle(RPGTheme.goldGradient)), lineWidth: 2)
        )
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.black.opacity(0.45), lineWidth: 1).padding(2))
        .shadow(color: done ? RPGTheme.ok.opacity(0.25) : .black.opacity(0.4), radius: done ? 10 : 5, y: 3)
        .opacity(locked ? 0.6 : (failed ? 0.55 : 1))
        .contentShape(Rectangle())
    }
}

extension QuestCard {
    @ViewBuilder
    func questMedallion(done: Bool, locked: Bool, failed: Bool, emoji: String, cat: String) -> some View {
        let size: CGFloat = big ? 58 : 50
        if done {
            Medallion(icon: "checkmark", size: size, gem: Color(hex: "1F8A4A"))
        } else if locked {
            Medallion(icon: "lock.fill", size: size, gem: Color(hex: "3A3450"))
        } else if failed {
            Medallion(icon: "xmark", size: size, gem: Color(hex: "5A1A1A"))
        } else if quest.boss {
            Medallion(icon: "flame.fill", size: size, gem: RPGTheme.boss, glow: true)
        } else {
            Medallion(icon: emoji, size: size, gem: RPGTheme.category(cat), emoji: true)
        }
    }
}

struct BossRibbon: View {
    var body: some View {
        Text("🔥 BOSS BATTLE")
            .font(GameFont.display(10))
            .foregroundStyle(.white)
            .outlined(Color(hex: "7E1C12"), 0.8)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Capsule().fill(RPGTheme.bossGradient))
            .overlay(Capsule().strokeBorder(RPGTheme.goldGradient, lineWidth: 1))
    }
}

// MARK: - Навык

/// Строка направления: медальон, название, шкала, щит ранга направления.
struct SkillRow: View {
    let cat: String
    let xp: Int
    var weak = false

    var body: some View {
        let c = RPGData.category(cat)
        let r = RPGEngine.rank(for: xp, scale: .category)
        HStack(spacing: 10) {
            Medallion(icon: c.emoji, size: 42, gem: RPGTheme.category(cat), emoji: true)
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(c.label).font(GameFont.body(14, .bold)).foregroundStyle(RPGTheme.cream).lineLimit(1)
                    Spacer()
                    Text(RPGFormat.xp(xp)).font(GameFont.display(13)).foregroundStyle(RPGTheme.gold).outlined(RPGTheme.edgeDark, 0.8)
                }
                GameBar(progress: r.progress, height: 12,
                        fill: LinearGradient(colors: [RPGTheme.category(cat).opacity(0.75), RPGTheme.category(cat)], startPoint: .top, endPoint: .bottom))
            }
            RankShield(id: r.rank.id, size: 30)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "1A1032").opacity(0.85)))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(weak ? AnyShapeStyle(RPGTheme.bad) : AnyShapeStyle(Color.black.opacity(0.5)), lineWidth: weak ? 2 : 1.5))
    }
}

// MARK: - Достижения

struct AchievementGrid: View {
    let items: [Achievement]
    var body: some View {
        if items.isEmpty {
            Text("Выполни первый квест — и здесь появятся награды").font(GameFont.body(13)).foregroundStyle(RPGTheme.muted)
        } else {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 12) {
                ForEach(items) { a in
                    VStack(spacing: 5) {
                        ZStack {
                            Circle().fill(RPGTheme.goldRing)
                            Circle().fill(RadialGradient(colors: [Color(hex: "7A45E8"), Color(hex: "1E1238")], center: .init(x: 0.4, y: 0.3), startRadius: 1, endRadius: 34)).padding(4)
                            Text(a.icon).font(.system(size: 26))
                        }
                        .frame(width: 60, height: 60)
                        .shadow(color: RPGTheme.gold.opacity(0.35), radius: 6)
                        Text(a.title)
                            .font(GameFont.body(10, .bold))
                            .foregroundStyle(RPGTheme.cream)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .frame(height: 38, alignment: .top)
                    }
                }
            }
        }
    }
}

// MARK: - LEVEL UP

struct LevelUpView: View {
    let event: LevelUpEvent
    let calm: Bool
    let unit: String
    let onClose: () -> Void
    @State private var spin = false
    @State private var pop = false

    var body: some View {
        let u = event.ups[0]
        let to = RPGData.ranks(u.scale).first { $0.id == u.to }
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea().onTapGesture(perform: onClose)
            if !calm {
                ZStack {
                    ForEach(0..<12, id: \.self) { i in
                        Rectangle()
                            .fill(LinearGradient(colors: [RPGTheme.goldLight.opacity(0.5), .clear], startPoint: .bottom, endPoint: .top))
                            .frame(width: 26, height: 420)
                            .offset(y: -210)
                            .rotationEffect(.degrees(Double(i) * 30))
                    }
                }
                .rotationEffect(.degrees(spin ? 360 : 0))
                .allowsHitTesting(false)
            }
            VStack(spacing: 14) {
                Text("🏆").font(.system(size: 70)).scaleEffect(pop || calm ? 1 : 0.2).shadow(color: RPGTheme.gold, radius: 20)
                Text("LEVEL UP!")
                    .font(GameFont.display(44))
                    .foregroundStyle(LinearGradient(colors: [Color(hex: "FFF6D6"), RPGTheme.gold, Color(hex: "F3A92E")], startPoint: .top, endPoint: .bottom))
                    .outlined(Color(hex: "5A2E00"), 2)
                OrnatePanel {
                    VStack(spacing: 12) {
                        Text(u.who).font(GameFont.title(18)).foregroundStyle(RPGTheme.muted)
                        HStack(spacing: 18) {
                            RankShield(id: u.from, size: 48)
                            Image(systemName: "arrowtriangle.right.fill").font(.system(size: 26)).foregroundStyle(RPGTheme.gold).shadow(color: .black, radius: 0, y: 2)
                            RankShield(id: u.to, size: 80).scaleEffect(pop || calm ? 1 : 0.4)
                        }
                        if let to { GameLabel(text: to.name, size: 20, color: RPGTheme.rankAccent(to.id)) }
                        if event.xp > 0 { GameLabel(text: "+\(RPGFormat.xp(event.xp)) \(unit)", size: 26, color: RPGTheme.gold) }
                        ForEach(event.ups.dropFirst()) { x in
                            Text("\(x.who): \(x.from) → \(x.to)").font(GameFont.body(13)).foregroundStyle(RPGTheme.muted)
                        }
                        ForEach(event.achievements) { a in
                            InsetCard(stroke: RPGTheme.gold.opacity(0.6)) {
                                Text("\(a.icon)  Achievement unlocked: \(a.title)").font(GameFont.body(14, .bold)).foregroundStyle(RPGTheme.cream)
                            }
                        }
                        Button("Продолжить", action: onClose).buttonStyle(ChunkyButtonStyle(kind: calm ? .calm : .gold))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(24)
        }
        .onAppear {
            if calm { return }
            Haptics.success()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) { pop = true }
            withAnimation(.linear(duration: 14).repeatForever(autoreverses: false)) { spin = true }
        }
    }
}

// MARK: - Новый маршрут

struct RerouteView: View {
    @EnvironmentObject private var store: RPGStore
    let event: RerouteEvent
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea().onTapGesture(perform: onClose)
            OrnatePanel(title: "Новый маршрут", onClose: onClose) {
                VStack(alignment: .center, spacing: 6) {
                    GameLabel(text: "❌ Quest failed", size: 20, color: RPGTheme.bad)
                    Text("🔄 New route unlocked: \(event.result.route)").font(GameFont.body(16, .bold)).foregroundStyle(RPGTheme.cream).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                ForEach(event.result.created) { q in
                    InsetCard(stroke: q.boss ? RPGTheme.boss : Color.black.opacity(0.5)) {
                        HStack(alignment: .top) {
                            Text("\(q.boss ? "🔥" : "⚔️") \(q.title)").font(GameFont.body(14, .bold)).foregroundStyle(RPGTheme.cream)
                            Spacer()
                            Text("+\(RPGFormat.xp(q.mainAward?.xp ?? 0))").font(GameFont.display(13)).foregroundStyle(RPGTheme.gold)
                        }
                    }
                }
                Text("Реальная жизнь не идёт строго по плану — игра перестроила карту.")
                    .font(GameFont.body(13, .medium)).foregroundStyle(RPGTheme.muted).multilineTextAlignment(.center).frame(maxWidth: .infinity)
                Button("Вперёд!", action: onClose).buttonStyle(ChunkyButtonStyle(kind: .green))
            }
            .padding(20)
        }
    }
}
