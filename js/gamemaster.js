// LIFE RPG — AI Game Master.
// Превращает мечту, написанную обычным языком, в игру: главный квест, фазы, квесты, Boss Battles, XP и запасные маршруты.
// Работает офлайн на правилах (шаблоны + разбор текста). Интерфейс generate() готов к подключению LLM.
import { WORLD_TYPES } from './data.js';
import { makeQuest, uid, DAY_MS } from './core.js';

const NUM_WORDS = { один: 1, одну: 1, одного: 1, два: 2, две: 2, три: 3, четыре: 4, пять: 5, шесть: 6, семь: 7, восемь: 8, девять: 9, десять: 10, двенадцать: 12 };

export function parseDuration(text) {
  const t = text.toLowerCase();
  if (/полгода|пол года|half a year/.test(t)) return 180;
  const num = '(\\d+|' + Object.keys(NUM_WORDS).join('|') + ')';
  const toN = (s) => (/^\d+$/.test(s) ? parseInt(s, 10) : NUM_WORDS[s]);
  const units = [
    [new RegExp(num + '\\s*(дн|день|дня|day)', 'i'), 1],
    [new RegExp(num + '\\s*(недел|week)', 'i'), 7],
    [new RegExp(num + '\\s*(месяц|мес\\b|month)', 'i'), 30],
    [new RegExp(num + '\\s*(год|лет|year)', 'i'), 365],
  ];
  // «Мне 15 лет» — это возраст, а не срок: ищем срок после «за/через/в течение/in».
  for (const [re, mul] of units) {
    const ctx = new RegExp('(за|через|в течение|на|in|within)\\s+' + re.source, 'i');
    const m = t.match(ctx);
    if (m) return Math.max(7, toN(m[2]) * mul);
  }
  for (const [re, mul] of units) {
    const m = t.match(re);
    if (m && !/мне\s*$/.test(t.slice(0, m.index))) return Math.max(7, toN(m[1]) * mul);
  }
  if (/\bгод\b|year/.test(t)) return 365;
  return null;
}

export function parseName(text) {
  const q = text.match(/«([^»]+)»|"([^"]+)"|“([^”]+)”/);
  if (q) return (q[1] || q[2] || q[3]).trim();
  const m = text.match(/(?:запустить|создать|построить|масштабировать|развить|компани[юяи]|бренд|launch|build)\s+(?:и\s+(?:масштабировать|развить)\s+)?([A-ZА-ЯЁ][\w&.\-]*(?:\s+[A-ZА-ЯЁ][\w&.\-]*){0,3})/u);
  return m ? m[1].trim() : null;
}

