// LIFE RPG — игровое ядро (чистая логика, без DOM; покрыто тестами).
import { RANKS, COMPANY_RANKS, KIDS_RANKS, CATEGORY_RANKS, WORLD_TYPES, ALL_TIERS, CATEGORIES } from './data.js';

export const DAY_MS = 86400000;
let _seq = 0;
export const uid = (p = 'id') => `${p}_${Date.now().toString(36)}${(_seq++).toString(36)}${Math.random().toString(36).slice(2, 6)}`;

export function emptyState() {
  return {
    version: 1,
    profile: null, // { name, age, location, mode, dream, createdAt }
    worlds: [],
    quests: [],
    roadmaps: [],
    achievements: [],
    log: [],
    settings: { calm: false },
  };
}

// ---------- ранги ----------
export const SCALES = { person: RANKS, company: COMPANY_RANKS, kids: KIDS_RANKS, category: CATEGORY_RANKS };

export function rankFor(xp, scale = 'person') {
  const list = SCALES[scale] || RANKS;
  let idx = 0;
  for (let i = 0; i < list.length; i++) if (xp >= list[i].min) idx = i;
  const rank = list[idx];
  const next = list[idx + 1] || null;
  const span = next ? next.min - rank.min : 1;
  const progress = next ? Math.min(1, (xp - rank.min) / span) : 1;
  return { rank, next, idx, progress, toNext: next ? next.min - xp : 0 };
}

export const worldScale = (w) => (WORLD_TYPES[w?.type] || WORLD_TYPES.personal).scale;
export const playerScale = (state) => (state.profile && (state.profile.mode === 'kids' || state.profile.mode === 'sen') ? 'kids' : 'person');
export const tierById = (id) => ALL_TIERS.find((t) => t.id === id) || null;

// ---------- подсчёт XP ----------
export const isDone = (q) => q.status === 'done';
// Verified XP: результат по стандартной шкале + доказательство. Свои критерии никогда не верифицируются.
export const isVerified = (q) => isDone(q) && !q.custom && !!(q.proof && String(q.proof).trim());

export function questXP(q, worldId = null) {
  return (q.awards || []).filter((a) => !worldId || a.worldId === worldId).reduce((s, a) => s + (a.xp || 0), 0);
}

export function worldXP(state, worldId, verifiedOnly = false) {
  return state.quests.filter((q) => (verifiedOnly ? isVerified(q) : isDone(q))).reduce((s, q) => s + questXP(q, worldId), 0);
}

const personWorldIds = (state) => state.worlds.filter((w) => w.type !== 'company').map((w) => w.id);

// XP игрока = все личные миры (компании прокачиваются отдельно).
export function playerXP(state, verifiedOnly = false) {
  const ids = new Set(personWorldIds(state));
  return state.quests
    .filter((q) => (verifiedOnly ? isVerified(q) : isDone(q)))
    .reduce((s, q) => s + (q.awards || []).filter((a) => ids.has(a.worldId)).reduce((t, a) => t + a.xp, 0), 0);
}

export function categoryXP(state, worldId = null) {
  const ids = worldId ? new Set([worldId]) : new Set(personWorldIds(state));
  const out = {};
  for (const q of state.quests) {
    if (!isDone(q)) continue;
    for (const a of q.awards || []) if (ids.has(a.worldId)) out[a.cat] = (out[a.cat] || 0) + a.xp;
  }
  return out;
}

// ---------- квесты ----------
export function questById(state, id) { return state.quests.find((q) => q.id === id); }

export function isLocked(state, q) {
  if (!q.requires || !q.requires.length) return false;
  return q.requires.some((rid) => { const r = questById(state, rid); return r && !isDone(r) && r.status !== 'failed'; });
}

export function makeQuest(p) {
  return {
    id: p.id || uid('q'),
    title: p.title,
    desc: p.desc || '',
    tier: p.tier || null,
    custom: !!p.custom,
    awards: p.awards || [],
    status: p.status || 'open', // open | pending | done | failed
    proof: p.proof || '',
    boss: !!p.boss,
    requires: p.requires || [],
    onFail: p.onFail || null, // { route, quests:[{title, xp, cat, tier}] }
    roadmapId: p.roadmapId || null,
    day: p.day || null,
    phase: p.phase || '',
    branch: p.branch || null,
    createdAt: p.createdAt || Date.now(),
    doneAt: p.doneAt || null,
  };
}

export function snapshot(state) {
  const pxp = playerXP(state);
  return {
    player: { xp: pxp, rank: rankFor(pxp, playerScale(state)).rank.id },
    worlds: Object.fromEntries(state.worlds.map((w) => { const x = worldXP(state, w.id); return [w.id, { xp: x, rank: rankFor(x, worldScale(w)).rank.id }]; })),
  };
}

