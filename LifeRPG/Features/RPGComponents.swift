//
//  RPGComponents.swift
//  LIFE RPG
//
//  Общие элементы: бейджи рангов, шкалы XP, карточки квестов, Level Up, тосты, новый маршрут.
//

import SwiftUI

struct RankBadge: View {
    let id: String
    var size: CGFloat = 30

    var body: some View {
        Text(id)
            .font(.system(size: size * (id.count > 1 ? 0.36 : 0.48), weight: .heavy, design: .serif))
            .foregroundStyle(RPGTheme.rankText(id))
            .frame(minWidth: size, minHeight: size)
            .padding(.horizontal, id.count > 1 ? 4 : 0)
            .background(RoundedRectangle(cornerRadius: size * 0.3, style: .continuous).fill(RPGTheme.rankGradient(id)))
            .overlay(RoundedRectangle(cornerRadius: size * 0.3, style: .continuous).stroke(.white.opacity(0.25), lineWidth: 1))
            .shadow(color: ["A", "S", "SS", "SSS"].contains(id) ? RPGTheme.gold.opacity(0.45) : .clear, radius: 6)
            .accessibilityLabel("Ранг \(id)")
    }
}

struct XPBar: View {
    let progress: Double
    var height: CGFloat = 10
    var style: AnyShapeStyle = AnyShapeStyle(RPGTheme.barGradient)

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.08))
                Capsule().fill(style)
                    .frame(width: Swift.max(height, geo.size.width * Swift.min(1, Swift.max(0, progress))))
                    .opacity(progress <= 0 ? 0.35 : 1)
            }
        }
        .frame(height: height)
        .animation(.easeOut(duration: 0.6), value: progress)
    }
}

struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .bold))
                .tracking(1)
                .foregroundStyle(RPGTheme.gold)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(RPGTheme.violet2)
            }
        }
        .padding(.top, 18)
        .padding(.bottom, 4)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var calm = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(Color(hex: calm ? "0D1A16" : "1B1300"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(calm ? AnyShapeStyle(RPGTheme.calm) : AnyShapeStyle(RPGTheme.goldGradient))
            )
            .shadow(color: calm ? .clear : RPGTheme.gold.opacity(0.25), radius: 10, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var tint: Color = RPGTheme.text
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(RPGTheme.card2))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(RPGTheme.line, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct Chip: View {
    let text: String
    var selected = false
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(selected ? RPGTheme.gold : RPGTheme.text)
            .background(Capsule().fill(RPGTheme.card))
            .overlay(Capsule().stroke(selected ? RPGTheme.gold : RPGTheme.line, lineWidth: 1))
    }
}

/// Карточка-квест: ✓ выполненные загораются, текущая подсвечена, будущие полупрозрачны, Boss — огненная.
struct QuestCard: View {
    @EnvironmentObject private var store: RPGStore
    let quest: Quest
    var compact = false
    var big = false
    var rmDay: Int? = nil

    private enum Look { case done, failed, pending, locked, future, open }

    private var look: Look {
        let s = store.state
        if quest.isDone { return .done }
        if quest.status == .failed { return .failed }
        if quest.status == .pending { return .pending }
        if s.isLocked(quest) { return .locked }
        if let d = rmDay, let qd = quest.day, qd > d + 10 { return .future }
        return .open
    }

    var body: some View {
        let s = store.state
        let main = quest.mainAward
        let color = RPGTheme.category(main?.cat ?? "growth")
        let extra = quest.awards.count - 1
        let lk = look
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if quest.boss {
                    Text("🔥 BOSS")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 6).fill(RPGTheme.bossGradient))
                } else {
                    Text(RPGData.category(main?.cat ?? "growth").emoji).font(.system(size: 16))
                }
                if quest.branch != nil { Text("🔄").font(.system(size: 13)) }
                Spacer(minLength: 0)
                switch lk {
                case .done: Image(systemName: "checkmark").font(.system(size: 16, weight: .heavy)).foregroundStyle(RPGTheme.ok)
                case .failed: Image(systemName: "xmark").foregroundStyle(RPGTheme.bad)
                case .pending: Text("⏳")
                case .locked: Image(systemName: "lock.fill").font(.system(size: 13)).foregroundStyle(RPGTheme.muted)
                default: EmptyView()
                }
            }
            Text(quest.title)
                .font(.system(size: big ? 19 : (compact ? 13 : 15), weight: .semibold))
                .foregroundStyle(lk == .done ? Color(hex: "CFF5E8") : RPGTheme.text)
                .strikethrough(lk == .failed)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Text("+\(RPGFormat.xp(main?.xp ?? 0)) \(store.unit)")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(RPGTheme.gold)
                if extra > 0 { Text("🪐+\(extra)").font(.system(size: 11, weight: .bold)).foregroundStyle(RPGTheme.violet2) }
                if s.isVerified(quest) {
                    Text("✓ verified").font(.system(size: 11, weight: .bold)).foregroundStyle(RPGTheme.ok)
                } else if quest.custom {
                    Text("свои").font(.system(size: 11)).foregroundStyle(RPGTheme.muted)
                }
            }
        }
        .padding(compact ? 10 : (big ? 18 : 12))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(colors: [bgTint(lk), RPGTheme.card], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(alignment: .leading) {
            UnevenRoundedRectangle(topLeadingRadius: 14, bottomLeadingRadius: 14)
                .fill(quest.boss ? RPGTheme.boss : color)
                .frame(width: 4)
        }
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(strokeColor(lk), lineWidth: 1))
        .shadow(color: lk == .done ? RPGTheme.ok.opacity(0.15) : .clear, radius: 10)
        .opacity(lk == .locked ? 0.55 : (lk == .future ? 0.45 : (lk == .failed ? 0.5 : 1)))
        .contentShape(Rectangle())
    }

    private func bgTint(_ lk: Look) -> Color {
        if lk == .done { return RPGTheme.ok.opacity(0.16) }
        if quest.boss { return RPGTheme.boss.opacity(0.14) }
        return RPGTheme.card
    }

    private func strokeColor(_ lk: Look) -> Color {
        switch lk {
        case .done: return RPGTheme.ok.opacity(0.45)
        case .pending: return RPGTheme.gold
        default: return quest.boss ? RPGTheme.boss.opacity(0.55) : RPGTheme.line
        }
    }
}

