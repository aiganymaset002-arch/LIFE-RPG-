//
//  RPGTheme.swift
//  LIFE RPG
//
//  Игровая дизайн-система: сумеречная фэнтези-палитра, золото, камень; шрифты Russo One и Philosopher.
//

import SwiftUI
import CoreText

extension Color {
    init(hex: String, opacity: Double = 1) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        self.init(.sRGB, red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255, opacity: opacity)
    }
}

enum RPGTheme {
    // Ночь и камень
    static let night = Color(hex: "140A28")
    static let night2 = Color(hex: "1E1238")
    static let panel = Color(hex: "3B2A63")
    static let panelInner = Color(hex: "2A1D4A")
    static let panelDeep = Color(hex: "1F1538")
    static let edgeLight = Color(hex: "9C86D8")
    static let edgeMid = Color(hex: "6A54A8")
    static let edgeDark = Color(hex: "150C2A")
    // Золото
    static let gold = Color(hex: "F6C453")
    static let goldLight = Color(hex: "FFF0B0")
    static let goldDark = Color(hex: "9A6512")
    // Текст
    static let cream = Color(hex: "FFF6E0")
    static let muted = Color(hex: "B9A9E0")
    static let text = cream
    // Статусы
    static let ok = Color(hex: "5BE08A")
    static let bad = Color(hex: "FF6A5A")
    static let boss = Color(hex: "FF5A36")
    static let cyan = Color(hex: "3FD8FF")
    static let violet = Color(hex: "8B5CFF")
    static let violet2 = Color(hex: "B48CFF")
    static let calm = Color(hex: "7FB7A8")
    static let senBg = Color(hex: "121826")
    static let senCard = Color(hex: "1C2638")

    static let goldGradient = LinearGradient(colors: [goldLight, gold, goldDark], startPoint: .top, endPoint: .bottom)
    static let goldRing = AngularGradient(colors: [goldLight, gold, goldDark, gold, goldLight, goldDark, goldLight], center: .center)
    static let barGradient = LinearGradient(colors: [Color(hex: "FFE27A"), Color(hex: "F6A83A")], startPoint: .top, endPoint: .bottom)
    static let xpGradient = LinearGradient(colors: [Color(hex: "D9A8FF"), Color(hex: "8B5CFF")], startPoint: .top, endPoint: .bottom)
    static let bossGradient = LinearGradient(colors: [Color(hex: "FF8A5A"), boss, Color(hex: "B82A1A")], startPoint: .top, endPoint: .bottom)

    static func category(_ id: String) -> Color { Color(hex: RPGData.category(id).colorHex) }

    static func rankColors(_ id: String) -> [Color] {
        switch id {
        case "E": return [Color(hex: "E0A868"), Color(hex: "8A5A2B")]
        case "D": return [Color(hex: "E6ECF5"), Color(hex: "7A8496")]
        case "C": return [Color(hex: "FFE08A"), Color(hex: "B07A16")]
        case "B": return [Color(hex: "D0A8FF"), Color(hex: "5B2FD1")]
        case "A": return [Color(hex: "FFF0A0"), Color(hex: "FF9D2E")]
        case "S": return [Color(hex: "A8E4FF"), Color(hex: "1F5FD1")]
        case "SS": return [Color(hex: "FFB0EC"), Color(hex: "8E2DE2")]
        default: return [Color(hex: "FFF6C8"), Color(hex: "B8860B")]
        }
    }

    static func rankAccent(_ id: String) -> Color { rankColors(id)[0] }
}

// MARK: - Шрифты

enum GameFont {
    /// Игровые кнопки и цифры (Russo One).
    static func display(_ size: CGFloat) -> Font { .custom("RussoOne-Regular", size: size) }
    /// Фэнтези-заголовки (Philosopher Bold).
    static func title(_ size: CGFloat) -> Font { .custom("Philosopher-Bold", size: size) }
    /// Основной текст.
    static func body(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font { .system(size: size, weight: weight, design: .rounded) }

    /// Регистрирует шрифты из бандла (без правки Info.plist).
    static func register() {
        for name in ["RussoOne-Regular", "Philosopher-Bold"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