export function rankUps(before, after, state) {
  const ups = [];
  if (before.player.rank !== after.player.rank && after.player.xp > before.player.xp) ups.push({ who: state.profile?.name || 'Игрок', from: before.player.rank, to: after.player.rank, scale: playerScale(state) });
  for (const w of state.worlds) {
    const b = before.worlds[w.id], a = after.worlds[w.id];
    if (b && a && b.rank !== a.rank && a.xp > b.xp) ups.push({ who: w.name, worldId: w.id, from: b.rank, to: a.rank, scale: worldScale(w) });
  }
  return ups;
}

function logEvent(state, text, xp = 0) {
  state.log.unshift({ at: Date.now(), text, xp });
  state.log = state.log.slice(0, 200);
}

/** Отметить квест выполненным. В детском режиме без родителя → 'pending'. */
export function completeQuest(state, id, { proof = '', needsParent = false } = {}) {
  const q = questById(state, id);
  if (!q || isDone(q)) return { ok: false, reason: 'already' };
  if (isLocked(state, q)) return { ok: false, reason: 'locked' };
  if (proof) q.proof = proof;
  if (needsParent) { q.status = 'pending'; logEvent(state, `Ждёт подтверждения: ${q.title}`); return { ok: true, pending: true, xp: 0 }; }
  q.status = 'done';
  q.doneAt = Date.now();
  const xp = questXP(q);
  logEvent(state, `✓ ${q.title}`, xp);
  return { ok: true, xp, quest: q };
}

export function confirmQuest(state, id) {
  const q = questById(state, id);
  if (!q || q.status !== 'pending') return { ok: false };
  q.status = 'done';
  q.doneAt = Date.now();
  if (!q.proof) q.proof = 'Подтверждение родителя';
  const xp = questXP(q);
  logEvent(state, `✓ Родитель подтвердил: ${q.title}`, xp);
  return { ok: true, xp, quest: q };
}

export function undoQuest(state, id) {
  const q = questById(state, id);
  if (!q) return;
  q.status = 'open'; q.doneAt = null;
}

export function addProof(state, id, proof) {
  const q = questById(state, id);
  if (q) q.proof = proof;
  return q;
}

/** Провал не проигрыш: игра перестраивает маршрут. */
export function failQuest(state, id) {
  const q = questById(state, id);
  if (!q || isDone(q)) return { ok: false };
  q.status = 'failed';
  const mainAward = (q.awards && q.awards[0]) || { worldId: state.worlds[0]?.id, cat: 'growth', xp: 300 };
  const plan = q.onFail || {
    route: 'Новый маршрут',
    quests: [
      { title: `Разобрать, что помешало: «${q.title}»`, xp: 80, tier: 'task' },
      { title: 'Сделать маленький промежуточный шаг', xp: Math.max(100, Math.round(mainAward.xp * 0.3)), tier: 'cert' },
      { title: `Повторная попытка: ${q.title}`, xp: mainAward.xp, tier: q.tier, boss: q.boss },
    ],
  };
  const created = [];
  let prev = null;
  plan.quests.forEach((p, i) => {
    const awards = (q.awards || []).map((a, j) => ({ ...a, xp: j === 0 ? (p.xp ?? a.xp) : Math.round((p.xp ?? a.xp) * (a.xp / (mainAward.xp || 1))), cat: j === 0 ? (p.cat || a.cat) : a.cat }));
    const nq = makeQuest({
      title: p.title,
      tier: p.tier || q.tier,
      awards: awards.length ? awards : [{ ...mainAward, xp: p.xp }],
      boss: !!p.boss,
      roadmapId: q.roadmapId,
      day: q.day ? q.day + i + 1 : null,
      phase: q.phase,
      branch: plan.route,
      requires: p.boss && prev ? created.filter((c) => !c.boss).map((c) => c.id) : [],
    });
    created.push(nq);
    prev = nq;
  });
  const idx = state.quests.indexOf(q);
  state.quests.splice(idx + 1, 0, ...created);
  // квесты, которые ждали проваленный, теперь ждут новую ветку
  for (const other of state.quests) {
    if (other.requires?.includes(q.id)) other.requires = other.requires.filter((r) => r !== q.id).concat(created[created.length - 1].id);
  }
  if (q.roadmapId) {
    const rm = state.roadmaps.find((r) => r.id === q.roadmapId);
    if (rm) rm.questIds.splice(rm.questIds.indexOf(q.id) + 1, 0, ...created.map((c) => c.id));
  }
  logEvent(state, `🔄 ${q.title} — маршрут перестроен: ${plan.route}`);
  return { ok: true, route: plan.route, created };
}

