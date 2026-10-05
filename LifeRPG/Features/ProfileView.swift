//
//  ProfileView.swift
//  LIFE RPG
//
//  Герой: портрет, щит ранга, общий и Verified XP, шкала E → SSS, следующий уровень, достижения,
//  результаты по направлениям. Зал рангов. Панель настроек (аватар, режим, переключатели, экспорт/импорт).
//

import SwiftUI
import UniformTypeIdentifiers

struct ProfileView: View {
    @EnvironmentObject private var store: RPGStore
    @State private var showRanks = false

    var body: some View {
        if showRanks {
            RanksView { showRanks = false }
        } else {
            hero
        }
    }

    private var hero: some View {
        let s = store.state
        let p = s.playerRank()
        let xp = s.playerXP()
        let scale = RPGData.ranks(s.playerScale)
        let cx = s.categoryXP()
        let done = s.quests.filter(\.isDone)
        let grouped = Dictionary(grouping: done) { $0.mainAward?.cat ?? "growth" }
        let order = grouped.keys.sorted { (cx[$0] ?? 0) > (cx[$1] ?? 0) }
        return ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                ScreenHeader(title: "Герой")
                OrnatePanel {
                    HStack(spacing: 14) {
                        AvatarMedallion(avatar: store.avatar, size: 96)
                        VStack(alignment: .leading, spacing: 4) {
                            GameLabel(text: s.profile?.name ?? "", size: 22)
                            Text([s.profile?.age.map { "Возраст: \($0)" }, s.profile?.location].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
                                .font(GameFont.body(12, .medium)).foregroundStyle(RPGTheme.muted)
                            Text("RPG уровень").font(GameFont.body(12, .bold)).foregroundStyle(RPGTheme.muted)
                            GameLabel(text: "\(p.rank.id) · \(p.rank.name)", size: 17, color: RPGTheme.rankAccent(p.rank.id))
                        }
                        Spacer(minLength: 0)
                        Button { showRanks = true } label: { RankShield(id: p.rank.id, size: 60) }
                            .buttonStyle(.plain)
                    }
                    InsetCard(stroke: RPGTheme.gold.opacity(0.6)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("РЕЗУЛЬТАТ · ОБЩИЙ XP").font(GameFont.display(10)).foregroundStyle(RPGTheme.muted)
                                GameLabel(text: "\(RPGFormat.xp(xp)) \(store.unit)", size: 32, color: RPGTheme.gold)
                                Text("Verified \(RPGFormat.xp(s.playerXP(verifiedOnly: true))) ✓ · \(done.count) результатов").font(GameFont.body(12, .bold)).foregroundStyle(RPGTheme.ok)
                            }
                            Spacer()
                            Text("🏆").font(.system(size: 50)).shadow(color: RPGTheme.gold.opacity(0.6), radius: 12)
                        }
                    }
                    GameBar(progress: p.progress, height: 18, label: p.next.map { "До ранга \($0.id) · \(RPGFormat.xp(p.toNext)) XP" } ?? "Максимальный ранг")
                }

                OrnatePanel(title: "Шкала уровней") {
                    HStack(spacing: 2) {
                        ForEach(scale) { r in
                            VStack(spacing: 3) {
                                RankShield(id: r.id, size: r.id == p.rank.id ? 38 : 28)
                                Text(compact(r.min)).font(GameFont.display(8)).foregroundStyle(r.id == p.rank.id ? RPGTheme.gold : RPGTheme.muted)
                            }
                            .frame(maxWidth: .infinity)
                            .opacity(r.min <= xp ? 1 : 0.55)
                        }
                    }
                    Button("Все ранги →") { showRanks = true }.buttonStyle(ChunkyButtonStyle(kind: .purple, size: 14))
                }
                .padding(.top, 8)

                OrnatePanel(title: "Достижения") {
                    AchievementGrid(items: s.achievements)
                }
                .padding(.top, 8)

