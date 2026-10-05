//
//  GameMaster.swift
//  LIFE RPG
//
//  AI Game Master: мечта обычным языком → игра (главный квест, фазы, квесты по дням, Boss Battles, XP, запасные маршруты).
//  Работает офлайн на правилах и шаблонах; generate() возвращает простой план — сюда можно подключить LLM.
//

import Foundation

struct PlanQuest: Hashable {
    var title: String
    var tier: String
    var xp: Int
    var cat: String
    var boss: Bool
    var onFail: FailPlan?
    var phase: String
    var kind: String
    var day: Int
}

struct GamePlan {
    var title: String
    var dream: String
    var days: Int
    var kinds: [String]
    var worldType: WorldType
    var worldName: String?
    var quests: [PlanQuest]
    var totalXP: Int { quests.reduce(0) { $0 + $1.xp } }
    var bosses: Int { quests.filter(\.boss).count }
}

private struct QSpec {
    let title: String
    let tier: String
    let xp: Int
    let cat: String
    var boss = false
    var onFail: FailPlan?
}

private struct Phase {
    let name: String
    let quests: [QSpec]
}

private struct Template {
    let kind: String
    let worldType: WorldType
    let title: String
    let days: Int
    let phases: [Phase]
}

private struct Context {
    let text: String
    let name: String?
    let score: String?
    let uni: String?
    let role: String?
}

private func q(_ title: String, _ tier: String, _ xp: Int, _ cat: String, boss: Bool = false, onFail: FailPlan? = nil) -> QSpec {
    QSpec(title: title, tier: tier, xp: xp, cat: cat, boss: boss, onFail: onFail)
}

private func f(_ title: String, _ xp: Int, tier: String, cat: String? = nil, boss: Bool = false) -> FailPlanQuest {
    FailPlanQuest(title: title, xp: xp, cat: cat, tier: tier, boss: boss)
}

enum GameMaster {
    // MARK: Разбор текста