/** Быстро добавить реальный результат (вне карты). */
export function addResult(state, { title, tier, custom = false, awards, proof = '' }) {
  const t = tierById(tier);
  // Стандартная шкала: каждый мир — не выше максимума тарифа, а самая большая награда — не ниже минимума.
  const clean = awards.filter((a) => a.xp > 0).map((a) => ({ ...a, xp: Math.round(!custom && t ? Math.min(t.max, a.xp) : a.xp) }));
  if (!custom && t && clean.length) {
    const top = clean.reduce((m, a) => (a.xp > m.xp ? a : m), clean[0]);
    top.xp = Math.max(t.min, top.xp);
  }
  const q = makeQuest({ title, tier: custom ? null : tier, custom, awards: clean, proof, status: 'done', doneAt: Date.now() });
  state.quests.unshift(q);
  logEvent(state, `✓ ${title}`, questXP(q));
  return q;
}

// ---------- карты ----------
export function roadmapQuests(state, rm) {
  return rm.questIds.map((id) => questById(state, id)).filter(Boolean);
}

export function roadmapProgress(state, rm, now = Date.now()) {
  const qs = roadmapQuests(state, rm);
  const day = Math.max(1, Math.min(rm.days, Math.floor((now - rm.startDate) / DAY_MS) + 1));
  const done = qs.filter(isDone).length;
  const total = qs.filter((q) => q.status !== 'failed').length;
  return { day, days: rm.days, timePct: day / rm.days, done, total, pct: total ? done / total : 0, xp: qs.filter(isDone).reduce((s, q) => s + questXP(q, rm.worldId), 0) };
}

export function currentQuest(state, rm) {
  return roadmapQuests(state, rm).find((q) => !isDone(q) && q.status !== 'failed' && !isLocked(state, q)) || null;
}

/** «Сегодня у меня три маленьких квеста». */
export function todayQuests(state, n = 3) {
  const out = [];
  for (const rm of state.roadmaps) for (const q of roadmapQuests(state, rm)) if (!isDone(q) && q.status !== 'failed' && !isLocked(state, q)) out.push(q);
  out.sort((a, b) => (a.boss - b.boss) || ((a.day || 0) - (b.day || 0)));
  return out.slice(0, n);
}

// ---------- слабое место ----------
export function weakSpot(state, worldId) {
  const w = state.worlds.find((x) => x.id === worldId);
  if (!w) return null;
  const cats = (WORLD_TYPES[w.type] || WORLD_TYPES.personal).cats;
  const xp = categoryXP(state, worldId);
  const sorted = cats.map((c) => ({ cat: c, xp: xp[c] || 0 })).sort((a, b) => a.xp - b.xp);
  const weak = sorted[0];
  const open = state.quests.filter((q) => !isDone(q) && q.status !== 'failed' && (q.awards || []).some((a) => a.worldId === worldId && a.cat === weak.cat)).slice(0, 3);
  const generic = SUGGESTIONS[weak.cat] || [`Сделать первый шаг в направлении «${CATEGORIES[weak.cat]?.label || weak.cat}»`, 'Найти наставника в этом направлении', 'Получить первый подтверждаемый результат'];
  return { weak, rank: rankFor(weak.xp, 'category').rank.id, open, suggestions: generic.slice(0, 3) };
}

const SUGGESTIONS = {
  sales: ['Провести 20 звонков/встреч с клиентами', 'Закрыть 3 новые сделки', 'Запустить реферальную программу'],
  finance: ['Составить финмодель на 12 месяцев', 'Подать заявку на грант', 'Выйти в операционный ноль'],
  team: ['Нанять первого сотрудника', 'Описать роли и процессы', 'Найти ментора/адвайзера'],
  brand: ['Опубликовать 10 постов о продукте', 'Получить первую публикацию в СМИ', 'Выступить на мероприятии'],
  international: ['Найти зарубежного партнёра', 'Перевести продукт на английский', 'Первый зарубежный клиент'],
  product: ['Собрать фидбэк 10 пользователей', 'Выпустить новую версию', 'Описать roadmap продукта'],
  technology: ['Автоматизировать ключевой процесс', 'Внедрить AI в продукт', 'Провести техаудит'],
  rnd: ['Подать заявку на патент', 'Провести эксперимент', 'Опубликовать исследование'],
  impact: ['Измерить социальный эффект', 'Запустить проект для людей с ОВЗ', 'Партнёрство с фондом'],
  languages: ['Пройти пробный экзамен', '30 дней практики подряд', 'Выступить на иностранном языке'],
  health: ['Тренировки 3 раза в неделю месяц', 'Чек-ап здоровья', 'Режим сна 30 дней'],
  science: ['Написать обзор литературы', 'Написать профессору', 'Подать тезисы на конференцию'],
  tech: ['Решить 30 алгоритмических задач', 'Задеплоить рабочее приложение', 'Сделать PR в open source'],
  media: ['Выступить публично', 'Опубликовать 5 видео', 'Дать интервью'],
  career: ['Подать 10 заявок на стажировку', 'Обновить резюме и LinkedIn', 'Пройти собеседование'],
  education: ['Закончить онлайн-курс с сертификатом', 'Участвовать в олимпиаде', 'Прочитать 3 профильные книги'],
  business: ['Запустить мини-проект', 'Получить первого клиента', 'Сделать сайт проекта'],
  growth: ['Ввести систему планирования', 'Вести дневник 30 дней', 'Прочитать 2 книги'],
  life: ['Время с семьёй без телефона', 'Новое хобби', 'Поездка в новое место'],
};