                OrnatePanel(title: "Результаты") {
                    ForEach(order, id: \.self) { c in
                        let qs = grouped[c] ?? []
                        DisclosureGroup {
                            VStack(spacing: 2) {
                                ForEach(qs) { q in
                                    Button { store.open(.quest(q.id)) } label: {
                                        HStack(alignment: .top) {
                                            Text(s.isVerified(q) ? "✓" : "·").font(GameFont.display(12)).foregroundStyle(RPGTheme.ok)
                                            Text(q.title).font(GameFont.body(13, .semibold)).foregroundStyle(RPGTheme.cream).multilineTextAlignment(.leading)
                                            Spacer()
                                            Text("+\(RPGFormat.xp(s.questXP(q)))").font(GameFont.display(12)).foregroundStyle(RPGTheme.gold)
                                        }
                                        .padding(.vertical, 5)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text(RPGData.category(c).emoji).font(.system(size: 20))
                                Text(RPGData.category(c).label).font(GameFont.body(14, .bold)).foregroundStyle(RPGTheme.cream)
                                Spacer()
                                Text(RPGFormat.xp(qs.reduce(0) { $0 + s.questXP($1) })).font(GameFont.display(13)).foregroundStyle(RPGTheme.gold)
                            }
                        }
                        .tint(RPGTheme.gold)
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "1A1032")))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.black.opacity(0.5), lineWidth: 1.5))
                    }
                }
                .padding(.top, 8)

                Text("You don’t play a character. You build yourself.\nYou don’t build a virtual empire. You build a real one.")
                    .font(GameFont.title(14)).foregroundStyle(RPGTheme.muted).multilineTextAlignment(.center).padding(.top, 6)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private func compact(_ n: Int) -> String { n >= 1000 ? "\(n / 1000)k" : "\(n)" }
}

// MARK: - Зал рангов

struct RanksView: View {
    @EnvironmentObject private var store: RPGStore
    let back: () -> Void

