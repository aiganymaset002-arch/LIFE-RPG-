//
//  RPGSeed.swift
//  LIFE RPG
//
//  Демо-игра: профиль Айганым (Rank A · 31 750 XP, Verified 24 500), связанные миры
//  и 90-дневная карта «AIKEN Fashion House» (сегодня день 37).
//

import Foundation

private struct SeedResult { let title: String; let world: String; let cat: String; let xp: Int; let proof: String }
private struct SeedCompany { let title: String; let cat: String; let xp: Int }
private struct SeedAiken { let n: Int; let title: String; let tier: String; let xp: Int; let cat: String; let boss: Bool }

private func r(_ title: String, _ world: String, _ cat: String, _ xp: Int, _ proof: String) -> SeedResult {
    SeedResult(title: title, world: world, cat: cat, xp: xp, proof: proof)
}
private func m(_ title: String, _ cat: String, _ xp: Int) -> SeedCompany { SeedCompany(title: title, cat: cat, xp: xp) }
private func a(_ n: Int, _ title: String, _ tier: String, _ xp: Int, _ cat: String, boss: Bool = false) -> SeedAiken {
    SeedAiken(n: n, title: title, tier: tier, xp: xp, cat: cat, boss: boss)
}

enum RPGSeed {
    private static let results: [SeedResult] = [
        // 🎓 Образование
        r("Учёба в NIS IB", "academic", "education", 500, "Диплом / справка NIS"),
        r("Сложная программа IB", "academic", "education", 300, "Транскрипт"),
        r("Академическая дисциплина", "academic", "education", 350, "Табель"),
        r("Участие в олимпиадах", "academic", "education", 400, "Грамоты"),
        r("Harvard CS50 + NASA SE", "developer", "education", 300, "cs50.harvard.edu/certificate"),
        r("MIT OpenCourseWare", "academic", "education", 250, "Сертификат OCW"),
        r("15+ сертификатов", "academic", "education", 200, "Портфолио сертификатов"),
        // 🔬 Наука
        r("2 статьи в Scopus (Q2)", "academic", "science", 800, "doi.org — 2 публикации"),
        r("Исследовательские проекты", "arai", "science", 400, "ARAI Lab"),
        r("Международные конкурсы", "academic", "science", 500, "Дипломы"),
        r("Выступления и публикации", "academic", "science", 500, "Ссылки на выступления"),
        r("ResearchGate и нетворкинг", "academic", "science", 200, "researchgate.net"),
        r("78 писем профессорам", "academic", "science", 100, ""),
        r("4 ответа от профессоров", "academic", "science", 150, "Скриншоты писем"),
        // 🚀 Проекты и бизнес
        r("Arai Academy (стартап)", "personal", "business", 700, "arai.academy"),
        r("Корпоративные связи", "personal", "business", 500, ""),
        r("Магазин на Kaspi", "personal", "business", 300, "kaspi.kz/shop"),
        r("Разработка приложений", "developer", "business", 400, "GitHub"),
        r("Привлечение инвестиций ($60M)", "personal", "business", 700, "Договор"),
        r("Сайт и бренд", "personal", "business", 250, "Сайт"),
        // 💻 Программирование
        r("Программирование: Python, C++, Flutter, Django", "developer", "tech", 600, "GitHub"),
        r("Освоила Android Studio и эмуляторы", "developer", "tech", 300, "GitHub"),
        r("Разработка мобильных приложений", "developer", "tech", 400, "GitHub"),
        r("Создание сайтов с нуля", "developer", "tech", 300, "GitHub Pages"),
        r("Backend, API, базы данных и серверы", "developer", "tech", 400, "GitHub"),
        r("Программирование сайтов (не через ИИ)", "developer", "tech", 300, ""),
        r("Сертификаты Google, Microsoft, Alison, HP", "developer", "tech", 400, "Сертификаты"),
        // 🌍 Языки
        r("Немецкий: Goethe C1", "personal", "languages", 600, "Сертификат Goethe"),
        r("Французский: DALF C1", "personal", "languages", 600, "Сертификат DALF"),
        r("Китайский: HSK5", "personal", "languages", 700, "Сертификат HSK"),
        r("Выступление на китайском (презентация проекта)", "personal", "languages", 300, "Видео"),
        r("Путь в BLCU через экзамен и рек. письмо", "personal", "languages", 500, "Письмо BLCU"),
        // 🎤 Медиа
        r("ATA MURA: 4 000 просмотров", "personal", "media", 800, "Ссылка на видео"),
        r("10 видео → 1 000+ просмотров", "personal", "media", 600, "Ссылки"),
        r("AIKEN: аккаунт + ролик (700 просмотров)", "personal", "media", 700, "Instagram"),
        r("TikTok: 1 303 просмотра + 87 лайков", "personal", "media", 300, "tiktok.com"),
        r("LinkedIn: 1 800 impressions / 14 дней", "personal", "media", 200, "LinkedIn"),
        r("LinkedIn: 2 400+ подписчиков", "personal", "media", 300, "LinkedIn"),
        r("Публичные выступления", "personal", "media", 400, ""),
        // 💼 Карьера
        r("Стажировка в КТЖ", "personal", "career", 400, "Справка"),
        r("Стажировка переводчиком в CHEC", "personal", "career", 750, "Рекомендательное письмо CHEC"),
        r("30 часов работы переводчиком", "personal", "career", 400, ""),
        r("Профессиональные связи и план роста", "personal", "career", 500, "LinkedIn"),
        r("Международный нетворкинг", "personal", "career", 150, "LinkedIn"),
        r("Astana Hub: прошла первый тур на программу", "personal", "career", 1000, "Письмо Astana Hub"),
        r("XAI: прошла первичный screening", "personal", "career", 1000, "Email"),
        // 🧠 Личное развитие
        r("Система концентрации (4–5 дней)", "personal", "growth", 300, ""),
        r("Уверенность и любовь к себе", "personal", "growth", 400, ""),
        r("Баланс работы и отдыха", "personal", "growth", 300, ""),
        r("Фокус на 2 главных направлениях", "personal", "growth", 400, ""),
        r("Психологический рост и дисциплина", "personal", "growth", 400, ""),
        r("Научила маму основам веб-разработки", "personal", "growth", 300, ""),
        r("Освоила делегирование", "personal", "growth", 300, ""),
        // ❤️ Личная жизнь
        r("Модельное агентство (заявка)", "personal", "life", 300, ""),
        r("День рождения мечты", "personal", "life", 250, ""),
        r("Поддержка мамы и семьи", "personal", "life", 300, ""),
        r("Расхламление и продажи", "personal", "life", 300, ""),
        // 🎓 Сертификаты с подтверждением
        r("Ki-Campus: Einführung in die KI — 40 ч, 92,75%", "academic", "education", 500, "Leistungsnachweis Ki-Campus"),
        r("UNAM: Exposición oral y presentaciones — 20 ч", "academic", "languages", 350, "Сертификат UNAM"),
    ]

