//
//  GameUI.swift
//  LIFE RPG
//
//  Игровые элементы: обведённый текст, «3D»-кнопки, медальоны с золотым кольцом, резные панели,
//  шкалы, щиты рангов, кристаллы-валюты, поля ввода, переключатели.
//

import SwiftUI

// MARK: - Обведённый текст

struct Outlined: ViewModifier {
    var color: Color = RPGTheme.edgeDark
    var width: CGFloat = 1.4
    func body(content: Content) -> some View {
        content
            .shadow(color: color, radius: 0, x: width, y: 0)
            .shadow(color: color, radius: 0, x: -width, y: 0)
            .shadow(color: color, radius: 0, x: 0, y: width)
            .shadow(color: color, radius: 0, x: 0, y: -width)
            .shadow(color: color.opacity(0.7), radius: 0, x: 0, y: width + 1.5)
    }
}

extension View {
    func outlined(_ color: Color = RPGTheme.edgeDark, _ width: CGFloat = 1.4) -> some View { modifier(Outlined(color: color, width: width)) }
}

/// Надпись в стиле игрового меню: Russo One, капс, кремовый цвет с тёмной обводкой.
struct GameLabel: View {
    let text: String
    var size: CGFloat = 18
    var color: Color = RPGTheme.cream
    var body: some View {
        Text(text.uppercased())
            .font(GameFont.display(size))
            .foregroundStyle(color)
            .outlined(RPGTheme.edgeDark, size > 20 ? 1.8 : 1.2)
    }
}

// MARK: - Кнопки

enum ChunkyKind {
    case gold, cyan, green, red, purple, stone, calm

    var top: Color {
        switch self {
        case .gold: return Color(hex: "FFE48A")
        case .cyan: return Color(hex: "8FF0FF")
        case .green: return Color(hex: "9CF09A")
        case .red: return Color(hex: "FF9A80")
        case .purple: return Color(hex: "C9A6FF")
        case .stone: return Color(hex: "7E6AB8")
        case .calm: return Color(hex: "A8D8CB")
        }
    }
    var base: Color {
        switch self {
        case .gold: return Color(hex: "F3A92E")
        case .cyan: return Color(hex: "1F9BE8")
        case .green: return Color(hex: "38B85A")
        case .red: return Color(hex: "E0442E")
        case .purple: return Color(hex: "7A45E8")
        case .stone: return Color(hex: "4A3878")
        case .calm: return Color(hex: "6FA898")
        }
    }
    var shade: Color {
        switch self {
        case .gold: return Color(hex: "9A5A0C")
        case .cyan: return Color(hex: "0E4E96")
        case .green: return Color(hex: "1C6A30")
        case .red: return Color(hex: "7E1C12")
        case .purple: return Color(hex: "3A1C8A")
        case .stone: return Color(hex: "21163F")
        case .calm: return Color(hex: "3E6A5E")
        }
    }
}

/// Сочная «3D»-кнопка: глянец, золотой кант, нижняя грань, нажатие вдавливает.
struct ChunkyButtonStyle: ButtonStyle {
    var kind: ChunkyKind = .gold
    var size: CGFloat = 18
    var fullWidth = true
    var radius: CGFloat = 16

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .font(GameFont.display(size))
            .textCase(.uppercase)
            .foregroundStyle(.white)
            .outlined(kind.shade, size > 20 ? 1.8 : 1.3)
            .multilineTextAlignment(.center)
            .padding(.vertical, size * 0.75)
            .padding(.horizontal, size * 1.1)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(LinearGradient(colors: [kind.top, kind.base], startPoint: .top, endPoint: .bottom))
                    RoundedRectangle(cornerRadius: radius - 3, style: .continuous)
                        .fill(LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0)], startPoint: .top, endPoint: .center))
                        .padding(3)
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(RPGTheme.goldGradient, lineWidth: 2.5)
                    RoundedRectangle(cornerRadius: radius - 2.5, style: .continuous)
                        .strokeBorder(kind.shade.opacity(0.6), lineWidth: 1)
                        .padding(2.5)
                }
            )
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(kind.shade)
                    .offset(y: pressed ? 1 : 5)
            )
            .offset(y: pressed ? 4 : 0)
            .padding(.bottom, 5)
            .shadow(color: .black.opacity(0.35), radius: 6, y: 6)
            .animation(.easeOut(duration: 0.08), value: pressed)
    }
}

