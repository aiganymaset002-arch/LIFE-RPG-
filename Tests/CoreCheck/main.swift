// Проверка игрового ядра LIFE RPG (без интерфейса).
// Запуск на Mac:  swiftc LifeRPG/Core/RPGModels.swift LifeRPG/Core/RPGEngine.swift LifeRPG/Core/GameMaster.swift \
//                    LifeRPG/Core/RPGSeed.swift Tests/CoreCheck/main.swift -o /tmp/corecheck && /tmp/corecheck
import Foundation

var failures = 0
func check(_ ok: Bool, _ name: String, file: String = #file, line: Int = #line) {
    if ok { print("✓ \(name)") } else { failures += 1; print("✗ \(name) (line \(line))") }
}

func fresh() -> GameState {
    var s = GameState()
    s.profile = Profile(name: "T", age: nil, location: "", mode: .life, dream: "", createdAt: Date(), demo: false)
    s.addWorld(name: "Personal", type: .personal)
    return s
}

// Ранги
check(RPGEngine.rank(for: 0, scale: .person).rank.id == "E", "E при 0 XP")
check(RPGEngine.rank(for: 9_450, scale: .person).rank.id == "C", "C при 9 450 XP")
check(RPGEngine.rank(for: 9_450, scale: .person).toNext == 5_550, "до B осталось 5 550")
let a = RPGEngine.rank(for: 31_750, scale: .person)
check(a.rank.id == "A" && a.next?.id == "S" && a.toNext == 68_250, "A · 31 750 → S, осталось 68 250")
check(RPGEngine.rank(for: 500_000, scale: .person).rank.id == "SSS", "SSS при 500 000")
check(RPGEngine.rank(for: 18_450, scale: .company).rank.name == "Growth", "компания C — Growth")

// Verified vs свои критерии
do {
    var s = fresh()
    let w = s.worlds[0].id
    s.addResult(title: "Сертификат", tier: "cert", custom: false, awards: [XPAward(worldId: w, cat: "education", xp: 300)], proof: "link")
    s.addResult(title: "Книга", tier: nil, custom: true, awards: [XPAward(worldId: w, cat: "growth", xp: 50_000)], proof: "фото")
    check(s.playerXP() == 50_300 && s.playerXP(verifiedOnly: true) == 300, "Verified XP отдельно от своих критериев")
    let q = s.addResult(title: "Задача", tier: "task", custom: false, awards: [XPAward(worldId: w, cat: "tech", xp: 99_999)], proof: "")
    check(s.questXP(q) == 100, "XP ограничен диапазоном тарифа")
}

// Boss Battle закрыт до подготовки
do {
    var s = fresh()
    let plan = GameMaster.generate("IELTS 7.0 за 6 месяцев")
    check(plan.days == 180, "IELTS: 180 дней")
    let rm = GameMaster.apply(plan, to: &s, worldId: s.worlds[0].id)
    if let boss = s.roadmapQuests(rm).first(where: { $0.boss }) {
        check(s.isLocked(boss), "босс закрыт")
        check(s.complete(boss.id).locked, "босса нельзя выполнить заранее")
        for r in boss.requires { s.complete(r) }
        check(!s.isLocked(boss) && s.complete(boss.id).ok, "босс открыт после подготовки")
    } else { check(false, "в карте есть босс") }
}

// Провал → Bootstrap Strategy
do {
    var s = fresh()
    let c = s.addWorld(name: "AIKEN", type: .company)
    let rm = GameMaster.apply(GameMaster.generate("За 90 дней запустить и масштабировать AIKEN Fashion House"), to: &s, worldId: c.id)
    if let pitch = s.roadmapQuests(rm).first(where: { $0.title.contains("питч инвестору") }), let i = s.questIndex(pitch.id) {
        s.quests[i].requires = []
        let r = s.fail(pitch.id)
        check(r?.route == "Bootstrap Strategy" && r?.created.count == 3, "новый маршрут Bootstrap Strategy")
        check((r?.created ?? []).reduce(0) { $0 + s.questXP($1, worldId: c.id) } == 1_500, "3 sales-квеста → +1 500 XP")
    } else { check(false, "найден питч инвестору") }
}

