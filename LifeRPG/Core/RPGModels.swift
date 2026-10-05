//
//  RPGModels.swift
//  LIFE RPG
//
//  Справочные данные (ранги, направления, тарифы XP, режимы, миры) и модели состояния игры.
//  Только Foundation — ядро собирается и проверяется отдельно от интерфейса.
//

import Foundation

// MARK: - Ранги

struct RankDef: Identifiable, Hashable {
    let id: String
    let name: String
    let ru: String
    let min: Int
    let icon: String
    let colorHex: String
}

enum RankScale: String, Codable {
    case person, company, kids, category
}

struct RankInfo {
    let goal: String
    let needs: [String]
    let motto: String
}

// MARK: - Направления

struct CategoryDef: Hashable {
    let id: String
    let label: String
    let emoji: String
    let colorHex: String
}

// MARK: - Тарифы XP

struct XPTier: Identifiable, Hashable {
    let id: String
    let label: String
    let min: Int
    let max: Int
    let def: Int
}

// MARK: - Миры

enum WorldType: String, Codable, CaseIterable, Identifiable {
    case personal, academic, developer, career, research, company, kids

    var id: String { rawValue }

    var label: String {
        switch self {
        case .personal: return "Personal World"
        case .academic: return "Academic World"
        case .developer: return "Developer World"
        case .career: return "Career World"
        case .research: return "Research World"
        case .company: return "Company World"
        case .kids: return "Kids World"
        }
    }

    var emoji: String {
        switch self {
        case .personal: return "👤"
        case .academic: return "🎓"
        case .developer: return "💻"
        case .career: return "💼"
        case .research: return "🔬"
        case .company: return "🏢"
        case .kids: return "🧒"
        }
    }

    var scale: RankScale {
        switch self {
        case .company: return .company
        case .kids: return .kids
        default: return .person
        }
    }

    /// «Дерево развития» мира.
    var categories: [String] {
        switch self {
        case .personal: return ["education", "science", "tech", "business", "languages", "career", "media", "growth", "life", "health"]
        case .academic: return ["education", "science", "languages", "media"]
        case .developer: return ["tech", "career", "business", "education"]
        case .career: return ["career", "tech", "education", "media", "growth"]
        case .research: return ["science", "education", "media", "tech"]
        case .company: return ["product", "team", "finance", "sales", "technology", "rnd", "brand", "international", "impact"]
        case .kids: return ["study", "reading", "sport", "creativity", "projects", "independence"]
        }
    }
}

// MARK: - Режимы

enum GameMode: String, Codable, CaseIterable, Identifiable {
    case life, kids, sen, academic, career, company

    var id: String { rawValue }

    var label: String {
        switch self {
        case .life: return "LIFE MODE"
        case .kids: return "KIDS MODE"
        case .sen: return "SEN MODE"
        case .academic: return "ACADEMIC MODE"
        case .career: return "CAREER MODE"
        case .company: return "COMPANY MODE"
        }
    }

    var emoji: String {
        switch self {
        case .life: return "🧍"
        case .kids: return "🧒"
        case .sen: return "🧩"
        case .academic: return "🎓"
        case .career: return "💼"
        case .company: return "🚀"
        }
    }

    var desc: String {
        switch self {
        case .life: return "Образование, карьера, здоровье, языки, финансы, отношения, путешествия, проекты."
        case .kids: return "Учёба, чтение, спорт, творчество. Не «ты должен», а Level Up! Родитель подтверждает достижения."
        case .sen: return "Для детей и взрослых с РАС и ООП: маленькие визуальные шаги, свой темп, предсказуемые награды, спокойный экран."
        case .academic: return "Олимпиады → университет → исследования → публикации → PhD → лаборатория."
        case .career: return "Выбираешь профессию — система строит дерево от Junior до CTO."
        case .company: return "Компания — RPG-персонаж: IDEA → MVP → REVENUE → INTERNATIONAL → GLOBAL COMPANY."
        }
    }

    var worldType: WorldType {
        switch self {
        case .life: return .personal
        case .kids, .sen: return .kids
        case .academic: return .academic
        case .career: return .developer
        case .company: return .company
        }
    }

