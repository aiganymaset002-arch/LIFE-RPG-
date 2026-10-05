//
//  RPGEngine.swift
//  LIFE RPG
//
//  Игровое ядро: XP, Verified XP, ранги, Boss Battles, перестройка маршрута, достижения.
//

import Foundation

struct RankProgress {
    let rank: RankDef
    let next: RankDef?
    let index: Int
    let progress: Double
    let toNext: Int
}

struct RankSnapshot {
    var playerXP: Int
    var playerRank: String
    var worlds: [String: (xp: Int, rank: String)]
}

struct RankUp: Identifiable {
    let id = UUID()
    let who: String
    let worldId: String?
    let from: String
    let to: String
    let scale: RankScale
}

struct ActionResult {
    var ok: Bool
    var xp: Int = 0
    var pending: Bool = false
    var locked: Bool = false
}

struct RerouteResult {
    let route: String
    let created: [Quest]
}

struct RoadmapProgress {
    let day: Int
    let days: Int
    let timePct: Double
    let done: Int
    let total: Int
    let pct: Double
    let xp: Int
}

struct WeakSpot {
    let cat: String
    let xp: Int
    let rank: String
    let open: [Quest]
    let suggestions: [String]
}

enum RPGEngine {
    static let dayLength: TimeInterval = 86_400

    static func rank(for xp: Int, scale: RankScale) -> RankProgress {
        let list = RPGData.ranks(scale)
        var idx = 0
        for (i, r) in list.enumerated() where xp >= r.min { idx = i }
        let rank = list[idx]
        let next: RankDef? = idx + 1 < list.count ? list[idx + 1] : nil
        var progress = 1.0
        if let next {
            progress = Swift.min(1, Swift.max(0, Double(xp - rank.min) / Double(next.min - rank.min)))
        }
        return RankProgress(rank: rank, next: next, index: idx, progress: progress, toNext: next.map { $0.min - xp } ?? 0)
    }

    static let suggestions: [String: [String]] = [
        "sales": ["Провести 20 звонков/встреч с клиентами", "Закрыть 3 новые сделки", "Запустить реферальную программу"],
        "finance": ["Составить финмодель на 12 месяцев", "Подать заявку на грант", "Выйти в операционный ноль"],
        "team": ["Нанять первого сотрудника", "Описать роли и процессы", "Найти ментора/адвайзера"],
        "brand": ["Опубликовать 10 постов о продукте", "Получить первую публикацию в СМИ", "Выступить на мероприятии"],
        "international": ["Найти зарубежного партнёра", "Перевести продукт на английский", "Первый зарубежный клиент"],
        "product": ["Собрать фидбэк 10 пользователей", "Выпустить новую версию", "Описать roadmap продукта"],
        "technology": ["Автоматизировать ключевой процесс", "Внедрить AI в продукт", "Провести техаудит"],
        "rnd": ["Подать заявку на патент", "Провести эксперимент", "Опубликовать исследование"],
        "impact": ["Измерить социальный эффект", "Запустить проект для людей с ОВЗ", "Партнёрство с фондом"],
        "languages": ["Пройти пробный экзамен", "30 дней практики подряд", "Выступить на иностранном языке"],
        "health": ["Тренировки 3 раза в неделю месяц", "Чек-ап здоровья", "Режим сна 30 дней"],
        "science": ["Написать обзор литературы", "Написать профессору", "Подать тезисы на конференцию"],
        "tech": ["Решить 30 алгоритмических задач", "Задеплоить рабочее приложение", "Сделать PR в open source"],
        "media": ["Выступить публично", "Опубликовать 5 видео", "Дать интервью"],
        "career": ["Подать 10 заявок на стажировку", "Обновить резюме и LinkedIn", "Пройти собеседование"],
        "education": ["Закончить онлайн-курс с сертификатом", "Участвовать в олимпиаде", "Прочитать 3 профильные книги"],
        "business": ["Запустить мини-проект", "Получить первого клиента", "Сделать сайт проекта"],
        "growth": ["Ввести систему планирования", "Вести дневник 30 дней", "Прочитать 2 книги"],
        "life": ["Время с семьёй без телефона", "Новое хобби", "Поездка в новое место"],
    ]
}