/// Строка направления: эмодзи, название, XP, шкала, ранг направления.
struct CategoryRow: View {
    let cat: String
    let xp: Int
    var weak = false

    var body: some View {
        let c = RPGData.category(cat)
        let r = RPGEngine.rank(for: xp, scale: .category)
        HStack(spacing: 10) {
            Text(c.emoji).font(.system(size: 20)).frame(width: 26)
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(c.label).font(.system(size: 14)).lineLimit(1)
                    Spacer()
                    Text("\(RPGFormat.xp(xp)) XP").font(.system(size: 13, weight: .bold)).foregroundStyle(RPGTheme.category(cat))
                }
                XPBar(progress: r.progress, height: 6, style: AnyShapeStyle(RPGTheme.category(cat)))
            }
            RankBadge(id: r.rank.id, size: 26)
        }
        .rpgCard(padding: 11, stroke: weak ? RPGTheme.bad : RPGTheme.line)
    }
}

struct ToastView: View {
    let toast: ToastMessage
    var body: some View {
        Text(toast.text)
            .font(.system(size: toast.isXP ? 19 : 14, weight: toast.isXP ? .heavy : .semibold))
            .foregroundStyle(toast.isXP ? Color(hex: "1B1300") : RPGTheme.text)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16).padding(.vertical, 12)
            .frame(maxWidth: 420)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(toast.isXP ? AnyShapeStyle(RPGTheme.goldGradient) : AnyShapeStyle(RPGTheme.card2.opacity(0.97)))
            )
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(toast.isXP ? .clear : RPGTheme.line, lineWidth: 1))
            .shadow(color: .black.opacity(0.4), radius: 14, y: 6)
            .padding(.horizontal, 16)
    }
}