// ---------- шаблоны ----------
// [название, тариф, XP, категория, опции]
const T = {
  company: (ctx) => ({
    kind: 'company', worldType: 'company', title: `Запустить и масштабировать ${ctx.name || 'компанию'}`, days: 90,
    phases: [
      { name: 'IDEA → VALIDATION', quests: [
        ['Сформулировать миссию, ценности и ценностное предложение', 'task', 100, 'product'],
        ['Провести 10 интервью с потенциальными клиентами', 'cert', 300, 'sales'],
        ['Зарегистрировать компанию', 'cert', 300, 'finance'],
      ] },
      { name: 'MVP', quests: [
        ['Создать сайт', 'cert', 300, 'product'],
        ['Сделать MVP / первую коллекцию', 'project', 500, 'product'],
        ['Опубликовать первую коллекцию / продукт', 'project', 500, 'brand'],
        ['Публичный запуск (Launch Day)', 'project', 1000, 'brand', { boss: true }],
      ] },
      { name: 'FIRST CUSTOMERS → REVENUE', quests: [
        ['Получить первых 10 клиентов', 'project', 700, 'sales'],
        ['Найти партнёра', 'project', 800, 'sales'],
        ['Первая выручка', 'project', 800, 'finance'],
        ['Первый питч инвестору', 'project', 1500, 'finance', { boss: true, onFail: { route: 'Bootstrap Strategy', quests: [
          { title: 'Sales-квест 1: закрыть 5 сделок', xp: 500, cat: 'sales', tier: 'project' },
          { title: 'Sales-квест 2: запустить предзаказы', xp: 500, cat: 'sales', tier: 'project' },
          { title: 'Sales-квест 3: выйти в операционный ноль', xp: 500, cat: 'finance', tier: 'project' },
        ] } }],
      ] },
      { name: 'TEAM → GROWTH', quests: [
        ['Нанять первого сотрудника', 'internship', 1000, 'team'],
        ['Провести мероприятие', 'internship', 1000, 'brand'],
        ['Подать заявку на патент / защиту дизайна', 'project', 800, 'rnd'],
        ['100 платных заказов', 'internship', 1500, 'sales'],
      ] },
      { name: 'EXPANSION → INTERNATIONAL', quests: [
        ['Выйти в новый город', 'internship', 1500, 'international'],
        ['Выйти на международный рынок', 'intl', 2500, 'international'],
        ['Первые $10,000 выручки', 'intl', 3000, 'finance', { boss: true, onFail: { route: 'Revenue Sprint', quests: [
          { title: 'Пересобрать оффер и цены', xp: 300, cat: 'sales', tier: 'cert' },
          { title: 'Запустить 2 новых канала продаж', xp: 800, cat: 'sales', tier: 'project' },
          { title: 'Повторная попытка: $10,000 выручки', xp: 3000, cat: 'finance', tier: 'intl', boss: true },
        ] } }],
      ] },
    ],
  }),

  ielts: (ctx) => ({
    kind: 'ielts', worldType: 'personal', title: `IELTS ${ctx.score || '7.0'}`, days: 180,
    phases: [
      { name: 'Диагностика', quests: [
        ['Пройти диагностический тест IELTS', 'task', 80, 'languages'],
        ['Составить план по 4 секциям', 'task', 60, 'languages'],
      ] },
      { name: 'База', quests: [
        ['Выучить 500 академических слов', 'task', 100, 'languages'],
        ['Listening: 20 тестов', 'cert', 250, 'languages'],
        ['Reading: 20 тестов', 'cert', 250, 'languages'],
      ] },
      { name: 'Writing & Speaking', quests: [
        ['Writing Task 1 + 2: 15 эссе с проверкой', 'cert', 400, 'languages'],
        ['Speaking: 10 сессий с партнёром/тьютором', 'cert', 300, 'languages'],
        ['Пробный экзамен — 6.0+', 'cert', 400, 'languages', { boss: true }],
      ] },
      { name: 'Финиш', quests: [
        ['Пробный экзамен — 6.5+', 'cert', 500, 'languages'],
        ['Неделя экзаменационного режима', 'task', 100, 'languages'],
        [`IELTS EXAM — ${ctx.score || '7.0'}`, 'intl', 2000, 'languages', { boss: true, onFail: { route: 'Retake Route', quests: [
          { title: 'Разбор результатов по секциям', xp: 80, tier: 'task' },
          { title: 'Интенсив по слабой секции (4 недели)', xp: 400, tier: 'cert' },
          { title: `Пересдача IELTS — ${ctx.score || '7.0'}`, xp: 2000, tier: 'intl', boss: true },
        ] } }],
      ] },
    ],
  }),

  university: (ctx) => ({
    kind: 'university', worldType: 'academic', title: `Поступить в ${ctx.uni || 'топовый университет'}`, days: 365,
    phases: [
      { name: 'Стратегия', quests: [
        ['Составить список вузов и требований', 'task', 80, 'education'],
        ['Найти ментора/выпускника вуза', 'task', 100, 'education'],
      ] },
      { name: 'Академический профиль', quests: [
        ['Подготовка к SAT/ACT — пробник 1400+', 'cert', 400, 'education'],
        ['Олимпиада / конкурс — призовое место', 'intl', 2000, 'education'],
        ['Онлайн-курс топ-вуза с сертификатом (MIT OCW, CS50)', 'cert', 300, 'education'],
      ] },
      { name: 'Исследования и проекты', quests: [
        ['Исследовательский проект с ментором', 'project', 1000, 'science'],
        ['Подать статью в журнал', 'publication', 1500, 'science'],
        ['Лидерство / волонтёрский проект', 'project', 700, 'growth'],
      ] },
      { name: 'Экзамены', quests: [
        ['IELTS 7.5+ / TOEFL 105+', 'intl', 2000, 'languages', { boss: true }],
        ['SAT 1500+', 'intl', 2000, 'education', { boss: true }],
      ] },
      { name: 'Заявка', quests: [
        ['Мотивационное эссе — 5 черновиков', 'cert', 400, 'education'],
        ['Получить рекомендательные письма', 'cert', 300, 'education'],
        ['UNIVERSITY APPLICATION', 'project', 1500, 'education', { boss: true }],
        [`Поступление в ${ctx.uni || 'университет мечты'}`, 'university', 8000, 'education', { boss: true, onFail: { route: 'Gap Year Route', quests: [
          { title: 'Поступить в сильный вуз из резервного списка', xp: 5000, tier: 'university' },
          { title: 'Год исследований/стажировки для усиления профиля', xp: 1500, tier: 'internship', cat: 'career' },
          { title: 'Повторная подача / перевод', xp: 8000, tier: 'university', boss: true },
        ] } }],
      ] },
    ],
  }),

  developer: (ctx) => ({
    kind: 'developer', worldType: 'developer', title: ctx.role ? `Стать ${ctx.role}` : 'Стать сильным software engineer', days: 180,
    phases: [
      { name: 'Основы', quests: [
        ['Python: основы + 50 задач', 'task', 100, 'tech'],
        ['Git & GitHub: первый репозиторий', 'task', 80, 'tech'],
        ['CS50 / курс по алгоритмам с сертификатом', 'cert', 400, 'education'],
      ] },
      { name: 'Алгоритмы и проекты', quests: [
        ['100 алгоритмических задач (LeetCode)', 'cert', 500, 'tech'],
        ['Pet-проект на GitHub', 'project', 700, 'tech'],
        ['Задеплоить рабочее приложение', 'project', 1000, 'tech'],
      ] },
      { name: 'Реальный мир', quests: [
        ['Первый open-source pull request', 'cert', 500, 'tech'],
        ['100 реальных пользователей продукта', 'project', 1500, 'business'],
        ['APP STORE / PRODUCTION RELEASE', 'project', 1500, 'tech', { boss: true }],
      ] },
      { name: 'Карьера', quests: [
        ['Резюме + LinkedIn + портфолио', 'task', 100, 'career'],
        ['Пройти техническое собеседование', 'cert', 500, 'career', { boss: true }],
        ['Стажировка / первая работа Junior', 'internship', 2000, 'career', { boss: true, onFail: { route: 'Freelance Route', quests: [
          { title: '3 фриланс-заказа с отзывами', xp: 800, tier: 'project', cat: 'career' },
          { title: 'Ещё 2 проекта в портфолио', xp: 700, tier: 'project', cat: 'tech' },
          { title: 'Повторная попытка: стажировка', xp: 2000, tier: 'internship', cat: 'career', boss: true },
        ] } }],
      ] },
    ],
  }),

  academic: () => ({
    kind: 'academic', worldType: 'research', title: 'Опубликовать исследование', days: 240,
    phases: [
      { name: 'Idea', quests: [['Сформулировать исследовательский вопрос', 'task', 100, 'science'], ['Найти научного руководителя', 'cert', 300, 'science']] },
      { name: 'Literature Review', quests: [['Прочитать и разобрать 30 статей', 'cert', 400, 'science'], ['Написать обзор литературы', 'cert', 500, 'science']] },
      { name: 'Experiment', quests: [['Дизайн эксперимента / методология', 'cert', 300, 'science'], ['Провести эксперимент и собрать данные', 'project', 1000, 'science']] },
      { name: 'Paper', quests: [['Написать черновик статьи', 'project', 800, 'science'], ['Получить фидбэк от 2 экспертов', 'cert', 300, 'science']] },
      { name: 'Submission → Review', quests: [['Подать статью в журнал (Scopus/WoS)', 'project', 700, 'science', { boss: true }], ['Ответить рецензентам (revision)', 'cert', 500, 'science']] },
      { name: 'Publication', quests: [['PUBLICATION — статья опубликована', 'publication', 2500, 'science', { boss: true, onFail: { route: 'Resubmission Route', quests: [
        { title: 'Учесть замечания рецензентов', xp: 300, tier: 'cert' },
        { title: 'Выбрать другой подходящий журнал', xp: 80, tier: 'task' },
        { title: 'Повторная подача и публикация', xp: 2500, tier: 'publication', boss: true },
      ] } }], ['Выступить на конференции', 'intl', 2000, 'media']] },
    ],
  }),

  kids: () => ({
    kind: 'kids', worldType: 'kids', title: 'Большое приключение', days: 30,
    phases: [
      { name: '🌱 Starter', quests: [['Прочитать 10 страниц книги', 'kid_small', 30, 'reading'], ['Заправить кровать сам(а)', 'kid_small', 20, 'independence'], ['10 минут зарядки', 'kid_small', 30, 'sport']] },
      { name: '🧭 Explorer', quests: [['Узнать 5 фактов о космосе', 'kid_small', 40, 'study'], ['Нарисовать своё изобретение', 'kid_mid', 60, 'creativity'], ['Прочитать целую книгу', 'kid_mid', 100, 'reading']] },
      { name: '🛠 Builder', quests: [['Собрать модель / поделку', 'kid_mid', 100, 'projects'], ['Неделя зарядки каждый день', 'kid_mid', 120, 'sport'], ['Помочь приготовить ужин', 'kid_small', 40, 'independence']] },
      { name: '🚀 Inventor', quests: [['Придумать и сделать свой проект', 'kid_big', 200, 'projects'], ['Выучить стихотворение', 'kid_mid', 80, 'study']] },
      { name: '🏆 Master', quests: [['Мини-выставка: показать проект семье', 'kid_big', 300, 'projects', { boss: true }]] },
    ],
  }),

  sen: () => ({
    kind: 'sen', worldType: 'kids', title: 'Мои маленькие шаги', days: 28,
    phases: [
      { name: '☀️ Утро', quests: [['🪥 Почистить зубы', 'kid_small', 20, 'independence'], ['👕 Одеться', 'kid_small', 20, 'independence'], ['🥣 Позавтракать', 'kid_small', 20, 'independence']] },
      { name: '📘 Учёба', quests: [['✏️ 1 страница прописи', 'kid_small', 30, 'study'], ['🔢 5 примеров', 'kid_small', 30, 'study'], ['📖 Посмотреть книгу с картинками', 'kid_small', 30, 'reading']] },
      { name: '🎨 Творчество', quests: [['🖍 Нарисовать рисунок', 'kid_small', 30, 'creativity'], ['🧩 Собрать пазл', 'kid_small', 30, 'projects']] },
      { name: '⚽ Движение', quests: [['🚶 Прогулка 15 минут', 'kid_small', 30, 'sport'], ['🤸 5 упражнений', 'kid_small', 30, 'sport']] },
      { name: '⭐ Неделя', quests: [['⭐ Все шаги недели', 'kid_mid', 100, 'independence', { boss: true }]] },
    ],
  }),

  generic: (ctx) => ({
    kind: 'generic', worldType: 'personal', title: ctx.text.length > 70 ? ctx.text.slice(0, 67) + '…' : ctx.text, days: 90,
    phases: [
      { name: 'Старт', quests: [['Определить критерии успеха цели', 'task', 80, 'growth'], ['Сделать первый маленький шаг', 'task', 60, 'growth']] },
      { name: 'Система', quests: [['Привычка 14 дней подряд', 'cert', 250, 'growth'], ['Найти наставника / сообщество', 'cert', 200, 'growth']] },
      { name: 'Результат', quests: [['Первый подтверждаемый результат', 'project', 700, 'growth'], ['Показать результат публично', 'cert', 300, 'media']] },
      { name: 'Финал', quests: [['ГЛАВНОЕ ИСПЫТАНИЕ цели', 'project', 1500, 'growth', { boss: true }]] },
    ],
  }),
};

