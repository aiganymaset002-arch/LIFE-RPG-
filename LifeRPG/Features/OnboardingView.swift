//
//  OnboardingView.swift
//  LIFE RPG
//
//  Старт: «Начать свою игру» или демо. Игрок, режим, мечта → AI Game Master строит первую карту.
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

    var body: some View {
        ZStack {
            RPGTheme.background
            if step == 0 { hero } else { form }
        }
        .foregroundStyle(RPGTheme.text)
    }

    private var hero: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("⚔️").font(.system(size: 64)).shadow(color: RPGTheme.gold.opacity(0.5), radius: 20)
            Text("LIFE RPG")
                .legendTitle(44)
                .tracking(4)
                .foregroundStyle(LinearGradient(colors: [Color(hex: "FFF6D6"), RPGTheme.gold], startPoint: .top, endPoint: .bottom))
            Text("Твоя жизнь — твоя игра.\nПрокачивай себя к легенде.")
                .font(.system(size: 18))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(hex: "D8D2FF"))
            HStack(spacing: 6) {
                ForEach(RPGData.personRanks) { RankBadge(id: $0.id, size: 32) }
            }
            .padding(.vertical, 6)
            Text("XP начисляется только за реальные результаты — не за время в приложении.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(RPGTheme.muted)
            Spacer()
            Button("Начать свою игру") { withAnimation { step = 1 } }
                .buttonStyle(PrimaryButtonStyle())
            Button("Посмотреть демо: Айганым · Rank A") { store.loadDemo() }
                .buttonStyle(SecondaryButtonStyle())
            Text("You don’t play a character. You build yourself.")
                .font(.system(size: 13, design: .serif))
                .foregroundStyle(RPGTheme.muted)
                .padding(.top, 6)
        }
        .padding(24)
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Button { withAnimation { step = 0 } } label: { Label("Назад", systemImage: "chevron.left") }
                    .foregroundStyle(RPGTheme.violet2)
                Text("Создай игрока").font(.title.bold())
                RPGField(title: "Имя", text: $name, placeholder: "Например, Айганым")
                HStack(spacing: 10) {
                    RPGField(title: "Возраст", text: $age, placeholder: "15", keyboard: .numberPad)
                    RPGField(title: "Город", text: $location, placeholder: "Астана")
                }
                Text("Выбери режим").font(.headline).padding(.top, 6)
                ForEach(GameMode.allCases) { m in
                    Button { mode = m } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(m.emoji) \(m.label)").font(.system(size: 15, weight: .bold))
                            Text(m.desc).font(.system(size: 12.5)).foregroundStyle(RPGTheme.muted).multilineTextAlignment(.leading)
                        }
                        .rpgCard(padding: 12, stroke: mode == m ? RPGTheme.gold : RPGTheme.line,
                                 fill: AnyShapeStyle(mode == m ? RPGTheme.gold.opacity(0.10) : RPGTheme.card))
                    }
                    .buttonStyle(.plain)
                }
                Text(mode == .company ? "Компания и её большая цель" : "Твоя главная мечта").font(.headline).padding(.top, 6)
                if mode == .company { RPGField(title: "Название компании", text: $company, placeholder: "MASHSTROY") }
                RPGTextArea(title: "", text: $dream, placeholder: mode.isChild
                            ? "Например: научиться читать и собрать свой робот"
                            : "Например: Хочу поступить в топовый университет и стать AI/software engineer")
                Text("AI Game Master превратит мечту в дорожную карту: квесты, Boss Battles, XP и уровни.")
                    .font(.footnote).foregroundStyle(RPGTheme.muted)
                Button("Создать игру ✨") {
                    store.startGame(name: name.trimmingCharacters(in: .whitespaces), age: Int(age), location: location,
                                    mode: mode, dream: dream.trimmingCharacters(in: .whitespacesAndNewlines),
                                    companyName: company.trimmingCharacters(in: .whitespaces))
                    onStart()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 6)
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}