    /// MASHSTROY: «Company Level C — Growth · 18 450 / 30 000 XP», слабое место — Sales.
    private static let mashstroy: [SeedCompany] = [
        m("Зарегистрировали компанию", "finance", 500),
        m("Создали MVP", "product", 2500),
        m("Получили первого клиента", "sales", 700),
        m("Подписали партнёрство", "brand", 1500),
        m("Наняли сотрудника", "team", 1000),
        m("Получили инвестиции", "finance", 2500),
        m("Вышли в новый город", "international", 1500),
        m("Получили патент", "rnd", 2000),
        m("Автоматизировали производство", "technology", 3000),
        m("Внедрили AI в технологию", "technology", 550),
        m("Запустили социальную программу", "impact", 1500),
    ]

    /// 90 ДНЕЙ ДО МАСШТАБНОГО РЕЗУЛЬТАТА — AIKEN FASHION HOUSE.
    private static let aiken: [SeedAiken] = [
        a(1, "Сделать сайт AIKEN FASHION HOUSE", "cert", 300, "product"),
        a(2, "Сделать брошюру о миссии, ценностях и проектах", "task", 100, "brand"),
        a(3, "Создать первые 5 необычных изобретений / нарядов", "project", 800, "rnd"),
        a(4, "Регулярно выкладывать посты (соцсети, блог, видео)", "task", 100, "brand"),
        a(5, "Собрать зал и показать разработки детям с ОВЗ / провести мероприятие", "project", 700, "impact"),
        a(6, "Выложить это в журнал (AIKEN Magazine, выпуск 1)", "cert", 400, "brand"),
        a(7, "Написать научные работы по 5 разработкам", "publication", 1200, "rnd"),
        a(8, "Вдохновлять и вовлекать других дизайнеров и изобретателей", "cert", 300, "team"),
        a(9, "Сделать свой fashion-дизайн / собственный стиль", "cert", 400, "product"),
        a(10, "Написать Chanel, Dior и ещё ~50 брендам. Сделать Merch AIKEN", "cert", 500, "sales"),
        a(12, "Сделать первую коллекцию из 10 необычных технологичных нарядов", "project", 1000, "product"),
        a(13, "Создать 5 изобретений для людей с ОВЗ: застёжки, одежда для моторики, тактильные элементы", "project", 1000, "impact"),
        a(14, "Сделать AIKEN Fashion Lab — лабораторию для детей и молодёжи с ОВЗ с AI и инженерами", "project", 1200, "rnd"),
        a(15, "Первый AIKEN Inclusive Fashion Show на 100–200 человек", "internship", 1500, "brand", boss: true),
        a(16, "Спецвыпуск AIKEN Magazine: каждый наряд = человек + идея + технология", "cert", 400, "brand"),
        a(17, "Добавить QR-код к каждому наряду в журнале (видео: идея, создание, технологии)", "task", 100, "technology"),
        a(18, "Конкурс AIKEN Young Inventors & Designers — дети придумывают fashion-изобретения", "project", 800, "impact"),
        a(19, "Отобрать AIKEN 30 — 30 молодых дизайнеров, инженеров, моделей и изобретателей", "project", 700, "team"),
        a(20, "Первая большая editorial-фотосессия уровня международного fashion-журнала", "project", 800, "brand"),
        a(21, "AIKEN × Kazakhstan collection — казахское наследие в fashion-tech", "project", 1000, "product"),
        a(22, "AIKEN «ATA MURA» collection: культурная история → идея ребёнка → AI/инженеры → наряд", "project", 1000, "product"),
        a(23, "Подать 5 разработок на патентование / защиту дизайна", "project", 1500, "rnd"),
        a(24, "Подать AIKEN на fashion + innovation + inclusion гранты, собрать грантовый портфель", "project", 800, "finance"),
        a(25, "AIKEN Documentary — фильм о детях и людях с ОВЗ как соавторах fashion-инноваций", "project", 1000, "brand"),
        a(26, "Найти 20 международных fashion schools для совместных student projects", "intl", 2000, "international"),
        a(27, "Найти 20 музеев / design institutions для выставки «Fashion × Engineering × Inclusion»", "intl", 2000, "international"),
        a(28, "AIKEN Exhibition — рядом с каждым платьем чертёж, технология, автор и прототип", "intl", 2500, "brand", boss: true),
        a(29, "Первый зарубежный pop-up / show AIKEN", "intl", 2500, "international"),
        a(30, "AIKEN Fashion Technology Conference: дизайнеры + инженеры + AI + inclusion + дети", "intl", 2000, "brand"),
        a(31, "Первые 100 платных заказов — проект становится коммерческим", "internship", 2000, "sales", boss: true),
        a(32, "Limited collections: часть дохода идёт на изобретения молодого автора", "project", 1000, "finance"),
        a(33, "Привлечь 10 известных моделей / артистов / инфлюенсеров для съёмок", "project", 1200, "brand"),
        a(34, "Первые 20 публикаций в зарубежных fashion/design/technology media", "intl", 2500, "brand"),
        a(35, "Международный AIKEN Award за лучшее изобретение в inclusive fashion", "intl", 3000, "impact"),
        a(36, "90 ДНЕЙ → AIKEN FASHION HOUSE: международный бренд + сообщество + инновации", "startup", 8000, "international", boss: true),
    ]

