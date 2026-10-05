// Демо-игра: профиль Айганым (Rank A · 31 750 XP), связанные миры и 90-дневная карта AIKEN Fashion House (день 37).
import { emptyState, makeQuest, uid, playerXP, checkAchievements, DAY_MS } from './core.js';

const W = (id, name, type, emoji) => ({ id, name, type, emoji, createdAt: Date.now() });

// [название, мир, категория, XP, доказательство]
const RESULTS = [
  // 🎓 Образование
  ['Учёба в NIS IB', 'academic', 'education', 500, 'Диплом / справка NIS'],
  ['Сложная программа IB', 'academic', 'education', 300, 'Транскрипт'],
  ['Академическая дисциплина', 'academic', 'education', 350, 'Табель'],
  ['Участие в олимпиадах', 'academic', 'education', 400, 'Грамоты'],
  ['Harvard CS50 + NASA SE', 'developer', 'education', 300, 'cs50.harvard.edu/certificate'],
  ['MIT OpenCourseWare', 'academic', 'education', 250, 'Сертификат OCW'],
  ['15+ сертификатов', 'academic', 'education', 200, 'Портфолио сертификатов'],
  // 🔬 Наука
  ['2 статьи в Scopus (Q2)', 'academic', 'science', 800, 'doi.org — 2 публикации'],
  ['Исследовательские проекты', 'arai', 'science', 400, 'ARAI Lab'],
  ['Международные конкурсы', 'academic', 'science', 500, 'Дипломы'],
  ['Выступления и публикации', 'academic', 'science', 500, 'Ссылки на выступления'],
  ['ResearchGate и нетворкинг', 'academic', 'science', 200, 'researchgate.net'],
  ['78 писем профессорам', 'academic', 'science', 100, ''],
  ['4 ответа от профессоров', 'academic', 'science', 150, 'Скриншоты писем'],
  // 🚀 Проекты и бизнес
  ['Arai Academy (стартап)', 'personal', 'business', 700, 'arai.academy'],
  ['Корпоративные связи', 'personal', 'business', 500, ''],
  ['Магазин на Kaspi', 'personal', 'business', 300, 'kaspi.kz/shop'],
  ['Разработка приложений', 'developer', 'business', 400, 'GitHub'],
  ['Привлечение инвестиций ($60M)', 'personal', 'business', 700, 'Договор'],
  ['Сайт и бренд', 'personal', 'business', 250, 'Сайт'],
  // 💻 Программирование
  ['Программирование: Python, C++, Flutter, Django', 'developer', 'tech', 600, 'GitHub'],
  ['Освоила Android Studio и эмуляторы', 'developer', 'tech', 300, 'GitHub'],
  ['Разработка мобильных приложений', 'developer', 'tech', 400, 'GitHub'],
  ['Создание сайтов с нуля', 'developer', 'tech', 300, 'GitHub Pages'],
  ['Backend, API, базы данных и серверы', 'developer', 'tech', 400, 'GitHub'],
  ['Программирование сайтов (не через ИИ)', 'developer', 'tech', 300, ''],
  ['Сертификаты Google, Microsoft, Alison, HP', 'developer', 'tech', 400, 'Сертификаты'],
  // 🌍 Языки
  ['Немецкий: Goethe C1', 'personal', 'languages', 600, 'Сертификат Goethe'],
  ['Французский: DALF C1', 'personal', 'languages', 600, 'Сертификат DALF'],
  ['Китайский: HSK5', 'personal', 'languages', 700, 'Сертификат HSK'],
  ['Выступление на китайском (презентация проекта)', 'personal', 'languages', 300, 'Видео'],
  ['Путь в BLCU через экзамен и рек. письмо', 'personal', 'languages', 500, 'Письмо BLCU'],
  // 🎤 Медиа
  ['ATA MURA: 4 000 просмотров', 'personal', 'media', 800, 'Ссылка на видео'],
  ['10 видео → 1 000+ просмотров', 'personal', 'media', 600, 'Ссылки'],
  ['AIKEN: аккаунт + ролик (700 просмотров)', 'personal', 'media', 700, 'Instagram'],
  ['TikTok: 1 303 просмотра + 87 лайков', 'personal', 'media', 300, 'tiktok.com'],
  ['LinkedIn: 1 800 impressions / 14 дней', 'personal', 'media', 200, 'LinkedIn'],
  ['LinkedIn: 2 400+ подписчиков', 'personal', 'media', 300, 'LinkedIn'],
  ['Публичные выступления', 'personal', 'media', 400, ''],
  // 💼 Карьера
  ['Стажировка в КТЖ', 'personal', 'career', 400, 'Справка'],
  ['Стажировка переводчиком в CHEC', 'personal', 'career', 750, 'Рекомендательное письмо CHEC'],
  ['30 часов работы переводчиком', 'personal', 'career', 400, ''],
  ['Профессиональные связи и план роста', 'personal', 'career', 500, 'LinkedIn'],
  ['Международный нетворкинг', 'personal', 'career', 150, 'LinkedIn'],
  ['Astana Hub: прошла первый тур на программу', 'personal', 'career', 1000, 'Письмо Astana Hub'],
  ['XAI: прошла первичный screening', 'personal', 'career', 1000, 'Email'],
  // 🧠 Личное развитие
  ['Система концентрации (4–5 дней)', 'personal', 'growth', 300, ''],
  ['Уверенность и любовь к себе', 'personal', 'growth', 400, ''],
  ['Баланс работы и отдыха', 'personal', 'growth', 300, ''],
  ['Фокус на 2 главных направлениях', 'personal', 'growth', 400, ''],
  ['Психологический рост и дисциплина', 'personal', 'growth', 400, ''],
  ['Научила маму основам веб-разработки', 'personal', 'growth', 300, ''],
  ['Освоила делегирование', 'personal', 'growth', 300, ''],
  // ❤️ Личная жизнь
  ['Модельное агентство (заявка)', 'personal', 'life', 300, ''],
  ['День рождения мечты', 'personal', 'life', 250, ''],
  ['Поддержка мамы и семьи', 'personal', 'life', 300, ''],
  ['Расхламление и продажи', 'personal', 'life', 300, ''],
  // 🎓 Сертификаты с подтверждением
  ['Ki-Campus: Einführung in die KI — 40 ч, 92,75%', 'academic', 'education', 500, 'Leistungsnachweis Ki-Campus'],
  ['UNAM: Exposición oral y presentaciones — 20 ч', 'academic', 'languages', 350, 'Сертификат UNAM'],
];