    var isChild: Bool { self == .kids || self == .sen }
}

// MARK: - Справочник

enum RPGData {
    /// Шкала игрока (как на карточке профиля: A = 30 000–99 999).
    static let personRanks: [RankDef] = [
        RankDef(id: "E", name: "Novice", ru: "Новичок", min: 0, icon: "🌱", colorHex: "C08A4A"),
        RankDef(id: "D", name: "Explorer", ru: "Исследователь", min: 1_000, icon: "🧭", colorHex: "9AA4B5"),
        RankDef(id: "C", name: "Professional", ru: "Профессионал", min: 5_000, icon: "🌐", colorHex: "E0B04A"),
        RankDef(id: "B", name: "Elite", ru: "Элита", min: 15_000, icon: "💎", colorHex: "A879FF"),
        RankDef(id: "A", name: "Legend", ru: "Легенда", min: 30_000, icon: "👑", colorHex: "FFC845"),
        RankDef(id: "S", name: "World Builder", ru: "Строитель мира", min: 100_000, icon: "🌍", colorHex: "5AA8FF"),
        RankDef(id: "SS", name: "Icon", ru: "Икона", min: 250_000, icon: "⭐", colorHex: "D58BFF"),
        RankDef(id: "SSS", name: "Legacy", ru: "Наследие", min: 500_000, icon: "🏛", colorHex: "FFD76A"),
    ]

    /// Шкала компании: «Company Level C — Growth · 18 450 / 30 000 XP · Next: B — Scale».
    static let companyRanks: [RankDef] = [
        RankDef(id: "E", name: "Idea", ru: "Идея", min: 0, icon: "💡", colorHex: "C08A4A"),
        RankDef(id: "D", name: "MVP", ru: "MVP", min: 2_000, icon: "🛠", colorHex: "9AA4B5"),
        RankDef(id: "C", name: "Growth", ru: "Рост", min: 8_000, icon: "📈", colorHex: "E0B04A"),
        RankDef(id: "B", name: "Scale", ru: "Масштаб", min: 30_000, icon: "🚀", colorHex: "A879FF"),
        RankDef(id: "A", name: "Expansion", ru: "Экспансия", min: 75_000, icon: "🌐", colorHex: "FFC845"),
        RankDef(id: "S", name: "Market Leader", ru: "Лидер рынка", min: 150_000, icon: "🏆", colorHex: "5AA8FF"),
        RankDef(id: "SS", name: "Global Company", ru: "Глобальная компания", min: 300_000, icon: "🌍", colorHex: "D58BFF"),
        RankDef(id: "SSS", name: "Legacy", ru: "Наследие", min: 600_000, icon: "🏛", colorHex: "FFD76A"),
    ]

    /// Детская шкала — карта приключения.
    static let kidsRanks: [RankDef] = [
        RankDef(id: "E", name: "Starter", ru: "Старт", min: 0, icon: "🌱", colorHex: "C08A4A"),
        RankDef(id: "D", name: "Explorer", ru: "Исследователь", min: 300, icon: "🧭", colorHex: "9AA4B5"),
        RankDef(id: "C", name: "Builder", ru: "Строитель", min: 1_000, icon: "🛠", colorHex: "E0B04A"),
        RankDef(id: "B", name: "Inventor", ru: "Изобретатель", min: 2_500, icon: "🚀", colorHex: "A879FF"),
        RankDef(id: "A", name: "Master", ru: "Мастер", min: 5_000, icon: "🏆", colorHex: "FFC845"),
        RankDef(id: "S", name: "Legend", ru: "Легенда", min: 10_000, icon: "🌟", colorHex: "5AA8FF"),
        RankDef(id: "SS", name: "Hero", ru: "Герой", min: 20_000, icon: "🦸", colorHex: "D58BFF"),
        RankDef(id: "SSS", name: "Champion", ru: "Чемпион", min: 40_000, icon: "👑", colorHex: "FFD76A"),
    ]