/// Медальон в золотом кольце (как круглые кнопки меню).
struct Medallion: View {
    let icon: String
    var size: CGFloat = 56
    var gem: Color = Color(hex: "2B1C52")
    var emoji = false
    var glow = false

    var body: some View {
        ZStack {
            Circle().fill(RPGTheme.goldRing)
            Circle().fill(RPGTheme.edgeDark).padding(size * 0.07)
            Circle()
                .fill(RadialGradient(colors: [gem.opacity(0.95), Color(hex: "120A24")], center: .init(x: 0.4, y: 0.3), startRadius: 1, endRadius: size * 0.6))
                .padding(size * 0.1)
            Circle()
                .fill(LinearGradient(colors: [.white.opacity(0.28), .clear], startPoint: .top, endPoint: .center))
                .padding(size * 0.12)
            if emoji {
                Text(icon).font(.system(size: size * 0.44))
            } else {
                Image(systemName: icon)
                    .font(.system(size: size * 0.38, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: [.white, RPGTheme.goldLight], startPoint: .top, endPoint: .bottom))
                    .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: 1.5)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: glow ? RPGTheme.gold.opacity(0.7) : .black.opacity(0.45), radius: glow ? 12 : 5, y: glow ? 0 : 3)
    }
}

/// Круглый аватар в золотом кольце с бейджем ранга.
struct AvatarMedallion: View {
    let avatar: String
    var size: CGFloat = 52
    var badge: String? = nil

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle().fill(RPGTheme.goldRing)
                Circle().fill(Color(hex: "3A2A6A")).padding(size * 0.07)
                Image(avatar)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size * 0.86, height: size * 0.86)
                    .clipShape(Circle())
            }
            .frame(width: size, height: size)
            if let badge {
                RankShield(id: badge, size: size * 0.46)
                    .offset(x: size * 0.12, y: size * 0.08)
            }
        }
        .shadow(color: .black.opacity(0.5), radius: 5, y: 3)
    }
}

// MARK: - Ранги

struct ShieldShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.16))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.58))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.maxY), control: CGPoint(x: r.maxX, y: r.minY + r.height * 0.86))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.58), control: CGPoint(x: r.minX, y: r.minY + r.height * 0.86))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.16))
        p.closeSubpath()
        return p
    }
}

/// Щит ранга: E D C B A S SS SSS.
struct RankShield: View {
    let id: String
    var size: CGFloat = 34

    var body: some View {
        let c = RPGTheme.rankColors(id)
        ZStack {
            ShieldShape().fill(RPGTheme.goldGradient)
            ShieldShape().fill(LinearGradient(colors: c, startPoint: .top, endPoint: .bottom)).padding(size * 0.08)
            ShieldShape().fill(LinearGradient(colors: [.white.opacity(0.45), .clear], startPoint: .top, endPoint: .center)).padding(size * 0.1)
            Text(id)
                .font(GameFont.display(size * (id.count > 2 ? 0.3 : (id.count > 1 ? 0.36 : 0.48))))
                .foregroundStyle(.white)
                .outlined(c[1].opacity(0.9), size > 40 ? 1.6 : 1)
                .offset(y: -size * 0.04)
        }
        .frame(width: size, height: size * 1.12)
        .shadow(color: ["A", "S", "SS", "SSS"].contains(id) ? c[0].opacity(0.7) : .black.opacity(0.4), radius: ["A", "S", "SS", "SSS"].contains(id) ? 8 : 3, y: 2)
        .accessibilityLabel("Ранг \(id)")
    }
}

// MARK: - Шкалы

struct GameBar: View {
    let progress: Double
    var height: CGFloat = 16
    var fill: LinearGradient = RPGTheme.barGradient
    var label: String? = nil