/// 🏆 LEVEL UP! C → B · +1 000 XP · Achievement unlocked.
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
            Color.black.opacity(0.72).ignoresSafeArea().onTapGesture(perform: onClose)
            VStack(spacing: 10) {
                Text("🏆").font(.system(size: 64)).scaleEffect(pop || calm ? 1 : 0.3)
                Text("LEVEL UP!")
                    .legendTitle(36)
                    .foregroundStyle(LinearGradient(colors: [Color(hex: "FFF6D6"), RPGTheme.gold], startPoint: .top, endPoint: .bottom))
                Text(u.who).font(.system(size: 15, weight: .semibold)).foregroundStyle(RPGTheme.muted)
                HStack(spacing: 14) {
                    RankBadge(id: u.from, size: 40)
                    Image(systemName: "arrow.right").font(.title2.bold()).foregroundStyle(RPGTheme.gold)
                    RankBadge(id: u.to, size: 64)
                }
                .padding(.vertical, 6)
                if let to { Text("\(to.name)\(to.ru.isEmpty ? "" : " · \(to.ru)")").font(.headline) }
                if event.xp > 0 { Text("+\(RPGFormat.xp(event.xp)) \(unit)").font(.system(size: 24, weight: .heavy)).foregroundStyle(RPGTheme.gold) }
                ForEach(event.ups.dropFirst()) { x in
                    Text("\(x.who): \(x.from) → \(x.to)").font(.footnote).foregroundStyle(RPGTheme.muted)
                }
                ForEach(event.achievements) { a in
                    Text("\(a.icon) Achievement unlocked: **\(a.title)**")
                        .font(.system(size: 14))
                        .multilineTextAlignment(.center)
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 12).fill(RPGTheme.gold.opacity(0.12)))
                }
                Button("Продолжить", action: onClose).buttonStyle(PrimaryButtonStyle(calm: calm)).padding(.top, 6)
            }
            .foregroundStyle(RPGTheme.text)
            .padding(22)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous).fill(RPGTheme.bg2)
                    if !calm {
                        AngularGradient(colors: [.clear, RPGTheme.gold.opacity(0.25), .clear, RPGTheme.violet.opacity(0.25), .clear, RPGTheme.gold.opacity(0.25), .clear], center: .center)
                            .scaleEffect(2)
                            .rotationEffect(.degrees(spin ? 360 : 0))
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }
                }
            )
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(RPGTheme.line, lineWidth: 1))
            .padding(24)
        }
        .onAppear {
            guard !calm else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) { pop = true }
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) { spin = true }
        }
    }
}

/// ❌ Quest failed → 🔄 New route unlocked.
struct RerouteView: View {
    @EnvironmentObject private var store: RPGStore
    let event: RerouteEvent
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            Text("❌ Quest failed").font(.system(size: 22, weight: .heavy)).foregroundStyle(RPGTheme.bad)
            (Text("🔄 New route unlocked: ") + Text(event.result.route).bold()).font(.system(size: 17))
            VStack(spacing: 0) {
                ForEach(event.result.created) { q in
                    HStack(alignment: .top) {
                        Text("\(q.boss ? "🔥" : "☐") \(q.title)").font(.system(size: 14)).foregroundStyle(q.boss ? Color(hex: "FFB199") : RPGTheme.text)
                        Spacer()
                        Text("+\(RPGFormat.xp(q.mainAward?.xp ?? 0)) \(store.unit)").font(.system(size: 13, weight: .bold)).foregroundStyle(RPGTheme.gold)
                    }
                    .padding(.vertical, 9)
                    Divider().overlay(RPGTheme.line)
                }
            }
            Text("Реальная жизнь не идёт строго по плану — игра перестроила карту.")
                .font(.footnote).foregroundStyle(RPGTheme.muted).multilineTextAlignment(.center)
            Button("Вперёд") { dismiss() }.buttonStyle(PrimaryButtonStyle(calm: store.calm))
        }
        .foregroundStyle(RPGTheme.text)
        .padding(22)
        .presentationDetents([.medium, .large])
        .presentationBackground(RPGTheme.bg2)
    }
}

/// Поле ввода в тёмном стиле.
struct RPGField: View {
    let title: String
    @Binding var text: String
    var placeholder = ""
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !title.isEmpty { Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(RPGTheme.muted) }
            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(RPGTheme.muted.opacity(0.7)))
                .keyboardType(keyboard)
                .padding(12)
                .foregroundStyle(RPGTheme.text)
                .background(RoundedRectangle(cornerRadius: 12).fill(RPGTheme.bg2))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(RPGTheme.line, lineWidth: 1))
        }
    }
}

struct RPGTextArea: View {
    let title: String
    @Binding var text: String
    var placeholder = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !title.isEmpty { Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(RPGTheme.muted) }
            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(RPGTheme.muted.opacity(0.7)), axis: .vertical)
                .lineLimit(3...6)
                .padding(12)
                .foregroundStyle(RPGTheme.text)
                .background(RoundedRectangle(cornerRadius: 12).fill(RPGTheme.bg2))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(RPGTheme.line, lineWidth: 1))
        }
    }
}