    /// Ранг отдельного направления (Technology: S, Sales: C …).
    static let categoryRanks: [RankDef] = [
        RankDef(id: "E", name: "E", ru: "", min: 0, icon: "", colorHex: "C08A4A"),
        RankDef(id: "D", name: "D", ru: "", min: 300, icon: "", colorHex: "9AA4B5"),
        RankDef(id: "C", name: "C", ru: "", min: 1_000, icon: "", colorHex: "E0B04A"),
        RankDef(id: "B", name: "B", ru: "", min: 2_500, icon: "", colorHex: "A879FF"),
        RankDef(id: "A", name: "A", ru: "", min: 5_000, icon: "", colorHex: "FFC845"),
        RankDef(id: "S", name: "S", ru: "", min: 12_000, icon: "", colorHex: "5AA8FF"),
        RankDef(id: "SS", name: "SS", ru: "", min: 30_000, icon: "", colorHex: "D58BFF"),
        RankDef(id: "SSS", name: "SSS", ru: "", min: 60_000, icon: "", colorHex: "FFD76A"),
    ]

    static func ranks(_ scale: RankScale) -> [RankDef] {
        switch scale {
        case .person: return personRanks
        case .company: return companyRanks
        case .kids: return kidsRanks
        case .category: return categoryRanks
        }
    }

    static let rankInfo: [String: RankInfo] = [
        "E": RankInfo(goal: "Построить фундамент.", needs: ["Закончить школу", "Первые международные сертификаты", "Английский C1", "Создать первый стартап", "Первые научные статьи", "Первые стажировки", "Первые 10 000 подписчиков"], motto: "Ты начинаешь путь."),
        "D": RankInfo(goal: "Стать сильным студентом и исследователем.", needs: ["Диплом IB", "Поступить в топовый университет", "3 языка C1", "10 научных статей", "Первый доход $10k+/мес", "Первый успешный продукт", "100k подписчиков"], motto: "Исследуй. Учись. Расти."),
        "C": RankInfo(goal: "Выйти на мировой уровень.", needs: ["Учёба в Harvard / топ-вузе", "Исследования международного уровня", "Работа с NASA или похожими организациями", "Доход около $100k+/мес", "Несколько успешных компаний", "1 млн аудитории", "Forbes 30 Under 30"], motto: "Профессионал мирового уровня."),
        "B": RankInfo(goal: "Построить империю и масштабировать влияние.", needs: ["20+ научных публикаций", "5 автоматизированных бизнесов", "Доход десятки миллионов ₸ в месяц", "10 языков, минимум 5 подтверждены", "10 млн подписчиков", "Международные выступления"], motto: "Элита. Твой голос слышат."),
        "A": RankInfo(goal: "Стать легендой в своей сфере.", needs: ["Изобретение мирового уровня", "Работа, влияющая на отрасль", "50 научных публикаций", "10 успешных компаний", "Крупный инвестиционный портфель", "Известность во многих странах"], motto: "Легенды меняют мир."),
        "S": RankInfo(goal: "Создавать то, чем пользуется весь мир.", needs: ["Технологии, которыми пользуется мир", "Сотни миллионов людей знают твой бренд", "Благотворительные проекты мирового масштаба", "Международное признание"], motto: "Ты строишь будущее."),
        "SS": RankInfo(goal: "Вдохновлять поколения.", needs: ["Один из самых известных предпринимателей поколения", "Огромное влияние в технологиях и образовании", "Международные награды", "Личный бренд мирового масштаба"], motto: "Иконы вдохновляют поколения."),
        "SSS": RankInfo(goal: "Оставить наследие, которое живёт без тебя.", needs: ["Компании, технологии и образовательные проекты, работающие десятилетиями", "Научные открытия", "Инвестиции в будущее"], motto: "Наследие живёт вечно."),
    ]

    static let companyStages = ["IDEA", "VALIDATION", "MVP", "FIRST CUSTOMER", "REVENUE", "TEAM", "PRODUCT-MARKET FIT", "EXPANSION", "INTERNATIONAL", "SCALE", "MARKET LEADER", "GLOBAL COMPANY"]