// Компания MASHSTROY: «Company Level C — Growth · 18 450 / 30 000 XP».
const MASHSTROY = [
  ['Зарегистрировали компанию', 'finance', 500],
  ['Создали MVP', 'product', 2500],
  ['Получили первого клиента', 'sales', 700],
  ['Подписали партнёрство', 'brand', 1500],
  ['Наняли сотрудника', 'team', 1000],
  ['Получили инвестиции', 'finance', 2500],
  ['Вышли в новый город', 'international', 1500],
  ['Получили патент', 'rnd', 2000],
  ['Автоматизировали производство', 'technology', 3000],
  ['Внедрили AI в технологию', 'technology', 550],
  ['Запустили социальную программу', 'impact', 1500],
];

// 90 ДНЕЙ ДО МАСШТАБНОГО РЕЗУЛЬТАТА — AIKEN FASHION HOUSE
// [номер, название, тариф, XP, категория, boss]
const AIKEN = [
  [1, 'Сделать сайт AIKEN FASHION HOUSE', 'cert', 300, 'product'],
  [2, 'Сделать брошюру о миссии, ценностях и проектах', 'task', 100, 'brand'],
  [3, 'Создать первые 5 необычных изобретений / нарядов', 'project', 800, 'rnd'],
  [4, 'Регулярно выкладывать посты (соцсети, блог, видео)', 'task', 100, 'brand'],
  [5, 'Собрать зал и показать разработки детям с ОВЗ / провести мероприятие', 'project', 700, 'impact'],
  [6, 'Выложить это в журнал (AIKEN Magazine, выпуск 1)', 'cert', 400, 'brand'],
  [7, 'Написать научные работы по 5 разработкам', 'publication', 1200, 'rnd'],
  [8, 'Вдохновлять и вовлекать других дизайнеров и изобретателей', 'cert', 300, 'team'],
  [9, 'Сделать свой fashion-дизайн / собственный стиль', 'cert', 400, 'product'],
  [10, 'Написать Chanel, Dior и ещё ~50 брендам. Сделать Merch AIKEN', 'cert', 500, 'sales'],
  [12, 'Сделать первую коллекцию из 10 необычных технологичных нарядов', 'project', 1000, 'product'],
  [13, 'Создать 5 изобретений для людей с ОВЗ: застёжки, одежда для моторики, тактильные элементы', 'project', 1000, 'impact'],
  [14, 'Сделать AIKEN Fashion Lab — лабораторию для детей и молодёжи с ОВЗ с AI и инженерами', 'project', 1200, 'rnd'],
  [15, 'Первый AIKEN Inclusive Fashion Show на 100–200 человек', 'internship', 1500, 'brand', true],
  [16, 'Спецвыпуск AIKEN Magazine: каждый наряд = человек + идея + технология', 'cert', 400, 'brand'],
  [17, 'Добавить QR-код к каждому наряду в журнале (видео: идея, создание, технологии)', 'task', 100, 'technology'],
  [18, 'Конкурс AIKEN Young Inventors & Designers — дети придумывают fashion-изобретения', 'project', 800, 'impact'],
  [19, 'Отобрать AIKEN 30 — 30 молодых дизайнеров, инженеров, моделей и изобретателей', 'project', 700, 'team'],
  [20, 'Первая большая editorial-фотосессия уровня международного fashion-журнала', 'project', 800, 'brand'],
  [21, 'AIKEN × Kazakhstan collection — казахское наследие в fashion-tech', 'project', 1000, 'product'],
  [22, 'AIKEN «ATA MURA» collection: культурная история → идея ребёнка → AI/инженеры → наряд', 'project', 1000, 'product'],
  [23, 'Подать 5 разработок на патентование / защиту дизайна', 'project', 1500, 'rnd'],
  [24, 'Подать AIKEN на fashion + innovation + inclusion гранты, собрать грантовый портфель', 'project', 800, 'finance'],
  [25, 'AIKEN Documentary — фильм о детях и людях с ОВЗ как соавторах fashion-инноваций', 'project', 1000, 'brand'],
  [26, 'Найти 20 международных fashion schools для совместных student projects', 'intl', 2000, 'international'],
  [27, 'Найти 20 музеев / design institutions для выставки «Fashion × Engineering × Inclusion»', 'intl', 2000, 'international'],
  [28, 'AIKEN Exhibition — рядом с каждым платьем чертёж, технология, автор и прототип', 'intl', 2500, 'brand', true],
  [29, 'Первый зарубежный pop-up / show AIKEN', 'intl', 2500, 'international'],
  [30, 'AIKEN Fashion Technology Conference: дизайнеры + инженеры + AI + inclusion + дети', 'intl', 2000, 'brand'],
  [31, 'Первые 100 платных заказов — проект становится коммерческим', 'internship', 2000, 'sales', true],
  [32, 'Limited collections: часть дохода идёт на изобретения молодого автора', 'project', 1000, 'finance'],
  [33, 'Привлечь 10 известных моделей / артистов / инфлюенсеров для съёмок', 'project', 1200, 'brand'],
  [34, 'Первые 20 публикаций в зарубежных fashion/design/technology media', 'intl', 2500, 'brand'],
  [35, 'Международный AIKEN Award за лучшее изобретение в inclusive fashion', 'intl', 3000, 'impact'],
  [36, '90 ДНЕЙ → AIKEN FASHION HOUSE: международный бренд + сообщество + инновации', 'startup', 8000, 'international', true],
];