// Связанные миры
do {
    var s = fresh()
    let ac = s.addWorld(name: "Academic", type: .academic)
    let m = s.addWorld(name: "MASHSTROY", type: .company)
    s.addResult(title: "Опубликовала исследование", tier: "publication", custom: false, awards: [
        XPAward(worldId: s.worlds[0].id, cat: "science", xp: 700), XPAward(worldId: ac.id, cat: "science", xp: 1_000), XPAward(worldId: m.id, cat: "rnd", xp: 1_200)], proof: "doi")
    check(s.worldXP(m.id) == 1_200 && s.playerXP() == 1_700, "XP сразу нескольким мирам")
    let ids = s.checkAchievements().map(\.id)
    check(ids.contains("publication") && ids.contains("multiworld"), "First Research Publication + Связанные миры")
}

// Level Up
do {
    var s = fresh()
    let before = s.snapshot()
    s.addResult(title: "Стажировка", tier: "internship", custom: false, awards: [XPAward(worldId: s.worlds[0].id, cat: "career", xp: 1_500)], proof: "")
    let ups = s.rankUps(from: before, to: s.snapshot())
    check(ups.first?.from == "E" && ups.first?.to == "D", "LEVEL UP E → D")
}

// Детский режим
do {
    var s = GameState()
    s.profile = Profile(name: "K", age: 8, location: "", mode: .kids, dream: "", createdAt: Date(), demo: false)
    let w = s.addWorld(name: "Мой мир", type: .kids)
    let rm = GameMaster.apply(GameMaster.generate("приключение", mode: .kids), to: &s, worldId: w.id)
    let q = s.roadmapQuests(rm)[0]
    check(s.complete(q.id, needsParent: true).pending && s.playerXP() == 0, "ждёт подтверждения родителя")
    s.confirm(q.id)
    check(s.playerXP() > 0 && s.isVerified(s.quest(q.id)!), "родитель подтвердил → Verified")
}

// Game Master
check(GameMaster.parseDuration("IELTS 7.0 за 6 месяцев") == 180, "срок: 6 месяцев")
check(GameMaster.parseDuration("Мне 15 лет. Я хочу через три года поступить в MIT") == 1_095, "срок: через три года (не возраст)")
check(GameMaster.parseDuration("За 90 дней запустить") == 90, "срок: 90 дней")
check(GameMaster.parseName("За 90 дней запустить и масштабировать AIKEN Fashion House") == "AIKEN Fashion House", "название компании")
let mit = GameMaster.generate("Мне 15 лет. Я хочу через три года поступить в MIT и создать технологическую компанию")
check(mit.kinds == ["university", "company"] && mit.days == 1_095, "MIT + компания на 3 года")

// Демо = профиль с картинки
let demo = RPGSeed.demo()
check(demo.playerXP() == 31_750, "демо: 31 750 XP (\(demo.playerXP()))")
check(demo.playerXP(verifiedOnly: true) == 24_500, "демо: Verified 24 500 (\(demo.playerXP(verifiedOnly: true)))")
check(demo.worldXP("mashstroy") == 18_450, "MASHSTROY 18 450")
check(demo.weakSpot("mashstroy")?.cat == "sales", "слабое место MASHSTROY — Sales")
check(demo.progress(of: demo.roadmaps[0]).day == 37, "AIKEN: день 37")

// Сохранение
let data = try! JSONEncoder().encode(demo)
let back = try! JSONDecoder().decode(GameState.self, from: data)
check(back.playerXP() == 31_750, "сохранение и загрузка игры")

print(failures == 0 ? "\nВСЕ ПРОВЕРКИ ПРОЙДЕНЫ" : "\nОШИБОК: \(failures)")
exit(failures == 0 ? 0 : 1)