    var body: some View {
        GeometryReader { geo in
            let p = Swift.min(1, Swift.max(0, progress))
            ZStack(alignment: .leading) {
                Capsule().fill(Color(hex: "120A24"))
                Capsule().strokeBorder(Color.black.opacity(0.6), lineWidth: 1)
                Capsule()
                    .fill(fill)
                    .overlay(Capsule().fill(LinearGradient(colors: [.white.opacity(0.55), .clear], startPoint: .top, endPoint: .center)).padding(.horizontal, 3).padding(.top, 1.5))
                    .frame(width: Swift.max(height, (geo.size.width - 4) * p))
                    .padding(2)
                    .opacity(p <= 0 ? 0 : 1)
                if let label {
                    Text(label)
                        .font(GameFont.display(Swift.max(9, height * 0.62)))
                        .foregroundStyle(.white)
                        .outlined(RPGTheme.edgeDark, 1)
                        .frame(maxWidth: .infinity)
                }
            }
            .overlay(Capsule().strokeBorder(RPGTheme.goldGradient, lineWidth: 1.5))
        }
        .frame(height: height)
        .animation(.easeOut(duration: 0.6), value: progress)
    }
}

// MARK: - Резная панель

/// Каменная панель с объёмным кантом, заклёпками и табличкой-заголовком.
struct OrnatePanel<Content: View>: View {
    var title: String? = nil
    var onClose: (() -> Void)? = nil
    var padding: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(padding)
            .padding(.top, title == nil ? 0 : 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PanelBackground())
            .overlay(alignment: .top) {
                if let title { TitlePlaque(text: title).offset(y: -22) }
            }
            .overlay(alignment: .topTrailing) {
                if let onClose {
                    Button(action: onClose) { CloseGem() }
                        .offset(x: 10, y: -14)
                        .accessibilityLabel("Закрыть")
                }
            }
            .padding(.top, title == nil ? 0 : 22)
    }
}

struct PanelBackground: View {
    var radius: CGFloat = 24
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous).fill(RPGTheme.edgeDark)
            RoundedRectangle(cornerRadius: radius - 2, style: .continuous)
                .fill(LinearGradient(colors: [RPGTheme.edgeLight, RPGTheme.edgeMid, Color(hex: "3A2A6A")], startPoint: .top, endPoint: .bottom))
                .padding(2.5)
            RoundedRectangle(cornerRadius: radius - 8, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: "35265C"), RPGTheme.panelInner], startPoint: .top, endPoint: .bottom))
                .padding(9)
            RoundedRectangle(cornerRadius: radius - 8, style: .continuous)
                .strokeBorder(Color.black.opacity(0.55), lineWidth: 2)
                .padding(9)
            RoundedRectangle(cornerRadius: radius - 10, style: .continuous)
                .strokeBorder(RPGTheme.edgeLight.opacity(0.25), lineWidth: 1)
                .padding(11)
            GeometryReader { g in
                ForEach(0..<4, id: \.self) { i in
                    Rivet()
                        .position(x: i % 2 == 0 ? 15 : g.size.width - 15, y: i < 2 ? 15 : g.size.height - 15)
                }
            }
        }
        .shadow(color: .black.opacity(0.5), radius: 14, y: 8)
    }
}

struct Rivet: View {
    var body: some View {
        Circle()
            .fill(RadialGradient(colors: [RPGTheme.goldLight, RPGTheme.gold, RPGTheme.goldDark], center: .init(x: 0.35, y: 0.3), startRadius: 0, endRadius: 6))
            .frame(width: 8, height: 8)
            .shadow(color: .black.opacity(0.6), radius: 0, y: 1)
    }
}

struct TitlePlaque: View {
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Rivet()
            Text(text)
                .font(GameFont.title(22))
                .foregroundStyle(RPGTheme.cream)
                .outlined(RPGTheme.edgeDark, 1.4)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Rivet()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(RPGTheme.edgeDark)
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(LinearGradient(colors: [Color(hex: "8C76C8"), Color(hex: "4E3A8A")], startPoint: .top, endPoint: .bottom))
                    .padding(2)
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(LinearGradient(colors: [.white.opacity(0.3), .clear], startPoint: .top, endPoint: .center))
                    .padding(3)
            }
        )
        .shadow(color: .black.opacity(0.45), radius: 4, y: 3)
        .padding(.horizontal, 30)
    }
}

struct CloseGem: View {
    var body: some View {
        ZStack {
            Circle().fill(RPGTheme.edgeDark)
            Circle().fill(LinearGradient(colors: [Color(hex: "9C86D8"), Color(hex: "4E3A8A")], startPoint: .top, endPoint: .bottom)).padding(2.5)
            Image(systemName: "xmark").font(.system(size: 15, weight: .black)).foregroundStyle(RPGTheme.cream).shadow(color: .black, radius: 0, y: 1)
        }
        .frame(width: 38, height: 38)
        .shadow(color: .black.opacity(0.5), radius: 3, y: 2)
    }
}