    static func demo(now: Date = Date()) -> GameState {
        var s = GameState()
        s.profile = Profile(name: "Айганым", age: 15, location: "Астана, Казахстан", mode: .life,
                            dream: "Поступить в топовый университет и стать AI/software engineer", createdAt: now, demo: true, avatar: "AvatarGirl")
        s.settings = GameSettings(calm: false, parentConfirm: false)
        s.addWorld(name: "Personal World", type: .personal, emoji: "👤", id: "personal")
        s.addWorld(name: "Academic World", type: .academic, emoji: "🎓", id: "academic")
        s.addWorld(name: "Developer World", type: .developer, emoji: "💻", id: "developer")
        s.addWorld(name: "MASHSTROY", type: .company, emoji: "🏗", id: "mashstroy")
        s.addWorld(name: "ARAI World", type: .research, emoji: "🔬", id: "arai")
        s.addWorld(name: "AIKEN Fashion House", type: .company, emoji: "👗", id: "aiken")
        func ago(_ d: Double) -> Date { now.addingTimeInterval(-d * RPGEngine.dayLength) }

        var d = 400.0
        for x in results {
            s.quests.append(Quest(title: x.title, awards: [XPAward(worldId: x.world, cat: x.cat, xp: x.xp)],
                                  status: .done, proof: x.proof, doneAt: ago(d)))
            d -= 6
        }
        for x in mashstroy {
            s.quests.append(Quest(title: x.title, awards: [XPAward(worldId: "mashstroy", cat: x.cat, xp: x.xp)],
                                  status: .done, proof: "Документ компании", doneAt: ago(d)))
            d -= 1
        }
        // Связанные миры: одно достижение → XP сразу трём мирам.
        s.quests.append(Quest(title: "Опубликовала исследование по технологии MASHSTROY", tier: "publication",
                              awards: [XPAward(worldId: "personal", cat: "science", xp: 700),
                                       XPAward(worldId: "academic", cat: "science", xp: 1000),
                                       XPAward(worldId: "mashstroy", cat: "rnd", xp: 1200)],
                              status: .done, proof: "doi.org/…", doneAt: ago(20)))

        var rm = Roadmap(id: "rm_aiken", title: "90 дней до масштабного результата — AIKEN Fashion House",
                         dream: "За 90 дней запустить и масштабировать AIKEN Fashion House", worldId: "aiken", days: 90,
                         startDate: ago(36), questIds: [],
                         pointA: "AIKEN Fashion House — платформа, где дети и люди с ОВЗ становятся изобретателями моды через AI, инженерию и дизайн.",
                         pointB: ["1 коллекция из 10 нарядов", "5 patent/IP заявок", "100 платных заказов", "20+ публикаций",
                                  "Fashion Show 100–200 чел.", "Международные партнёры", "AIKEN Magazine выпуск 1",
                                  "Лаборатория AIKEN Lab", "Конкурс + AIKEN 30"])
        var prep: [String] = []
        for (i, x) in aiken.enumerated() {
            let week = i / 3 + 1
            let day = Swift.min(90, (week - 1) * 7 + 1 + (i % 3) * 2)
            let done = week <= 5
            let personalCat: String = x.cat == "rnd" ? "science" : (x.cat == "brand" ? "media" : "business")
            let proof: String = (done && x.n % 2 == 1) ? "Фото / ссылка" : ""
            let awards = [XPAward(worldId: "aiken", cat: x.cat, xp: x.xp),
                          XPAward(worldId: "personal", cat: personalCat, xp: Int((Double(x.xp) * 0.5).rounded()))]
            let qst = Quest(id: "aiken_\(x.n)", title: x.title, tier: x.tier, awards: awards,
                            status: done ? .done : .open, proof: proof, boss: x.boss, requires: x.boss ? prep : [],
                            roadmapId: rm.id, day: day, phase: "Неделя \(week)",
                            doneAt: done ? ago(Double(36 - day)) : nil)
            if x.boss { prep = [] } else { prep.append(qst.id) }
            s.quests.append(qst)
            rm.questIds.append(qst.id)
        }
        s.roadmaps.append(rm)

        // Баланс до показателей профиля: 31 750 XP.
        let missing = 31_750 - s.playerXP()
        if missing > 0 {
            s.quests.append(Quest(title: "Достижения до начала игры (свои критерии)", custom: true,
                                  awards: [XPAward(worldId: "personal", cat: "growth", xp: missing)], status: .done, doneAt: ago(420)))
        }
        s.checkAchievements()
        s.addLog("Новое достижение: системный подход и реализация проектов", xp: 500)
        return s
    }
}
