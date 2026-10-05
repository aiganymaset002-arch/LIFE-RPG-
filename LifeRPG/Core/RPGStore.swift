//
//  RPGStore.swift
//  LIFE RPG
//
//  Единое хранилище игры: сохраняет прогресс на устройстве и показывает Level Up / XP / новые маршруты.
//

import Foundation
import Combine

struct LevelUpEvent: Identifiable {
    let id = UUID()
    let ups: [RankUp]
    let xp: Int
    let achievements: [Achievement]
}

struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isXP: Bool
}

struct RerouteEvent: Identifiable {
    let id = UUID()
    let result: RerouteResult
}

@MainActor
final class RPGStore: ObservableObject {
    @Published var state: GameState
    @Published var levelUp: LevelUpEvent?
    @Published var toast: ToastMessage?
    @Published var reroute: RerouteEvent?

    private let fileURL: URL
    private var toastQueue: [ToastMessage] = []
    private var toastTask: Task<Void, Never>?

    init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        fileURL = dir.appendingPathComponent("life-rpg.json")
        if let data = try? Data(contentsOf: fileURL), let decoded = try? JSONDecoder().decode(GameState.self, from: data) {
            state = decoded
        } else {
            state = GameState()
        }
    }

    // MARK: Сохранение

    func saveNow() {
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("LIFE RPG: не удалось сохранить игру — \(error)")
        }
    }

    func exportFile() -> URL? {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        guard let data = try? enc.encode(state) else { return nil }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("life-rpg-\(df.string(from: Date())).json")
        do { try data.write(to: url, options: .atomic) } catch { return nil }
        return url
    }

    func importFile(_ url: URL) -> Bool {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else { return false }
        let iso = JSONDecoder()
        iso.dateDecodingStrategy = .iso8601
        if let s = try? iso.decode(GameState.self, from: data) {
            state = s
        } else if let s = try? JSONDecoder().decode(GameState.self, from: data) {
            state = s
        } else {
            return false
        }
        saveNow()
        return true
    }

    // MARK: Мутации с Level Up

    /// Любое изменение игры проходит здесь: проверка достижений, повышение ранга, сохранение.
    @discardableResult
    func mutate<T>(_ body: (inout GameState) -> T) -> T {
        let before = state.snapshot()
        var s = state
        let result = body(&s)
        let fresh = s.checkAchievements()
        let after = s.snapshot()
        let ups = s.rankUps(from: before, to: after)
        state = s
        saveNow()
        let gained = Swift.max(0, after.playerXP - before.playerXP)
        if !ups.isEmpty {
            levelUp = LevelUpEvent(ups: ups, xp: gained, achievements: fresh)
        } else {
            for a in fresh { show("\(a.icon) Achievement unlocked: \(a.title)") }
        }
        return result
    }

    func show(_ text: String, xp: Bool = false) {
        toastQueue.append(ToastMessage(text: text, isXP: xp))
        if toast == nil { nextToast() }
    }

    private func nextToast() {
        guard !toastQueue.isEmpty else { toast = nil; return }
        toast = toastQueue.removeFirst()
        toastTask?.cancel()
        toastTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_300_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.toast = nil
                self?.nextToast()
            }
        }
    }

    // MARK: Действия

    func complete(_ id: String, proof: String = "") {
        let parent = state.needsParent
        let res = mutate { $0.complete(id, proof: proof, needsParent: parent) }
        if res.locked { show("🔒 Сначала выполни подготовительные квесты") }
        else if res.pending { show("⏳ Отправлено родителю на подтверждение") }
        else if res.ok && levelUp == nil { show("+\(RPGFormat.xp(res.xp)) \(unit)", xp: true) }
    }

    func confirm(_ id: String) {
        let res = mutate { $0.confirm(id) }
        if res.ok && levelUp == nil { show("+\(RPGFormat.xp(res.xp)) \(unit)", xp: true) }
    }

    func fail(_ id: String) {
        if let r = mutate({ $0.fail(id) }) { reroute = RerouteEvent(result: r) }
    }

    func undo(_ id: String) { mutate { $0.undo(id) } }

    func setProof(_ id: String, _ proof: String) {
        mutate { $0.setProof(id, proof) }
        show("Доказательство сохранено")
    }

    func deleteQuest(_ id: String) { mutate { $0.deleteQuest(id) } }

    func addResult(title: String, tier: String?, custom: Bool, awards: [XPAward], proof: String) {
        let q = mutate { $0.addResult(title: title, tier: tier, custom: custom, awards: awards, proof: proof) }
        if levelUp == nil { show("+\(RPGFormat.xp(state.questXP(q))) \(unit)", xp: true) }
    }

    func addQuest(_ quest: Quest, to roadmapId: String) {
        mutate { (s: inout GameState) -> Void in
            s.quests.append(quest)
            guard let r = s.roadmaps.firstIndex(where: { $0.id == roadmapId }) else { return }
            let qs = s.roadmapQuests(s.roadmaps[r])
            if let next = qs.first(where: { ($0.day ?? 0) > (quest.day ?? 0) }), let pos = s.roadmaps[r].questIds.firstIndex(of: next.id) {
                s.roadmaps[r].questIds.insert(quest.id, at: pos)
            } else {
                s.roadmaps[r].questIds.append(quest.id)
            }
        }
        show("＋ Квест добавлен в карту")
    }

    func addSuggestion(_ title: String, worldId: String, cat: String) {
        let kids = state.world(worldId)?.type == .kids
        mutate { $0.quests.append(Quest(title: title, tier: kids ? "kid_mid" : "project", awards: [XPAward(worldId: worldId, cat: cat, xp: kids ? 100 : 800)])) }
        show("＋ Квест добавлен")
    }

    @discardableResult
    func apply(_ plan: GamePlan, worldId: String?) -> Roadmap {
        let rm = mutate { (s: inout GameState) -> Roadmap in
            var wid = worldId ?? ""
            if worldId == nil || s.world(wid) == nil {
                wid = s.addWorld(name: plan.worldName ?? plan.worldType.label, type: plan.worldType).id
            }
            return GameMaster.apply(plan, to: &s, worldId: wid)
        }
        show("▶ Игра началась! День 1")
        return rm
    }

    func deleteRoadmap(_ id: String) { mutate { $0.deleteRoadmap(id) } }

    func addWorld(name: String, type: WorldType) {
        mutate { $0.addWorld(name: name, type: type) }
        show("🪐 Мир «\(name)» создан")
    }

    func deleteWorld(_ id: String) { mutate { $0.deleteWorld(id) } }

    /// Онбординг: создаёт игрока, миры и первую карту из мечты.
    @discardableResult
    func startGame(name: String, age: Int?, location: String, mode: GameMode, dream: String, companyName: String) -> Roadmap {
        var s = GameState()
        s.profile = Profile(name: name.isEmpty ? "Игрок" : name, age: age, location: location, mode: mode, dream: dream, createdAt: Date(), demo: false)
        s.settings = GameSettings(calm: mode == .sen, parentConfirm: mode == .kids)
        let personal = s.addWorld(name: mode.isChild ? "Мой мир" : "Personal World", type: mode.isChild ? .kids : .personal)
        var main = personal
        if mode.worldType != personal.type {
            main = s.addWorld(name: mode == .company ? (companyName.isEmpty ? "Моя компания" : companyName) : mode.worldType.label, type: mode.worldType)
        }
        var text = dream
        if text.isEmpty {
            switch mode {
            case .company: text = "Запустить и масштабировать \(companyName.isEmpty ? "компанию" : companyName)"
            case .kids: text = "Большое приключение"
            case .sen: text = "Маленькие шаги"
            default: text = "Стать лучшей версией себя за 90 дней"
            }
        }
        let plan = GameMaster.generate(text, mode: mode)
        let rm = GameMaster.apply(plan, to: &s, worldId: main.id)
        state = s
        saveNow()
        show("✨ Игра создана: \(plan.quests.count) квестов, \(plan.bosses) Boss Battles")
        return rm
    }

    func loadDemo() {
        state = RPGSeed.demo()
        saveNow()
        show("Демо: Айганым · Rank A · 31 750 XP")
    }

    func reset() {
        state = GameState()
        saveNow()
    }

    func updateProfile(name: String, age: Int?, location: String, mode: GameMode, calm: Bool, parentConfirm: Bool) {
        guard var p = state.profile else { return }
        p.name = name.isEmpty ? p.name : name
        p.age = age
        p.location = location
        p.mode = mode
        state.profile = p
        state.settings = GameSettings(calm: calm, parentConfirm: parentConfirm)
        saveNow()
        show("Сохранено")
    }

    // MARK: Удобства для экранов

    var isKids: Bool { state.profile?.mode == .kids }
    var isSen: Bool { state.profile?.mode == .sen }
    var calm: Bool { state.settings.calm || isSen }
    var unit: String { (state.profile?.mode.isChild ?? false) ? "⭐" : "XP" }
}