extension GameState {
    // MARK: Поиск

    func world(_ id: String) -> World? { worlds.first { $0.id == id } }
    func quest(_ id: String) -> Quest? { quests.first { $0.id == id } }
    func questIndex(_ id: String) -> Int? { quests.firstIndex { $0.id == id } }

    var playerScale: RankScale { (profile?.mode.isChild ?? false) ? .kids : .person }
    var needsParent: Bool { settings.parentConfirm }

    // MARK: XP

    /// Verified XP: результат по стандартной шкале + доказательство. Свои критерии никогда не верифицируются.
    func isVerified(_ q: Quest) -> Bool {
        q.isDone && !q.custom && !q.proof.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func questXP(_ q: Quest, worldId: String? = nil) -> Int {
        q.awards.filter { worldId == nil || $0.worldId == worldId }.reduce(0) { $0 + $1.xp }
    }

    func worldXP(_ worldId: String, verifiedOnly: Bool = false) -> Int {
        quests.filter { verifiedOnly ? isVerified($0) : $0.isDone }.reduce(0) { $0 + questXP($1, worldId: worldId) }
    }

    private var personWorldIds: Set<String> { Set(worlds.filter { $0.type != .company }.map(\.id)) }

    /// XP игрока = все личные миры (компании прокачиваются отдельно).
    func playerXP(verifiedOnly: Bool = false) -> Int {
        let ids = personWorldIds
        return quests.filter { verifiedOnly ? isVerified($0) : $0.isDone }
            .reduce(0) { sum, q in sum + q.awards.filter { ids.contains($0.worldId) }.reduce(0) { $0 + $1.xp } }
    }

    func categoryXP(worldId: String? = nil) -> [String: Int] {
        var ids = personWorldIds
        if let worldId { ids = [worldId] }
        var out: [String: Int] = [:]
        for q in quests where q.isDone {
            for a in q.awards where ids.contains(a.worldId) { out[a.cat, default: 0] += a.xp }
        }
        return out
    }

    func playerRank() -> RankProgress { RPGEngine.rank(for: playerXP(), scale: playerScale) }

    func worldRank(_ w: World) -> RankProgress { RPGEngine.rank(for: worldXP(w.id), scale: w.type.scale) }

    // MARK: Квесты

    func isLocked(_ q: Quest) -> Bool {
        q.requires.contains { rid in
            guard let r = quest(rid) else { return false }
            return !r.isDone && r.status != .failed
        }
    }

    func snapshot() -> RankSnapshot {
        let pxp = playerXP()
        var ws: [String: (xp: Int, rank: String)] = [:]
        for w in worlds {
            let x = worldXP(w.id)
            ws[w.id] = (x, RPGEngine.rank(for: x, scale: w.type.scale).rank.id)
        }
        return RankSnapshot(playerXP: pxp, playerRank: RPGEngine.rank(for: pxp, scale: playerScale).rank.id, worlds: ws)
    }

    func rankUps(from before: RankSnapshot, to after: RankSnapshot) -> [RankUp] {
        var ups: [RankUp] = []
        if before.playerRank != after.playerRank && after.playerXP > before.playerXP {
            ups.append(RankUp(who: profile?.name ?? "Игрок", worldId: nil, from: before.playerRank, to: after.playerRank, scale: playerScale))
        }
        for w in worlds {
            guard let b = before.worlds[w.id], let a = after.worlds[w.id] else { continue }
            if b.rank != a.rank && a.xp > b.xp {
                ups.append(RankUp(who: w.name, worldId: w.id, from: b.rank, to: a.rank, scale: w.type.scale))
            }
        }
        return ups
    }

    mutating func addLog(_ text: String, xp: Int = 0) {
        log.insert(LogEntry(id: RPGID.make("log"), at: Date(), text: text, xp: xp), at: 0)
        if log.count > 200 { log.removeLast(log.count - 200) }
    }

    /// Отметить квест выполненным. В детском режиме с подтверждением → «ждёт родителя».
    @discardableResult
    mutating func complete(_ id: String, proof: String = "", needsParent: Bool = false) -> ActionResult {
        guard let i = questIndex(id), !quests[i].isDone else { return ActionResult(ok: false) }
        if isLocked(quests[i]) { return ActionResult(ok: false, locked: true) }
        if !proof.isEmpty { quests[i].proof = proof }
        if needsParent {
            quests[i].status = .pending
            addLog("Ждёт подтверждения: \(quests[i].title)")
            return ActionResult(ok: true, pending: true)
        }
        quests[i].status = .done
        quests[i].doneAt = Date()
        let xp = questXP(quests[i])
        addLog("✓ \(quests[i].title)", xp: xp)
        return ActionResult(ok: true, xp: xp)
    }

    @discardableResult
    mutating func confirm(_ id: String) -> ActionResult {
        guard let i = questIndex(id), quests[i].status == .pending else { return ActionResult(ok: false) }
        quests[i].status = .done
        quests[i].doneAt = Date()
        if quests[i].proof.isEmpty { quests[i].proof = "Подтверждение родителя" }
        let xp = questXP(quests[i])
        addLog("✓ Родитель подтвердил: \(quests[i].title)", xp: xp)
        return ActionResult(ok: true, xp: xp)
    }

    mutating func undo(_ id: String) {
        guard let i = questIndex(id) else { return }
        quests[i].status = .open
        quests[i].doneAt = nil
    }

    mutating func setProof(_ id: String, _ proof: String) {
        guard let i = questIndex(id) else { return }
        quests[i].proof = proof
    }

    /// Провал — не проигрыш: игра перестраивает маршрут.
    mutating func fail(_ id: String) -> RerouteResult? {
        guard let i = questIndex(id), !quests[i].isDone else { return nil }
        quests[i].status = .failed
        let q = quests[i]
        let main = q.mainAward ?? XPAward(worldId: worlds.first?.id ?? "", cat: "growth", xp: 300)
        let plan = q.onFail ?? FailPlan(route: "Новый маршрут", quests: [
            FailPlanQuest(title: "Разобрать, что помешало: «\(q.title)»", xp: 80, cat: nil, tier: "task", boss: false),
            FailPlanQuest(title: "Сделать маленький промежуточный шаг", xp: Swift.max(100, Int(Double(main.xp) * 0.3)), cat: nil, tier: "cert", boss: false),
            FailPlanQuest(title: "Повторная попытка: \(q.title)", xp: main.xp, cat: nil, tier: q.tier, boss: q.boss),
        ])
        var created: [Quest] = []
        for (n, p) in plan.quests.enumerated() {
            var awards: [XPAward] = []
            for (j, a) in q.awards.enumerated() {
                if j == 0 {
                    awards.append(XPAward(worldId: a.worldId, cat: p.cat ?? a.cat, xp: p.xp))
                } else {
                    let ratio = Double(a.xp) / Double(Swift.max(1, main.xp))
                    awards.append(XPAward(worldId: a.worldId, cat: a.cat, xp: Int((Double(p.xp) * ratio).rounded())))
                }
            }
            if awards.isEmpty { awards = [XPAward(worldId: main.worldId, cat: p.cat ?? main.cat, xp: p.xp)] }
            let reqs = p.boss ? created.filter { !$0.boss }.map(\.id) : []
            created.append(Quest(title: p.title, tier: p.tier ?? q.tier, awards: awards, boss: p.boss, requires: reqs,
                                 roadmapId: q.roadmapId, day: q.day.map { $0 + n + 1 }, phase: q.phase, branch: plan.route))
        }
        quests.insert(contentsOf: created, at: i + 1)
        // Квесты, которые ждали проваленный, теперь ждут новую ветку.
        if let last = created.last {
            for k in quests.indices where quests[k].requires.contains(q.id) {
                quests[k].requires = quests[k].requires.filter { $0 != q.id } + [last.id]
            }
        }
        if let rid = q.roadmapId, let r = roadmaps.firstIndex(where: { $0.id == rid }), let pos = roadmaps[r].questIds.firstIndex(of: q.id) {
            roadmaps[r].questIds.insert(contentsOf: created.map(\.id), at: pos + 1)
        }
        addLog("🔄 \(q.title) — маршрут перестроен: \(plan.route)")
        return RerouteResult(route: plan.route, created: created)
    }

    /// Быстро добавить реальный результат (вне карты).
    @discardableResult
    mutating func addResult(title: String, tier: String?, custom: Bool, awards: [XPAward], proof: String) -> Quest {
        let t = RPGData.tier(tier)
        var clean = awards.filter { $0.xp > 0 }
        if !custom, let t, !clean.isEmpty {
            // Каждый мир — не выше максимума тарифа, самая большая награда — не ниже минимума.
            for k in clean.indices { clean[k].xp = Swift.min(t.max, clean[k].xp) }
            if let top = clean.indices.max(by: { clean[$0].xp < clean[$1].xp }) { clean[top].xp = Swift.max(t.min, clean[top].xp) }
        }
        let q = Quest(title: title, tier: custom ? nil : tier, custom: custom, awards: clean, status: .done, proof: proof, doneAt: Date())
        quests.insert(q, at: 0)
        addLog("✓ \(title)", xp: questXP(q))
        return q
    }

    mutating func deleteQuest(_ id: String) {
        quests.removeAll { $0.id == id }
        for r in roadmaps.indices { roadmaps[r].questIds.removeAll { $0 == id } }
        for k in quests.indices { quests[k].requires.removeAll { $0 == id } }
    }

    // MARK: Карты

    func roadmapQuests(_ rm: Roadmap) -> [Quest] { rm.questIds.compactMap { quest($0) } }

    func progress(of rm: Roadmap, now: Date = Date()) -> RoadmapProgress {
        let qs = roadmapQuests(rm)
        let raw = Int(floor(now.timeIntervalSince(rm.startDate) / RPGEngine.dayLength)) + 1
        let day = Swift.max(1, Swift.min(rm.days, raw))
        let done = qs.filter(\.isDone).count
        let total = qs.filter { $0.status != .failed }.count
        let xp = qs.filter(\.isDone).reduce(0) { $0 + questXP($1, worldId: rm.worldId) }
        return RoadmapProgress(day: day, days: rm.days, timePct: Double(day) / Double(rm.days), done: done, total: total,
                               pct: total > 0 ? Double(done) / Double(total) : 0, xp: xp)
    }

    func currentQuest(_ rm: Roadmap) -> Quest? {
        roadmapQuests(rm).first { !$0.isDone && $0.status != .failed && $0.status != .pending && !isLocked($0) }
    }

    /// «Сегодня у меня три маленьких квеста».
    func todayQuests(_ n: Int = 3) -> [Quest] {
        var out: [Quest] = []
        for rm in roadmaps {
            for q in roadmapQuests(rm) where !q.isDone && q.status != .failed && q.status != .pending && !isLocked(q) { out.append(q) }
        }
        out.sort { a, b in
            if a.boss != b.boss { return !a.boss }
            return (a.day ?? 0) < (b.day ?? 0)
        }
        return Array(out.prefix(n))
    }

    mutating func deleteRoadmap(_ id: String) {
        quests.removeAll { $0.roadmapId == id && !$0.isDone }
        for k in quests.indices where quests[k].roadmapId == id { quests[k].roadmapId = nil }
        roadmaps.removeAll { $0.id == id }
    }

    // MARK: Слабое место

    func weakSpot(_ worldId: String) -> WeakSpot? {
        guard let w = world(worldId) else { return nil }
        let xp = categoryXP(worldId: worldId)
        let sorted = w.type.categories.map { (cat: $0, xp: xp[$0] ?? 0) }.sorted { $0.xp < $1.xp }
        guard let weak = sorted.first else { return nil }
        let open = quests.filter { q in
            !q.isDone && q.status != .failed && q.awards.contains { $0.worldId == worldId && $0.cat == weak.cat }
        }
        let generic = RPGEngine.suggestions[weak.cat] ?? [
            "Сделать первый шаг в направлении «\(RPGData.category(weak.cat).label)»",
            "Найти наставника в этом направлении",
            "Получить первый подтверждаемый результат",
        ]
        return WeakSpot(cat: weak.cat, xp: weak.xp, rank: RPGEngine.rank(for: weak.xp, scale: .category).rank.id,
                        open: Array(open.prefix(3)), suggestions: Array(generic.prefix(3)))
    }

    // MARK: Миры

    @discardableResult
    mutating func addWorld(name: String, type: WorldType, emoji: String? = nil, id: String? = nil) -> World {
        let w = World(id: id ?? RPGID.make("w"), name: name, type: type, emoji: emoji ?? type.emoji)
        worlds.append(w)
        return w
    }

    mutating func deleteWorld(_ id: String) {
        worlds.removeAll { $0.id == id }
        for k in quests.indices { quests[k].awards.removeAll { $0.worldId == id } }
        roadmaps.removeAll { $0.worldId == id }
    }

    // MARK: Достижения

    /// Проверяет правила и добавляет новые достижения. Возвращает только что открытые.
    @discardableResult
    mutating func checkAchievements() -> [Achievement] {
        var have = Set(achievements.map(\.id))
        var fresh: [Achievement] = []
        func add(_ id: String, _ icon: String, _ title: String, _ desc: String) {
            guard !have.contains(id) else { return }
            let a = Achievement(id: id, icon: icon, title: title, desc: desc, at: Date())
            achievements.insert(a, at: 0)
            have.insert(id)
            fresh.append(a)
        }
        let done = quests.filter(\.isDone)
        if !done.isEmpty { add("first_quest", "⚔️", "Первый квест", "Выполнен первый реальный результат") }
        if quests.contains(where: { isVerified($0) }) { add("first_verified", "✅", "Подтверждено", "Первый результат с доказательством") }
        if done.contains(where: \.boss) { add("first_boss", "🔥", "Boss повержен", "Пройдена первая Boss Battle") }
        if done.contains(where: { $0.branch != nil }) { add("comeback", "🔄", "Не сдаюсь", "Провал превращён в новый маршрут") }
        if done.contains(where: { $0.tier == "publication" || $0.title.range(of: "публикац|publication|scopus", options: [.regularExpression, .caseInsensitive]) != nil }) {
            add("publication", "📄", "First Research Publication", "Первая научная публикация")
        }
        if done.contains(where: { $0.tier == "intl" || $0.title.range(of: "международ|international|зарубеж", options: [.regularExpression, .caseInsensitive]) != nil }) {
            add("international", "🌐", "First International Step", "Первый выход на международный уровень")
        }
        if done.contains(where: { Set($0.awards.map(\.worldId)).count >= 3 }) { add("multiworld", "🪐", "Связанные миры", "Один результат прокачал несколько миров") }
        if done.count >= 10 { add("ten_quests", "🏅", "10 квестов", "Выполнено 10 квестов") }
        if done.count >= 50 { add("fifty_quests", "🎖", "50 квестов", "Выполнено 50 квестов") }
        for q in done where q.boss { add("boss_\(q.id)", "🏆", "Boss: \(q.title)", "Boss Battle пройдена") }
        for rm in roadmaps {
            let p = progress(of: rm)
            if p.total > 0 && p.done == p.total { add("map_\(rm.id)", "🗺", "Карта пройдена: \(rm.title)", "\(p.done) квестов") }
        }
        let scale = playerScale
        let pr = RPGEngine.rank(for: playerXP(), scale: scale)
        if pr.index >= 1 {
            for i in 1...pr.index {
                let r = RPGData.ranks(scale)[i]
                add("rank_\(scale.rawValue)_\(r.id)", r.icon, "Rank \(r.id) — \(r.name)", "Достигнут порог \(RPGFormat.xp(r.min)) XP")
            }
        }
        return fresh
    }
}