export function detectKinds(text, mode) {
  const t = text.toLowerCase();
  if (mode === 'sen') return ['sen'];
  if (mode === 'kids') return ['kids'];
  const kinds = [];
  if (/ielts|toefl|английск|english/.test(t) && !/поступ|универ|harvard|mit\b/.test(t)) kinds.push('ielts');
  if (/поступ|университет|универ|harvard|mit\b|stanford|oxford|cambridge|college|колледж/.test(t)) kinds.push('university');
  if (/компани|стартап|startup|бизнес|business|бренд|fashion|house|магазин|запуст|масштаб|company/.test(t)) kinds.push('company');
  if (/developer|разработчик|программист|software|engineer|инженер|ai\b|ии\b|frontend|backend|coding|код/.test(t)) kinds.push('developer');
  if (/исследова|research|публикац|статью|статьи|учён|ученый|phd|наук/.test(t) && !kinds.includes('university')) kinds.push('academic');
  if (!kinds.length) kinds.push(mode === 'company' ? 'company' : mode === 'academic' ? 'academic' : mode === 'career' ? 'developer' : 'generic');
  return kinds;
}

/** Мечта → план игры (без изменения состояния). */
export function generate(text, { mode = 'life' } = {}) {
  const ctx = {
    text: text.trim(),
    name: parseName(text),
    score: (text.match(/ielts\s*(\d(?:[.,]\d)?)/i) || [])[1]?.replace(',', '.'),
    uni: (text.match(/\b(harvard|mit|stanford|oxford|cambridge|nus|kaist|nazarbayev university|nu)\b/i) || [])[1],
    role: (text.match(/(ai\/software engineer|software engineer|ai engineer|data scientist|frontend|backend|mobile developer|ai-инженер)/i) || [])[1],
  };
  if (ctx.uni) ctx.uni = ctx.uni.length <= 3 ? ctx.uni.toUpperCase() : ctx.uni[0].toUpperCase() + ctx.uni.slice(1);
  const kinds = detectKinds(text, mode);
  const parts = kinds.map((k) => T[k](ctx));
  const days = parseDuration(text) || Math.max(...parts.map((p) => p.days));
  // Квесты каждого шаблона растягиваются на весь срок и сливаются по дням.
  const quests = [];
  for (const part of parts) {
    const n = part.phases.length;
    part.phases.forEach((ph, pi) => {
      ph.quests.forEach((spec, qi) => {
        const [title, tier, xp, cat, opt = {}] = spec;
        const r = (pi + (qi + 1) / (ph.quests.length + 0.0001)) / n;
        quests.push({ title, tier, xp, cat, boss: !!opt.boss, onFail: opt.onFail || null, phase: ph.name, kind: part.kind, day: Math.max(1, Math.min(days, Math.round(r * days))) });
      });
    });
  }
  quests.sort((a, b) => a.day - b.day);
  const main = parts[0];
  const title = parts.length > 1 ? parts.map((p) => p.title).join(' + ') : main.title;
  const totalXP = quests.reduce((s, q) => s + q.xp, 0);
  const bosses = quests.filter((q) => q.boss).length;
  return { title, dream: ctx.text, days, kinds, worldType: main.worldType, worldName: ctx.name, quests, totalXP, bosses };
}

