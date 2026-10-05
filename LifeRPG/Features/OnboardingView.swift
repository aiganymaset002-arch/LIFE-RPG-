//
//  OnboardingView.swift
//  LIFE RPG
//
//  Заставка как в игре: сцена с героем, логотип, «ИГРАТЬ» / «Демо».
//  Затем панель создания героя: аватар, имя, режим, мечта → Оракул строит первую карту.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: RPGStore
    var onStart: () -> Void

    @State private var step = 0
    @State private var name = ""
    @State private var age = ""
    @State private var location = ""
    @State private var mode: GameMode = .life
    @State private var dream = ""
    @State private var company = ""
    @State private var avatar = "AvatarLeopard"
    @State private var shine = false

    var body: some View {
        ZStack {
            GameBackground(dim: step == 0 ? 0 : 0.5)
            if step == 0 {
                Sparkles(count: 18)
                HeroLayer()
                splash
            } else {
                form
            }
        }
    }

    private var splash: some View {
        VStack(spacing: 10) {
            VStack(spacing: 2) {
                Text("LIFE RPG")
                    .font(GameFont.display(54))
                    .foregroundStyle(LinearGradient(colors: [Color(hex: "FFF6D6"), RPGTheme.gold, Color(hex: "F3A92E")], startPoint: .top, endPoint: .bottom))
                    .outlined(Color(hex: "3A1A00"), 2.4)
                    .shadow(color: RPGTheme.gold.opacity(shine ? 0.8 : 0.3), radius: 18)
                Text("Твоя жизнь — твоя игра")
                    .font(GameFont.title(20))
                    .foregroundStyle(RPGTheme.cream)
                    .outlined(RPGTheme.edgeDark, 1.2)
            }
            .padding(.top, 50)
            HStack(spacing: 4) {
                ForEach(RPGData.personRanks) { RankShield(id: $0.id, size: 30) }
            }
            Spacer()
            Text("XP — только за реальные результаты")
                .font(GameFont.body(13, .bold)).foregroundStyle(RPGTheme.cream).outlined(RPGTheme.edgeDark, 1)
            Button {
                withAnimation { step = 1 }
            } label: {
                HStack(spacing: 10) { Text("Играть"); Image(systemName: "play.fill") }
            }
            .buttonStyle(ChunkyButtonStyle(kind: .cyan, size: 28, radius: 22))
            Button("Демо: Айганым · Rank A") { store.loadDemo() }
                .buttonStyle(ChunkyButtonStyle(kind: .purple, size: 16))
            Text("You don’t play a character. You build yourself.")
                .font(GameFont.title(13)).foregroundStyle(RPGTheme.muted).padding(.bottom, 6)
        }
        .padding(.horizontal, 22)
        .onAppear { withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { shine = true } }
    }

    private var form: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                ScreenHeader(title: "Новый герой") { withAnimation { step = 0 } }
                OrnatePanel(title: "Выбери героя") {
                    HStack(spacing: 10) {
                        ForEach(["AvatarLeopard", "AvatarGirl", "AvatarBoy"], id: \.self) { a in
                            Button { avatar = a } label: {
                                VStack(spacing: 6) {
                                    Image(a).resizable().scaledToFill().frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(avatar == a ? AnyShapeStyle(RPGTheme.goldGradient) : AnyShapeStyle(RPGTheme.edgeDark), lineWidth: avatar == a ? 4 : 2))
                                    CheckStone(on: avatar == a)
                                }
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    GameField(title: "Имя", text: $name, placeholder: "Например, Айганым")
                    HStack(spacing: 10) {
                        GameField(title: "Возраст", text: $age, placeholder: "15", keyboard: .numberPad)
                        GameField(title: "Город", text: $location, placeholder: "Астана")
                    }
                }
                OrnatePanel(title: "Режим игры") {
                    ForEach(GameMode.allCases) { m in
                        Button { mode = m } label: {
                            HStack(alignment: .top, spacing: 10) {
                                Text(m.emoji).font(.system(size: 26))
                                VStack(alignment: .leading, spacing: 3) {
                                    GameLabel(text: m.label, size: 14, color: mode == m ? RPGTheme.gold : RPGTheme.cream)
                                    Text(m.desc).font(GameFont.body(12, .medium)).foregroundStyle(RPGTheme.muted).multilineTextAlignment(.leading)
                                }
                                Spacer()
                                CheckStone(on: mode == m)
                            }
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(mode == m ? Color(hex: "4A3878") : Color(hex: "1A1032")))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(mode == m ? AnyShapeStyle(RPGTheme.goldGradient) : AnyShapeStyle(Color.black.opacity(0.5)), lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 8)
                OrnatePanel(title: mode == .company ? "Цель компании" : "Твоя мечта") {
                    if mode == .company { GameField(title: "Название компании", text: $company, placeholder: "MASHSTROY") }
                    GameField(title: "", text: $dream, placeholder: mode.isChild ? "Например: научиться читать и собрать свой робот" : "Например: Хочу поступить в топовый университет и стать AI/software engineer", multiline: true)
                    Text("Оракул превратит мечту в дорожную карту: квесты, Boss Battles, XP и уровни.")
                        .font(GameFont.body(12, .medium)).foregroundStyle(RPGTheme.muted)
                    Button("Начать игру ▶") {
                        store.startGame(name: name.trimmingCharacters(in: .whitespaces), age: Int(age), location: location, mode: mode,
                                        dream: dream.trimmingCharacters(in: .whitespacesAndNewlines),
                                        companyName: company.trimmingCharacters(in: .whitespaces), avatar: avatar)
                        onStart()
                    }
                    .buttonStyle(ChunkyButtonStyle(kind: .cyan, size: 22))
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}