    static let categories: [String: CategoryDef] = {
        let list: [CategoryDef] = [
            CategoryDef(id: "education", label: "Образование", emoji: "🎓", colorHex: "5AA8FF"),
            CategoryDef(id: "science", label: "Наука и исследования", emoji: "🔬", colorHex: "4FD1A5"),
            CategoryDef(id: "tech", label: "Программирование и технологии", emoji: "💻", colorHex: "7C8CFF"),
            CategoryDef(id: "business", label: "Проекты и бизнес", emoji: "🚀", colorHex: "FF8A4C"),
            CategoryDef(id: "languages", label: "Языки", emoji: "🌍", colorHex: "3FC1E0"),
            CategoryDef(id: "career", label: "Карьера и опыт", emoji: "💼", colorHex: "E0B04A"),
            CategoryDef(id: "media", label: "Медиа и выступления", emoji: "🎤", colorHex: "FF5D8F"),
            CategoryDef(id: "growth", label: "Личное развитие", emoji: "🧠", colorHex: "B07CFF"),
            CategoryDef(id: "life", label: "Личная жизнь", emoji: "❤️", colorHex: "FF6B6B"),
            CategoryDef(id: "health", label: "Здоровье и спорт", emoji: "💪", colorHex: "5FD068"),
            CategoryDef(id: "study", label: "Учёба", emoji: "📘", colorHex: "5AA8FF"),
            CategoryDef(id: "reading", label: "Чтение", emoji: "📚", colorHex: "4FD1A5"),
            CategoryDef(id: "sport", label: "Спорт", emoji: "⚽", colorHex: "5FD068"),
            CategoryDef(id: "creativity", label: "Творчество", emoji: "🎨", colorHex: "FF8A4C"),
            CategoryDef(id: "projects", label: "Проекты", emoji: "🛠", colorHex: "7C8CFF"),
            CategoryDef(id: "independence", label: "Самостоятельность", emoji: "🧭", colorHex: "E0B04A"),
            CategoryDef(id: "product", label: "Product", emoji: "📦", colorHex: "7C8CFF"),
            CategoryDef(id: "team", label: "Team", emoji: "👥", colorHex: "4FD1A5"),
            CategoryDef(id: "finance", label: "Finance", emoji: "💰", colorHex: "E0B04A"),
            CategoryDef(id: "sales", label: "Sales", emoji: "📈", colorHex: "FF8A4C"),
            CategoryDef(id: "technology", label: "Technology", emoji: "⚙️", colorHex: "5AA8FF"),
            CategoryDef(id: "rnd", label: "R&D", emoji: "🧪", colorHex: "B07CFF"),
            CategoryDef(id: "brand", label: "Brand", emoji: "✨", colorHex: "FF5D8F"),
            CategoryDef(id: "international", label: "International Expansion", emoji: "🌐", colorHex: "3FC1E0"),
            CategoryDef(id: "impact", label: "Impact", emoji: "🌱", colorHex: "5FD068"),
        ]
        return Dictionary(uniqueKeysWithValues: list.map { ($0.id, $0) })
    }()

    static func category(_ id: String) -> CategoryDef {
        categories[id] ?? CategoryDef(id: id, label: id, emoji: "•", colorHex: "8888AA")
    }

    /// Стандартизированная система XP (Verified XP считается только по ней).
    static let xpTiers: [XPTier] = [
        XPTier(id: "task", label: "Небольшая задача / новый навык", min: 50, max: 100, def: 80),
        XPTier(id: "cert", label: "Сертификат / небольшой проект", min: 200, max: 500, def: 300),
        XPTier(id: "project", label: "Завершённый серьёзный проект", min: 500, max: 1_500, def: 800),
        XPTier(id: "internship", label: "Стажировка", min: 1_000, max: 3_000, def: 1_500),
        XPTier(id: "publication", label: "Научная публикация", min: 1_000, max: 3_000, def: 1_500),
        XPTier(id: "intl", label: "Международное достижение", min: 2_000, max: 5_000, def: 2_500),
        XPTier(id: "university", label: "Поступление в сильный университет", min: 5_000, max: 10_000, def: 7_000),
        XPTier(id: "startup", label: "Запуск успешного продукта/стартапа", min: 5_000, max: 20_000, def: 8_000),
    ]