    private static func groups(_ pattern: String, in text: String, options: NSRegularExpression.Options = [.caseInsensitive]) -> (range: NSRange, groups: [String])? {
        guard let re = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
        let ns = text as NSString
        guard let m = re.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)) else { return nil }
        var out: [String] = []
        for i in 0..<m.numberOfRanges {
            let r = m.range(at: i)
            out.append(r.location == NSNotFound ? "" : ns.substring(with: r))
        }
        return (m.range, out)
    }

    private static func matches(_ pattern: String, _ text: String) -> Bool {
        groups(pattern, in: text) != nil
    }

    private static let numberWords: [String: Int] = ["один": 1, "одну": 1, "одного": 1, "два": 2, "две": 2, "три": 3, "четыре": 4, "пять": 5, "шесть": 6, "семь": 7, "восемь": 8, "девять": 9, "десять": 10, "двенадцать": 12]

    /// «за 90 дней», «6 месяцев», «через три года», «полгода». «Мне 15 лет» — это возраст, а не срок.
    static func parseDuration(_ text: String) -> Int? {
        let t = text.lowercased()
        if t.contains("полгода") || t.contains("пол года") || t.contains("half a year") { return 180 }
        let num = "(\\d+|" + numberWords.keys.sorted { $0.count > $1.count }.joined(separator: "|") + ")"
        let units: [(String, Int)] = [
            (num + "\\s*(дн|день|дня|day)", 1),
            (num + "\\s*(недел|week)", 7),
            (num + "\\s*(месяц|мес\\b|month)", 30),
            (num + "\\s*(год|лет|year)", 365),
        ]
        func toN(_ s: String) -> Int? { Int(s) ?? numberWords[s] }
        for (p, mul) in units {
            if let m = groups("(за|через|в течение|на|in|within)\\s+" + p, in: t), let n = toN(m.groups[2]) { return Swift.max(7, n * mul) }
        }
        let ns = t as NSString
        for (p, mul) in units {
            if let m = groups(p, in: t), let n = toN(m.groups[1]) {
                let before = ns.substring(to: m.range.location)
                if before.range(of: "мне\\s*$", options: .regularExpression) != nil { continue }
                return Swift.max(7, n * mul)
            }
        }
        if matches("\\bгод\\b|year", t) { return 365 }
        return nil
    }

    static func parseName(_ text: String) -> String? {
        if let m = groups("«([^»]+)»|\"([^\"]+)\"|“([^”]+)”", in: text) {
            let v = m.groups.dropFirst().first { !$0.isEmpty } ?? ""
            return v.trimmingCharacters(in: .whitespaces)
        }
        let p = "(?:запустить|создать|построить|масштабировать|развить|компани[юяи]|бренд|launch|build)\\s+(?:и\\s+(?:масштабировать|развить)\\s+)?([A-ZА-ЯЁ][\\w&.\\-]*(?:\\s+[A-ZА-ЯЁ][\\w&.\\-]*){0,3})"
        if let m = groups(p, in: text, options: []) { return m.groups[1].trimmingCharacters(in: .whitespaces) }
        return nil
    }

    static func detectKinds(_ text: String, mode: GameMode) -> [String] {
        let t = text.lowercased()
        if mode == .sen { return ["sen"] }
        if mode == .kids { return ["kids"] }
        var kinds: [String] = []
        let uni = "поступ|университет|универ|harvard|mit\\b|stanford|oxford|cambridge|college|колледж"
        if matches("ielts|toefl|английск|english", t) && !matches("поступ|универ|harvard|mit\\b", t) { kinds.append("ielts") }
        if matches(uni, t) { kinds.append("university") }
        if matches("компани|стартап|startup|бизнес|business|бренд|fashion|house|магазин|запуст|масштаб|company", t) { kinds.append("company") }
        if matches("developer|разработчик|программист|software|engineer|инженер|\\bai\\b|\\bии\\b|frontend|backend|coding", t) { kinds.append("developer") }
        if matches("исследова|research|публикац|статью|статьи|учён|ученый|phd|наук", t) && !kinds.contains("university") { kinds.append("academic") }
        if kinds.isEmpty {
            switch mode {
            case .company: kinds = ["company"]
            case .academic: kinds = ["academic"]
            case .career: kinds = ["developer"]
            default: kinds = ["generic"]
            }
        }
        return kinds
    }

    // MARK: Генерация

    /// Мечта → план игры (без изменения состояния).
    static func generate(_ text: String, mode: GameMode = .life) -> GamePlan {
        var uni = groups("\\b(harvard|mit|stanford|oxford|cambridge|nus|kaist|nazarbayev university)\\b", in: text)?.groups[1]
        if let u = uni {
            let capitalized: String = u.prefix(1).uppercased() + String(u.dropFirst())
            uni = u.count <= 4 ? u.uppercased() : capitalized
        }
        let ctx = Context(
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            name: parseName(text),
            score: groups("ielts\\s*(\\d(?:[.,]\\d)?)", in: text)?.groups[1].replacingOccurrences(of: ",", with: "."),
            uni: uni,
            role: groups("(ai/software engineer|software engineer|ai engineer|data scientist|frontend|backend|mobile developer)", in: text)?.groups[1]
        )
        let kinds = detectKinds(text, mode: mode)
        let parts = kinds.map { template($0, ctx) }
        let days = parseDuration(text) ?? (parts.map(\.days).max() ?? 90)
        var quests: [PlanQuest] = []
        for part in parts {
            let n = Double(part.phases.count)
            for (pi, ph) in part.phases.enumerated() {
                for (qi, s) in ph.quests.enumerated() {
                    let r = (Double(pi) + Double(qi + 1) / (Double(ph.quests.count) + 0.0001)) / n
                    let day = Swift.max(1, Swift.min(days, Int((r * Double(days)).rounded())))
                    quests.append(PlanQuest(title: s.title, tier: s.tier, xp: s.xp, cat: s.cat, boss: s.boss, onFail: s.onFail, phase: ph.name, kind: part.kind, day: day))
                }
            }
        }
        // Стабильная сортировка по дню.
        quests = quests.enumerated().sorted { a, b in a.element.day != b.element.day ? a.element.day < b.element.day : a.offset < b.offset }.map(\.element)
        let title = parts.count > 1 ? parts.map(\.title).joined(separator: " + ") : (parts.first?.title ?? ctx.text)
        return GamePlan(title: title, dream: ctx.text, days: days, kinds: kinds, worldType: parts.first?.worldType ?? .personal, worldName: ctx.name, quests: quests)
    }

    private static let mirror: [String: String] = ["product": "business", "team": "business", "finance": "business", "sales": "business", "technology": "tech", "rnd": "science", "brand": "media", "international": "business", "impact": "growth"]

    static func fitCategory(_ world: World, _ cat: String) -> String {
        let cats = world.type.categories
        if cats.contains(cat) { return cat }
        if let m = mirror[cat], cats.contains(m) { return m }
        return cats.first ?? cat
    }

    /// Применить план: создать карту и квесты. Квесты в рабочем мире дают XP и личному миру (связанные миры).
    @discardableResult
    static func apply(_ plan: GamePlan, to state: inout GameState, worldId: String, startDate: Date = Date(), linkPersonal: Bool = true) -> Roadmap {
        let world = state.world(worldId) ?? state.worlds[0]
        let personal = state.worlds.first { $0.type == .personal || $0.type == .kids }
        var rm = Roadmap(id: RPGID.make("rm"), title: plan.title, dream: plan.dream, worldId: world.id, days: plan.days, startDate: startDate, questIds: [], pointA: nil, pointB: nil)
        var prepByPhase: [String: [Quest]] = [:]
        for s in plan.quests {
            var awards = [XPAward(worldId: world.id, cat: fitCategory(world, s.cat), xp: s.xp)]
            if linkPersonal, let p = personal, p.id != world.id {
                awards.append(XPAward(worldId: p.id, cat: fitCategory(p, s.cat), xp: Int((Double(s.xp) * 0.5).rounded())))
            }
            let key = s.kind + "|" + s.phase
            let prep = prepByPhase[key] ?? []
            let quest = Quest(title: s.title, tier: s.tier, awards: awards, boss: s.boss,
                              requires: s.boss ? prep.filter { !$0.boss }.map(\.id) : [],
                              onFail: s.onFail, roadmapId: rm.id, day: s.day, phase: s.phase)
            prepByPhase[key] = prep + [quest]
            state.quests.append(quest)
            rm.questIds.append(quest.id)
        }
        state.roadmaps.append(rm)
        return rm
    }

    // MARK: Шаблоны

    private static func template(_ kind: String, _ c: Context) -> Template {
        switch kind {
        case "company": return company(c)
        case "ielts": return ielts(c)
        case "university": return university(c)
        case "developer": return developer(c)
        case "academic": return academic()
        case "kids": return kids()
        case "sen": return sen()
        default: return generic(c)
        }
    }

    private static func company(_ c: Context) -> Template {
        Template(kind: "company", worldType: .company, title: "Запустить и масштабировать \(c.name ?? "компанию")", days: 90, phases: [
            Phase(name: "IDEA → VALIDATION", quests: [
                q("Сформулировать миссию, ценности и ценностное предложение", "task", 100, "product"),
                q("Провести 10 интервью с потенциальными клиентами", "cert", 300, "sales"),
                q("Зарегистрировать компанию", "cert", 300, "finance"),
            ]),
            Phase(name: "MVP", quests: [
                q("Создать сайт", "cert", 300, "product"),
                q("Сделать MVP / первую коллекцию", "project", 500, "product"),
                q("Опубликовать первую коллекцию / продукт", "project", 500, "brand"),
                q("Публичный запуск (Launch Day)", "project", 1000, "brand", boss: true),
            ]),
            Phase(name: "FIRST CUSTOMERS → REVENUE", quests: [
                q("Получить первых 10 клиентов", "project", 700, "sales"),
                q("Найти партнёра", "project", 800, "sales"),
                q("Первая выручка", "project", 800, "finance"),
                q("Первый питч инвестору", "project", 1500, "finance", boss: true, onFail: FailPlan(route: "Bootstrap Strategy", quests: [
                    f("Sales-квест 1: закрыть 5 сделок", 500, tier: "project", cat: "sales"),
                    f("Sales-квест 2: запустить предзаказы", 500, tier: "project", cat: "sales"),
                    f("Sales-квест 3: выйти в операционный ноль", 500, tier: "project", cat: "finance"),
                ])),
            ]),
            Phase(name: "TEAM → GROWTH", quests: [
                q("Нанять первого сотрудника", "internship", 1000, "team"),
                q("Провести мероприятие", "internship", 1000, "brand"),
                q("Подать заявку на патент / защиту дизайна", "project", 800, "rnd"),
                q("100 платных заказов", "internship", 1500, "sales"),
            ]),
            Phase(name: "EXPANSION → INTERNATIONAL", quests: [
                q("Выйти в новый город", "internship", 1500, "international"),
                q("Выйти на международный рынок", "intl", 2500, "international"),
                q("Первые $10,000 выручки", "intl", 3000, "finance", boss: true, onFail: FailPlan(route: "Revenue Sprint", quests: [
                    f("Пересобрать оффер и цены", 300, tier: "cert", cat: "sales"),
                    f("Запустить 2 новых канала продаж", 800, tier: "project", cat: "sales"),
                    f("Повторная попытка: $10,000 выручки", 3000, tier: "intl", cat: "finance", boss: true),
                ])),
            ]),
        ])
    }

    private static func ielts(_ c: Context) -> Template {
        let s = c.score ?? "7.0"
        return Template(kind: "ielts", worldType: .personal, title: "IELTS \(s)", days: 180, phases: [
            Phase(name: "Диагностика", quests: [
                q("Пройти диагностический тест IELTS", "task", 80, "languages"),
                q("Составить план по 4 секциям", "task", 60, "languages"),
            ]),
            Phase(name: "База", quests: [
                q("Выучить 500 академических слов", "task", 100, "languages"),
                q("Listening: 20 тестов", "cert", 250, "languages"),
                q("Reading: 20 тестов", "cert", 250, "languages"),
            ]),
            Phase(name: "Writing & Speaking", quests: [
                q("Writing Task 1 + 2: 15 эссе с проверкой", "cert", 400, "languages"),
                q("Speaking: 10 сессий с партнёром/тьютором", "cert", 300, "languages"),
                q("Пробный экзамен — 6.0+", "cert", 400, "languages", boss: true),
            ]),
            Phase(name: "Финиш", quests: [
                q("Пробный экзамен — 6.5+", "cert", 500, "languages"),
                q("Неделя экзаменационного режима", "task", 100, "languages"),
                q("IELTS EXAM — \(s)", "intl", 2000, "languages", boss: true, onFail: FailPlan(route: "Retake Route", quests: [
                    f("Разбор результатов по секциям", 80, tier: "task"),
                    f("Интенсив по слабой секции (4 недели)", 400, tier: "cert"),
                    f("Пересдача IELTS — \(s)", 2000, tier: "intl", boss: true),
                ])),
            ]),
        ])
    }

    private static func university(_ c: Context) -> Template {
        let uni = c.uni ?? "топовый университет"
        return Template(kind: "university", worldType: .academic, title: "Поступить в \(uni)", days: 365, phases: [
            Phase(name: "Стратегия", quests: [
                q("Составить список вузов и требований", "task", 80, "education"),
                q("Найти ментора/выпускника вуза", "task", 100, "education"),
            ]),
            Phase(name: "Академический профиль", quests: [
                q("Подготовка к SAT/ACT — пробник 1400+", "cert", 400, "education"),
                q("Олимпиада / конкурс — призовое место", "intl", 2000, "education"),
                q("Онлайн-курс топ-вуза с сертификатом (MIT OCW, CS50)", "cert", 300, "education"),
            ]),
            Phase(name: "Исследования и проекты", quests: [
                q("Исследовательский проект с ментором", "project", 1000, "science"),
                q("Подать статью в журнал", "publication", 1500, "science"),
                q("Лидерство / волонтёрский проект", "project", 700, "growth"),
            ]),
            Phase(name: "Экзамены", quests: [
                q("IELTS 7.5+ / TOEFL 105+", "intl", 2000, "languages", boss: true),
                q("SAT 1500+", "intl", 2000, "education", boss: true),
            ]),
            Phase(name: "Заявка", quests: [
                q("Мотивационное эссе — 5 черновиков", "cert", 400, "education"),
                q("Получить рекомендательные письма", "cert", 300, "education"),
                q("UNIVERSITY APPLICATION", "project", 1500, "education", boss: true),
                q("Поступление в \(c.uni ?? "университет мечты")", "university", 8000, "education", boss: true, onFail: FailPlan(route: "Gap Year Route", quests: [
                    f("Поступить в сильный вуз из резервного списка", 5000, tier: "university"),
                    f("Год исследований/стажировки для усиления профиля", 1500, tier: "internship", cat: "career"),
                    f("Повторная подача / перевод", 8000, tier: "university", boss: true),
                ])),
            ]),
        ])
    }

    private static func developer(_ c: Context) -> Template {
        Template(kind: "developer", worldType: .developer, title: c.role.map { "Стать \($0)" } ?? "Стать сильным software engineer", days: 180, phases: [
            Phase(name: "Основы", quests: [
                q("Python: основы + 50 задач", "task", 100, "tech"),
                q("Git & GitHub: первый репозиторий", "task", 80, "tech"),
                q("CS50 / курс по алгоритмам с сертификатом", "cert", 400, "education"),
            ]),
            Phase(name: "Алгоритмы и проекты", quests: [
                q("100 алгоритмических задач (LeetCode)", "cert", 500, "tech"),
                q("Pet-проект на GitHub", "project", 700, "tech"),
                q("Задеплоить рабочее приложение", "project", 1000, "tech"),
            ]),
            Phase(name: "Реальный мир", quests: [
                q("Первый open-source pull request", "cert", 500, "tech"),
                q("100 реальных пользователей продукта", "project", 1500, "business"),
                q("APP STORE / PRODUCTION RELEASE", "project", 1500, "tech", boss: true),
            ]),
            Phase(name: "Карьера", quests: [
                q("Резюме + LinkedIn + портфолио", "task", 100, "career"),
                q("Пройти техническое собеседование", "cert", 500, "career", boss: true),
                q("Стажировка / первая работа Junior", "internship", 2000, "career", boss: true, onFail: FailPlan(route: "Freelance Route", quests: [
                    f("3 фриланс-заказа с отзывами", 800, tier: "project", cat: "career"),
                    f("Ещё 2 проекта в портфолио", 700, tier: "project", cat: "tech"),
                    f("Повторная попытка: стажировка", 2000, tier: "internship", cat: "career", boss: true),
                ])),
            ]),
        ])
    }

    private static func academic() -> Template {
        Template(kind: "academic", worldType: .research, title: "Опубликовать исследование", days: 240, phases: [
            Phase(name: "Idea", quests: [q("Сформулировать исследовательский вопрос", "task", 100, "science"), q("Найти научного руководителя", "cert", 300, "science")]),
            Phase(name: "Literature Review", quests: [q("Прочитать и разобрать 30 статей", "cert", 400, "science"), q("Написать обзор литературы", "cert", 500, "science")]),
            Phase(name: "Experiment", quests: [q("Дизайн эксперимента / методология", "cert", 300, "science"), q("Провести эксперимент и собрать данные", "project", 1000, "science")]),
            Phase(name: "Paper", quests: [q("Написать черновик статьи", "project", 800, "science"), q("Получить фидбэк от 2 экспертов", "cert", 300, "science")]),
            Phase(name: "Submission → Review", quests: [q("Подать статью в журнал (Scopus/WoS)", "project", 700, "science", boss: true), q("Ответить рецензентам (revision)", "cert", 500, "science")]),
            Phase(name: "Publication", quests: [
                q("PUBLICATION — статья опубликована", "publication", 2500, "science", boss: true, onFail: FailPlan(route: "Resubmission Route", quests: [
                    f("Учесть замечания рецензентов", 300, tier: "cert"),
                    f("Выбрать другой подходящий журнал", 80, tier: "task"),
                    f("Повторная подача и публикация", 2500, tier: "publication", boss: true),
                ])),
                q("Выступить на конференции", "intl", 2000, "media"),
            ]),
        ])
    }

    private static func kids() -> Template {
        Template(kind: "kids", worldType: .kids, title: "Большое приключение", days: 30, phases: [
            Phase(name: "🌱 Starter", quests: [q("Прочитать 10 страниц книги", "kid_small", 30, "reading"), q("Заправить кровать сам(а)", "kid_small", 20, "independence"), q("10 минут зарядки", "kid_small", 30, "sport")]),
            Phase(name: "🧭 Explorer", quests: [q("Узнать 5 фактов о космосе", "kid_small", 40, "study"), q("Нарисовать своё изобретение", "kid_mid", 60, "creativity"), q("Прочитать целую книгу", "kid_mid", 100, "reading")]),
            Phase(name: "🛠 Builder", quests: [q("Собрать модель / поделку", "kid_mid", 100, "projects"), q("Неделя зарядки каждый день", "kid_mid", 120, "sport"), q("Помочь приготовить ужин", "kid_small", 40, "independence")]),
            Phase(name: "🚀 Inventor", quests: [q("Придумать и сделать свой проект", "kid_big", 200, "projects"), q("Выучить стихотворение", "kid_mid", 80, "study")]),
            Phase(name: "🏆 Master", quests: [q("Мини-выставка: показать проект семье", "kid_big", 300, "projects", boss: true)]),
        ])
    }

    private static func sen() -> Template {
        Template(kind: "sen", worldType: .kids, title: "Мои маленькие шаги", days: 28, phases: [
            Phase(name: "☀️ Утро", quests: [q("🪥 Почистить зубы", "kid_small", 20, "independence"), q("👕 Одеться", "kid_small", 20, "independence"), q("🥣 Позавтракать", "kid_small", 20, "independence")]),
            Phase(name: "📘 Учёба", quests: [q("✏️ 1 страница прописи", "kid_small", 30, "study"), q("🔢 5 примеров", "kid_small", 30, "study"), q("📖 Посмотреть книгу с картинками", "kid_small", 30, "reading")]),
            Phase(name: "🎨 Творчество", quests: [q("🖍 Нарисовать рисунок", "kid_small", 30, "creativity"), q("🧩 Собрать пазл", "kid_small", 30, "projects")]),
            Phase(name: "⚽ Движение", quests: [q("🚶 Прогулка 15 минут", "kid_small", 30, "sport"), q("🤸 5 упражнений", "kid_small", 30, "sport")]),
            Phase(name: "⭐ Неделя", quests: [q("⭐ Все шаги недели", "kid_mid", 100, "independence", boss: true)]),
        ])
    }

    private static func generic(_ c: Context) -> Template {
        let title = c.text.count > 70 ? String(c.text.prefix(67)) + "…" : c.text
        return Template(kind: "generic", worldType: .personal, title: title.isEmpty ? "Моя цель" : title, days: 90, phases: [
            Phase(name: "Старт", quests: [q("Определить критерии успеха цели", "task", 80, "growth"), q("Сделать первый маленький шаг", "task", 60, "growth")]),
            Phase(name: "Система", quests: [q("Привычка 14 дней подряд", "cert", 250, "growth"), q("Найти наставника / сообщество", "cert", 200, "growth")]),
            Phase(name: "Результат", quests: [q("Первый подтверждаемый результат", "project", 700, "growth"), q("Показать результат публично", "cert", 300, "media")]),
            Phase(name: "Финал", quests: [q("ГЛАВНОЕ ИСПЫТАНИЕ цели", "project", 1500, "growth", boss: true)]),
        ])
    }
}