    var body: some View {
        let current = store.state.playerRank().rank.id
        let list = RPGData.personRanks
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                ScreenHeader(title: "Зал рангов", back: back)
                Text("Твоя жизнь — твоя игра. Прокачивай себя к легенде.")
                    .font(GameFont.title(16)).foregroundStyle(RPGTheme.gold).multilineTextAlignment(.center)
                ForEach(Array(list.enumerated()), id: \.offset) { i, r in
                    let info = RPGData.rankInfo[r.id]
                    let next: RankDef? = i + 1 < list.count ? list[i + 1] : nil
                    OrnatePanel {
                        HStack(spacing: 14) {
                            RankShield(id: r.id, size: 58)
                            VStack(alignment: .leading, spacing: 3) {
                                GameLabel(text: r.name, size: 19, color: RPGTheme.rankAccent(r.id))
                                Text("\(RPGFormat.xp(r.min))\(next.map { "–" + RPGFormat.xp($0.min - 1) } ?? "+") XP").font(GameFont.display(12)).foregroundStyle(RPGTheme.muted)
                            }
                            Spacer()
                            if r.id == current {
                                Text("ТЫ ЗДЕСЬ").font(GameFont.display(10)).foregroundStyle(.white)
                                    .padding(.horizontal, 8).padding(.vertical, 5)
                                    .background(Capsule().fill(RPGTheme.xpGradient))
                                    .overlay(Capsule().strokeBorder(RPGTheme.goldGradient, lineWidth: 1))
                            }
                        }
                        if let info {
                            Text("Цель: \(info.goal)").font(GameFont.body(14, .heavy)).foregroundStyle(RPGTheme.rankAccent(r.id))
                            VStack(alignment: .leading, spacing: 3) {
                                ForEach(info.needs, id: \.self) { n in
                                    HStack(alignment: .top, spacing: 6) {
                                        Image(systemName: "diamond.fill").font(.system(size: 7)).foregroundStyle(RPGTheme.gold).padding(.top, 5)
                                        Text(n).font(GameFont.body(13, .medium)).foregroundStyle(RPGTheme.cream)
                                    }
                                }
                            }
                            Text(info.motto).font(GameFont.title(13)).foregroundStyle(RPGTheme.muted)
                        }
                    }
                    .shadow(color: r.id == current ? RPGTheme.violet.opacity(0.6) : .clear, radius: 14)
                }
                OrnatePanel(title: "Как получать XP") {
                    ForEach(RPGData.xpTiers) { t in
                        HStack {
                            Text(t.label).font(GameFont.body(13, .semibold)).foregroundStyle(RPGTheme.cream)
                            Spacer()
                            Text("+\(RPGFormat.xp(t.min))–\(RPGFormat.xp(t.max))").font(GameFont.display(12)).foregroundStyle(RPGTheme.gold)
                        }
                        .padding(.vertical, 2)
                    }
                    Text("Свои критерии и веса можно создавать — они входят в Total XP, но не в Verified XP. Verified XP подтверждается сертификатами, GitHub, публикациями, дипломами, ссылками и портфолио.")
                        .font(GameFont.body(12, .medium)).foregroundStyle(RPGTheme.muted)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Настройки

struct SettingsPanel: View {
    @EnvironmentObject private var store: RPGStore
    @State private var name = ""
    @State private var age = ""
    @State private var location = ""
    @State private var mode: GameMode = .life
    @State private var avatar = "AvatarLeopard"
    @State private var calm = false
    @State private var parent = false
    @State private var haptics = true
    @State private var importing = false
    @State private var confirmReset = false
    @State private var exportURL: URL?

    private struct AvatarChoice: Identifiable { let id: String; let title: String }
    private let avatars = [AvatarChoice(id: "AvatarLeopard", title: "Барс"), AvatarChoice(id: "AvatarGirl", title: "Девочка"), AvatarChoice(id: "AvatarBoy", title: "Мальчик")]

    var body: some View {
        OrnatePanel(title: "Настройки", onClose: { store.panel = nil }) {
            HStack(spacing: 10) {
                ForEach(avatars) { a in
                    Button { avatar = a.id } label: {
                        VStack(spacing: 6) {
                            Image(a.id).resizable().scaledToFill()
                                .frame(width: 78, height: 78)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(avatar == a.id ? AnyShapeStyle(RPGTheme.goldGradient) : AnyShapeStyle(RPGTheme.edgeDark), lineWidth: avatar == a.id ? 4 : 2))
                                .shadow(color: avatar == a.id ? RPGTheme.gold.opacity(0.6) : .clear, radius: 8)
                            HStack(spacing: 6) {
                                Text(a.title).font(GameFont.title(14)).foregroundStyle(RPGTheme.cream)
                                CheckStone(on: avatar == a.id)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
            }

            GameField(title: "Имя", text: $name)
            HStack(spacing: 10) {
                GameField(title: "Возраст", text: $age, keyboard: .numberPad)
                GameField(title: "Город", text: $location)
            }
            Text("Режим").font(GameFont.body(13, .bold)).foregroundStyle(RPGTheme.muted)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(GameMode.allCases) { m in
                    Button { mode = m } label: { StoneChip(text: "\(m.emoji) \(m.label.replacingOccurrences(of: " MODE", with: ""))", selected: mode == m).frame(maxWidth: .infinity) }
                        .buttonStyle(.plain)
                }
            }
            GameToggle(title: "Спокойный экран", icon: "leaf.fill", isOn: $calm)
            GameToggle(title: "Подтверждение родителем", icon: "person.2.fill", isOn: $parent)
            GameToggle(title: "Вибрация", icon: "iphone.radiowaves.left.and.right", isOn: $haptics)

            Button("Сохранить") {
                store.setAvatar(avatar)
                store.setHaptics(haptics)
                store.updateProfile(name: name.trimmingCharacters(in: .whitespaces), age: Int(age), location: location, mode: mode, calm: calm, parentConfirm: parent)
                store.panel = nil
            }
            .buttonStyle(ChunkyButtonStyle(kind: .gold, size: 22))

            HStack(spacing: 10) {
                if let exportURL {
                    ShareLink(item: exportURL) { Text("Экспорт") }.buttonStyle(ChunkyButtonStyle(kind: .cyan, size: 14))
                }
                Button("Импорт") { importing = true }.buttonStyle(ChunkyButtonStyle(kind: .cyan, size: 14))
                Button("Сброс") { confirmReset = true }.buttonStyle(ChunkyButtonStyle(kind: .red, size: 14))
            }
        }
        .onAppear(perform: load)
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            if case .success(let url) = result {
                store.show(store.importFile(url) ? "Игра загружена" : "Не удалось прочитать файл")
                store.panel = nil
            }
        }
        .confirmationDialog("Стереть игру и начать заново?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Стереть", role: .destructive) { store.panel = nil; store.reset() }
        }
    }

    private func load() {
        guard let p = store.state.profile else { return }
        name = p.name
        age = p.age.map { String($0) } ?? ""
        location = p.location
        mode = p.mode
        avatar = store.avatar
        calm = store.state.settings.calm
        parent = store.state.settings.parentConfirm
        haptics = store.haptics
        exportURL = store.exportFile()
    }
}