/// Внутренняя «ячейка» панели (тёмная вдавленная плашка).
struct InsetCard<Content: View>: View {
    var stroke: Color = Color.black.opacity(0.5)
    var tint: Color? = nil
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(colors: [(tint ?? Color(hex: "1A1032")).opacity(tint == nil ? 1 : 0.35), Color(hex: "241848")], startPoint: .top, endPoint: .bottom))
            )
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(stroke, lineWidth: 1.5))
            .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).strokeBorder(RPGTheme.edgeLight.opacity(0.15), lineWidth: 1).padding(1.5))
    }
}

// MARK: - Валюта и чипы

struct CurrencyPill: View {
    let icon: String
    let text: String
    var tint: Color = RPGTheme.gold
    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle().fill(RadialGradient(colors: [tint, tint.opacity(0.4)], center: .init(x: 0.4, y: 0.3), startRadius: 0, endRadius: 12))
                Image(systemName: icon).font(.system(size: 10, weight: .black)).foregroundStyle(.white).shadow(color: .black.opacity(0.5), radius: 0, y: 1)
            }
            .frame(width: 22, height: 22)
            .overlay(Circle().strokeBorder(RPGTheme.goldGradient, lineWidth: 1.5))
            Text(text).font(GameFont.display(13)).foregroundStyle(.white).outlined(RPGTheme.edgeDark, 1).lineLimit(1)
        }
        .padding(.leading, 2).padding(.trailing, 10).padding(.vertical, 2)
        .background(Capsule().fill(Color(hex: "120A24").opacity(0.85)))
        .overlay(Capsule().strokeBorder(Color(hex: "6A54A8"), lineWidth: 1.2))
    }
}

struct StoneChip: View {
    let text: String
    var selected = false
    var body: some View {
        Text(text)
            .font(GameFont.body(13, .bold))
            .foregroundStyle(selected ? Color(hex: "2A1600") : RPGTheme.cream)
            .lineLimit(1)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(
                Capsule().fill(selected ? AnyShapeStyle(LinearGradient(colors: [RPGTheme.goldLight, RPGTheme.gold], startPoint: .top, endPoint: .bottom))
                                        : AnyShapeStyle(LinearGradient(colors: [Color(hex: "5A4690"), Color(hex: "3A2A6A")], startPoint: .top, endPoint: .bottom)))
            )
            .overlay(Capsule().strokeBorder(selected ? RPGTheme.goldDark : RPGTheme.edgeDark, lineWidth: 1.5))
            .shadow(color: .black.opacity(0.35), radius: 0, y: 2)
    }
}

// MARK: - Поля ввода и переключатели

struct GameField: View {
    let title: String
    @Binding var text: String
    var placeholder = ""
    var keyboard: UIKeyboardType = .default
    var multiline = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !title.isEmpty { Text(title).font(GameFont.body(13, .bold)).foregroundStyle(RPGTheme.muted) }
            Group {
                if multiline {
                    TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(RPGTheme.muted.opacity(0.6)), axis: .vertical).lineLimit(3...6)
                } else {
                    TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(RPGTheme.muted.opacity(0.6))).keyboardType(keyboard)
                }
            }
            .font(GameFont.body(16, .medium))
            .foregroundStyle(RPGTheme.cream)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: "150C2A")))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Color.black.opacity(0.7), lineWidth: 2))
            .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).strokeBorder(RPGTheme.edgeLight.opacity(0.3), lineWidth: 1).padding(2))
        }
    }
}

/// Квадратный «камень» с галочкой (как Girl/Boy в настройках).
struct CheckStone: View {
    var on: Bool
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous).fill(RPGTheme.edgeDark)
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: "6A54A8"), Color(hex: "3A2A6A")], startPoint: .top, endPoint: .bottom))
                .padding(2)
            if on {
                Image(systemName: "checkmark").font(.system(size: 16, weight: .black)).foregroundStyle(.white).shadow(color: .black, radius: 0, y: 1)
            }
        }
        .frame(width: 30, height: 30)
    }
}