// ---------- достижения ----------
const ACH_RULES = [
  { id: 'first_quest', icon: '⚔️', title: 'Первый квест', desc: 'Выполнен первый реальный результат', test: (s) => s.quests.some(isDone) },
  { id: 'first_verified', icon: '✅', title: 'Подтверждено', desc: 'Первый результат с доказательством', test: (s) => s.quests.some(isVerified) },
  { id: 'first_boss', icon: '🔥', title: 'Boss повержен', desc: 'Пройдена первая Boss Battle', test: (s) => s.quests.some((q) => q.boss && isDone(q)) },
  { id: 'comeback', icon: '🔄', title: 'Не сдаюсь', desc: 'Провал превращён в новый маршрут', test: (s) => s.quests.some((q) => q.branch && isDone(q)) },
  { id: 'publication', icon: '📄', title: 'First Research Publication', desc: 'Первая научная публикация', test: (s) => s.quests.some((q) => isDone(q) && (q.tier === 'publication' || /публикац|publication|scopus|статья опубликована/i.test(q.title))) },
  { id: 'international', icon: '🌐', title: 'First International Step', desc: 'Первый выход на международный уровень', test: (s) => s.quests.some((q) => isDone(q) && (q.tier === 'intl' || /международ|international|зарубеж/i.test(q.title))) },
  { id: 'multiworld', icon: '🪐', title: 'Связанные миры', desc: 'Один результат прокачал несколько миров', test: (s) => s.quests.some((q) => isDone(q) && new Set((q.awards || []).map((a) => a.worldId)).size >= 3) },
  { id: 'ten_quests', icon: '🏅', title: '10 квестов', desc: 'Выполнено 10 квестов', test: (s) => s.quests.filter(isDone).length >= 10 },
  { id: 'fifty_quests', icon: '🎖', title: '50 квестов', desc: 'Выполнено 50 квестов', test: (s) => s.quests.filter(isDone).length >= 50 },
];

export function checkAchievements(state) {
  const have = new Set(state.achievements.map((a) => a.id));
  const fresh = [];
  const add = (a) => { if (!have.has(a.id)) { const x = { id: a.id, icon: a.icon, title: a.title, desc: a.desc, at: Date.now() }; state.achievements.unshift(x); have.add(a.id); fresh.push(x); } };
  for (const r of ACH_RULES) if (r.test(state)) add(r);
  // боссы и пройденные карты дают именные ачивки
  for (const q of state.quests) if (q.boss && isDone(q)) add({ id: `boss_${q.id}`, icon: '🏆', title: `Boss: ${q.title}`, desc: 'Boss Battle пройдена' });
  for (const rm of state.roadmaps) {
    const p = roadmapProgress(state, rm);
    if (p.total && p.done === p.total) add({ id: `map_${rm.id}`, icon: '🗺', title: `Карта пройдена: ${rm.title}`, desc: `${p.done} квестов` });
  }
  // ранги игрока
  const pr = rankFor(playerXP(state), playerScale(state));
  for (let i = 1; i <= pr.idx; i++) { const r = SCALES[playerScale(state)][i]; add({ id: `rank_${playerScale(state)}_${r.id}`, icon: r.icon || '⭐', title: `Rank ${r.id} — ${r.name}`, desc: `Достигнут порог ${r.min.toLocaleString('ru-RU')} XP` }); }
  return fresh;
}

// ---------- миры ----------
export function addWorld(state, { name, type, emoji }) {
  const w = { id: uid('w'), name, type, emoji: emoji || WORLD_TYPES[type]?.emoji || '🌐', createdAt: Date.now() };
  state.worlds.push(w);
  return w;
}

export const fmt = (n) => Math.round(n).toLocaleString('ru-RU').replace(/ /g, ' ');