const MIRROR = { product: 'business', team: 'business', finance: 'business', sales: 'business', technology: 'tech', rnd: 'science', brand: 'media', international: 'business', impact: 'growth' };

function fitCat(world, cat) {
  const cats = (WORLD_TYPES[world.type] || WORLD_TYPES.personal).cats;
  if (cats.includes(cat)) return cat;
  if (MIRROR[cat] && cats.includes(MIRROR[cat])) return MIRROR[cat];
  return cats[0];
}

/** Применить план: создать карту и квесты. Достижения в рабочем мире дают XP и личному миру (связанные миры). */
export function applyPlan(state, plan, { worldId, startDate = Date.now(), linkPersonal = true } = {}) {
  const world = state.worlds.find((w) => w.id === worldId) || state.worlds[0];
  const personal = state.worlds.find((w) => w.type === 'personal' || w.type === 'kids');
  const rm = { id: uid('rm'), title: plan.title, dream: plan.dream, worldId: world.id, days: plan.days, startDate, questIds: [], kinds: plan.kinds };
  const byPhase = {};
  for (const spec of plan.quests) {
    const awards = [{ worldId: world.id, cat: fitCat(world, spec.cat), xp: spec.xp }];
    if (linkPersonal && personal && personal.id !== world.id) awards.push({ worldId: personal.id, cat: fitCat(personal, spec.cat), xp: Math.round(spec.xp * 0.5) });
    const key = spec.kind + '|' + spec.phase;
    const prep = (byPhase[key] ||= []);
    const q = makeQuest({
      title: spec.title, tier: spec.tier, awards, boss: spec.boss, onFail: spec.onFail, roadmapId: rm.id, day: spec.day, phase: spec.phase,
      requires: spec.boss ? prep.filter((p) => !p.boss).map((p) => p.id) : [],
    });
    prep.push(q);
    state.quests.push(q);
    rm.questIds.push(q.id);
  }
  state.roadmaps.push(rm);
  return rm;
}

export const daysAgo = (n) => Date.now() - n * DAY_MS;