struct GameToggle: View {
    let title: String
    var icon: String
    @Binding var isOn: Bool
    var body: some View {
        Button { isOn.toggle() } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(LinearGradient(colors: [Color(hex: "6A54A8"), Color(hex: "3A2A6A")], startPoint: .top, endPoint: .bottom))
                    Image(systemName: icon).font(.system(size: 14, weight: .bold)).foregroundStyle(RPGTheme.cream)
                }
                .frame(width: 32, height: 32)
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(RPGTheme.edgeDark, lineWidth: 1.5))
                Text(title).font(GameFont.title(17)).foregroundStyle(RPGTheme.cream).multilineTextAlignment(.leading)
                Spacer()
                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule().fill(isOn ? AnyShapeStyle(RPGTheme.xpGradient) : AnyShapeStyle(Color(hex: "120A24")))
                        .overlay(Capsule().strokeBorder(Color.black.opacity(0.6), lineWidth: 1.5))
                    Circle()
                        .fill(RadialGradient(colors: [RPGTheme.goldLight, RPGTheme.gold, RPGTheme.goldDark], center: .init(x: 0.35, y: 0.3), startRadius: 0, endRadius: 14))
                        .frame(width: 24, height: 24)
                        .padding(3)
                        .shadow(color: .black.opacity(0.5), radius: 1, y: 1)
                }
                .frame(width: 58, height: 30)
                .animation(.easeOut(duration: 0.15), value: isOn)
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "1A1032").opacity(0.8)))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.black.opacity(0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Фон и искры

struct GameBackground: View {
    var dim: Double = 0
    var body: some View {
        GeometryReader { g in
            Image("LobbyBackground")
                .resizable()
                .scaledToFill()
                .frame(width: g.size.width, height: g.size.height)
                .clipped()
                .overlay(Color(hex: "120826").opacity(dim))
        }
        .ignoresSafeArea()
    }
}

/// Мерцающие искры поверх сцены.
struct Sparkles: View {
    var count = 14
    var calm = false
    @State private var on = false
    var body: some View {
        GeometryReader { g in
            ForEach(0..<count, id: \.self) { i in
                let x = CGFloat((i * 73) % 100) / 100 * g.size.width
                let y = CGFloat((i * 37 + 11) % 100) / 100 * g.size.height
                Image(systemName: "sparkle")
                    .font(.system(size: CGFloat(6 + (i % 4) * 3)))
                    .foregroundStyle(i % 3 == 0 ? RPGTheme.goldLight : .white)
                    .opacity(calm ? 0.5 : (on ? (i % 2 == 0 ? 0.95 : 0.15) : (i % 2 == 0 ? 0.15 : 0.9)))
                    .position(x: x, y: y)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            guard !calm else { return }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { on = true }
        }
    }
}

/// Заголовок экрана: табличка по центру.
struct ScreenHeader: View {
    let title: String
    var back: (() -> Void)? = nil
    var body: some View {
        ZStack {
            TitlePlaque(text: title)
            if let back {
                HStack {
                    Button(action: back) {
                        ZStack {
                            Circle().fill(RPGTheme.edgeDark)
                            Circle().fill(LinearGradient(colors: [Color(hex: "9C86D8"), Color(hex: "4E3A8A")], startPoint: .top, endPoint: .bottom)).padding(2.5)
                            Image(systemName: "chevron.left").font(.system(size: 16, weight: .black)).foregroundStyle(RPGTheme.cream).shadow(color: .black, radius: 0, y: 1)
                        }
                        .frame(width: 40, height: 40)
                    }
                    .accessibilityLabel("Назад")
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}

/// Небольшая подпись секции с золотыми ромбами.
struct SectionTitle: View {
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "diamond.fill").font(.system(size: 8)).foregroundStyle(RPGTheme.gold)
            Text(text.uppercased()).font(GameFont.display(14)).foregroundStyle(RPGTheme.gold).outlined(RPGTheme.edgeDark, 1)
            Rectangle().fill(LinearGradient(colors: [RPGTheme.gold.opacity(0.7), .clear], startPoint: .leading, endPoint: .trailing)).frame(height: 1.5)
        }
        .padding(.top, 14)
    }
}

/// Гаптика для приятных нажатий.
enum Haptics {
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func tap() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
}