    /// Детские тарифы — маленькие и предсказуемые.
    static let kidsTiers: [XPTier] = [
        XPTier(id: "kid_small", label: "Маленький квест", min: 20, max: 50, def: 30),
        XPTier(id: "kid_mid", label: "Квест побольше", min: 50, max: 150, def: 100),
        XPTier(id: "kid_big", label: "Большое достижение", min: 150, max: 500, def: 300),
    ]

    static var allTiers: [XPTier] { xpTiers + kidsTiers }

    static func tier(_ id: String?) -> XPTier? {
        guard let id else { return nil }
        return allTiers.first { $0.id == id }
    }

    static let proofTypes = ["Сертификат", "GitHub", "Публикация", "Диплом", "Ссылка", "Портфолио", "Фото/видео", "Подтверждение родителя"]
}

// MARK: - Состояние игры

struct XPAward: Codable, Hashable {
    var worldId: String
    var cat: String
    var xp: Int
}

enum QuestStatus: String, Codable {
    case open, pending, done, failed
}

struct FailPlanQuest: Codable, Hashable {
    var title: String
    var xp: Int
    var cat: String?
    var tier: String?
    var boss: Bool
}

/// Запасной маршрут, который открывается, если квест не получился.
struct FailPlan: Codable, Hashable {
    var route: String
    var quests: [FailPlanQuest]
}

struct Quest: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var tier: String?
    var custom: Bool
    var awards: [XPAward]
    var status: QuestStatus
    var proof: String
    var boss: Bool
    var requires: [String]
    var onFail: FailPlan?
    var roadmapId: String?
    var day: Int?
    var phase: String
    var branch: String?
    var createdAt: Date
    var doneAt: Date?

    init(id: String = RPGID.make("q"), title: String, tier: String? = nil, custom: Bool = false, awards: [XPAward] = [],
         status: QuestStatus = .open, proof: String = "", boss: Bool = false, requires: [String] = [], onFail: FailPlan? = nil,
         roadmapId: String? = nil, day: Int? = nil, phase: String = "", branch: String? = nil, createdAt: Date = Date(), doneAt: Date? = nil) {
        self.id = id
        self.title = title
        self.tier = tier
        self.custom = custom
        self.awards = awards
        self.status = status
        self.proof = proof
        self.boss = boss
        self.requires = requires
        self.onFail = onFail
        self.roadmapId = roadmapId
        self.day = day
        self.phase = phase
        self.branch = branch
        self.createdAt = createdAt
        self.doneAt = doneAt
    }

    var isDone: Bool { status == .done }
    var mainAward: XPAward? { awards.first }
}

struct World: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var type: WorldType
    var emoji: String
}

struct Roadmap: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var dream: String
    var worldId: String
    var days: Int
    var startDate: Date
    var questIds: [String]
    var pointA: String?
    var pointB: [String]?
}

struct Achievement: Codable, Identifiable, Hashable {
    var id: String
    var icon: String
    var title: String
    var desc: String
    var at: Date
}

struct LogEntry: Codable, Identifiable, Hashable {
    var id: String
    var at: Date
    var text: String
    var xp: Int
}

struct Profile: Codable, Hashable {
    var name: String
    var age: Int?
    var location: String
    var mode: GameMode
    var dream: String
    var createdAt: Date
    var demo: Bool
}

struct GameSettings: Codable, Hashable {
    var calm: Bool
    var parentConfirm: Bool
}

struct GameState: Codable {
    var version: Int = 1
    var profile: Profile?
    var worlds: [World] = []
    var quests: [Quest] = []
    var roadmaps: [Roadmap] = []
    var achievements: [Achievement] = []
    var log: [LogEntry] = []
    var settings = GameSettings(calm: false, parentConfirm: false)
}

enum RPGID {
    static func make(_ prefix: String) -> String {
        "\(prefix)_\(UUID().uuidString.prefix(12).lowercased())"
    }
}

/// Форматирование чисел как на карточках: 31 750.
enum RPGFormat {
    static func xp(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = " "
        f.groupingSize = 3
        f.usesGroupingSeparator = true
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