export function buildDemo(now = Date.now()) {
  const s = emptyState();
  s.profile = { name: 'Айганым', age: 15, location: 'Астана, Казахстан', mode: 'life', dream: 'Поступить в топовый университет и стать AI/software engineer', createdAt: now, demo: true };
  s.worlds = [
    W('personal', 'Personal World', 'personal', '👤'),
    W('academic', 'Academic World', 'academic', '🎓'),
    W('developer', 'Developer World', 'developer', '💻'),
    W('mashstroy', 'MASHSTROY', 'company', '🏗'),
    W('arai', 'ARAI World', 'research', '🔬'),
    W('aiken', 'AIKEN Fashion House', 'company', '👗'),
  ];
  const ago = (d) => now - d * DAY_MS;
  let d = 400;
  for (const [title, worldId, cat, xp, proof] of RESULTS) {
    s.quests.push(makeQuest({ title, awards: [{ worldId, cat, xp }], proof, status: 'done', doneAt: ago(d), tier: null }));
    d -= 6;
  }
  for (const [title, cat, xp] of MASHSTROY) s.quests.push(makeQuest({ title, awards: [{ worldId: 'mashstroy', cat, xp }], proof: 'Документ компании', status: 'done', doneAt: ago(d--) }));
  // Связанные миры: одно достижение → XP сразу трём мирам.
  s.quests.push(makeQuest({ title: 'Опубликовала исследование по технологии MASHSTROY', tier: 'publication', proof: 'doi.org/…', status: 'done', doneAt: ago(20),
    awards: [{ worldId: 'personal', cat: 'science', xp: 700 }, { worldId: 'academic', cat: 'science', xp: 1000 }, { worldId: 'mashstroy', cat: 'rnd', xp: 1200 }] }));

  // Карта AIKEN — сегодня день 37 из 90.
  const rm = { id: 'rm_aiken', title: '90 дней до масштабного результата — AIKEN Fashion House', dream: 'За 90 дней запустить и масштабировать AIKEN Fashion House', worldId: 'aiken', days: 90, startDate: ago(36), questIds: [], kinds: ['company'],
    pointA: 'AIKEN Fashion House — платформа, где дети и люди с ОВЗ становятся изобретателями моды через AI, инженерию и дизайн.',
    pointB: ['1 коллекция из 10 нарядов', '5 patent/IP заявок', '100 платных заказов', '20+ публикаций', 'Fashion Show 100–200 чел.', 'Международные партнёры', 'AIKEN Magazine выпуск 1', 'Лаборатория AIKEN Lab', 'Конкурс + AIKEN 30'] };
  const prep = [];
  AIKEN.forEach(([n, title, tier, xp, cat, boss], i) => {
    const week = Math.floor(i / 3) + 1;
    const day = Math.min(90, (week - 1) * 7 + 1 + (i % 3) * 2);
    const done = week <= 5;
    const q = makeQuest({ id: 'aiken_' + n, title, tier, roadmapId: rm.id, day, phase: `Неделя ${week}`, boss: !!boss,
      awards: [{ worldId: 'aiken', cat, xp }, { worldId: 'personal', cat: cat === 'rnd' ? 'science' : cat === 'brand' ? 'media' : 'business', xp: Math.round(xp * 0.5) }],
      requires: boss ? prep.splice(0).map((p) => p.id) : [],
      status: done ? 'done' : 'open', doneAt: done ? ago(36 - day) : null, proof: done && n % 2 ? 'Фото / ссылка' : '' });
    if (!boss) prep.push(q);
    s.quests.push(q);
    rm.questIds.push(q.id);
  });
  s.roadmaps.push(rm);

  // Баланс до показателей профиля: 31 750 XP (из них проверено ~24 500).
  const missing = 31750 - playerXP(s);
  if (missing > 0) s.quests.push(makeQuest({ title: 'Достижения до начала игры (свои критерии)', custom: true, awards: [{ worldId: 'personal', cat: 'growth', xp: missing }], status: 'done', doneAt: ago(420) }));
  checkAchievements(s);
  s.log.unshift({ at: now, text: 'Новое достижение: системный подход и реализация проектов', xp: 500 });
  return s;
}
