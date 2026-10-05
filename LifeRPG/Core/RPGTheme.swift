//
//  RPGTheme.swift
//  LIFE RPG
//
//  Тёмная «легендарная» тема: ночной фиолетовый + золото (как на карточках AIGANYM LIFE RPG).
//

import SwiftUI

extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let r = Double((v >> 16) & 0xFF) / 255
        let g = Double((v >> 8) & 0xFF) / 255
        let b = Double(v & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

enum RPGTheme {
    static let bg = Color(hex: "0B0A1A")
    static let bg2 = Color(hex: "12102A")
    static let card = Color(hex: "17143A")
    static let card2 = Color(hex: "1E1A48")
    static let line = Color(hex: "2C2766")
    static let text = Color(hex: "ECE9FF")
    static let muted = Color(hex: "9A94C7")
    static let gold = Color(hex: "FFC845")
    static let gold2 = Color(hex: "FF9D2E")
    static let violet = Color(hex: "8B5CFF")
    static let violet2 = Color(hex: "B07CFF")
    static let ok = Color(hex: "4FD1A5")
    static let bad = Color(hex: "FF5D6C")
    static let boss = Color(hex: "FF5A36")
    static let calm = Color(hex: "7FB7A8")
    static let senBg = Color(hex: "10141C")
    static let senCard = Color(hex: "1A2230")

    static let goldGradient = LinearGradient(colors: [gold2, gold], startPoint: .leading, endPoint: .trailing)
    static let barGradient = LinearGradient(colors: [gold2, gold, violet2], startPoint: .leading, endPoint: .trailing)
    static let violetGradient = LinearGradient(colors: [violet, Color(hex: "D14CFF")], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let bossGradient = LinearGradient(colors: [boss, gold2], startPoint: .leading, endPoint: .trailing)

    static var background: some View {
        ZStack {
            bg
            RadialGradient(colors: [Color(hex: "2A1D6B"), .clear], center: .top, startRadius: 0, endRadius: 520)
        }
        .ignoresSafeArea()
    }

    static func rankGradient(_ id: String) -> LinearGradient {
        let pair: (String, String)
        switch id {
        case "E": pair = ("8A5A2B", "C08A4A")
        case "D": pair = ("5D6676", "B5BFCF")
        case "C": pair = ("B07A16", "F0C35A")
        case "B": pair = ("5B2FD1", "B07CFF")
        case "A": pair = ("FF9D2E", "FFE07A")
        case "S": pair = ("1F5FD1", "6EC0FF")
        case "SS": pair = ("8E2DE2", "FF7AD9")
        default: pair = ("B8860B", "FFF1A8")
        }
        return LinearGradient(colors: [Color(hex: pair.0), Color(hex: pair.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func rankText(_ id: String) -> Color {
        ["D", "C", "A", "SSS"].contains(id) ? Color(hex: "1B1300") : .white
    }

    static func rankAccent(_ id: String) -> Color {
        switch id {
        case "A", "SSS", "C": return gold
        case "B", "SS": return violet2
        case "S": return Color(hex: "6EC0FF")
        default: return muted
        }
    }

    static func category(_ id: String) -> Color { Color(hex: RPGData.category(id).colorHex) }
}

struct RPGCardModifier: ViewModifier {
    var padding: CGFloat = 14
    var stroke: Color = RPGTheme.line
    var fill: AnyShapeStyle = AnyShapeStyle(RPGTheme.card)

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(stroke, lineWidth: 1))
    }
}

extension View {
    func rpgCard(padding: CGFloat = 14, stroke: Color = RPGTheme.line, fill: AnyShapeStyle = AnyShapeStyle(RPGTheme.card)) -> some View {
        modifier(RPGCardModifier(padding: padding, stroke: stroke, fill: fill))
    }

    /// Заголовки в стиле «легендарной» серифной надписи.
    func legendTitle(_ size: CGFloat) -> some View {
        font(.system(size: size, weight: .heavy, design: .serif))
    }
}
