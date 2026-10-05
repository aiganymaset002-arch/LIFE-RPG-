// LIFE RPG — мобильный интерфейс.
import { RANKS, RANK_INFO, CATEGORIES, WORLD_TYPES, MODES, XP_TIERS, KIDS_TIERS, COMPANY_STAGES, PROOF_TYPES } from './data.js';
import * as G from './core.js';
import { generate, applyPlan } from './gamemaster.js';
import { buildDemo } from './demo.js';

const KEY = 'liferpg.v1';
const $app = document.getElementById('app');
const $overlay = document.getElementById('overlay');
const $toasts = document.getElementById('toasts');

let state = load();
const ui = { tab: 'home', rmId: null, worldId: null, sheet: null, gm: { text: '', plan: null, worldId: '' }, ob: { step: 0, mode: 'life' } };

function load() {
  try { const raw = localStorage.getItem(KEY); if (raw) return { ...G.emptyState(), ...JSON.parse(raw) }; } catch (e) { /* пусто */ }
  return G.emptyState();
}
function save() { try { localStorage.setItem(KEY, JSON.stringify(state)); } catch (e) { /* нет хранилища */ } }

const h = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const fmt = G.fmt;
const isKids = () => state.profile?.mode === 'kids';
const isSen = () => state.profile?.mode === 'sen';
const parentConfirm = () => state.settings.parentConfirm ?? isKids();
const worldById = (id) => state.worlds.find((w) => w.id === id);
const unit = () => (isKids() || isSen() ? '⭐' : 'XP');
const cat = (c) => CATEGORIES[c] || { label: c, emoji: '•', color: '#888' };

// ---------- мутации с Level Up ----------
function mutate(fn) {
  const before = G.snapshot(state);
  const res = fn();
  const fresh = G.checkAchievements(state);
  const after = G.snapshot(state);
  const ups = G.rankUps(before, after, state);
  save();
  render();
  const gained = after.player.xp - before.player.xp + Object.values(after.worlds).reduce((s, w) => s + w.xp, 0) - Object.values(before.worlds).reduce((s, w) => s + w.xp, 0);
  if (ups.length) showLevelUp(ups, res?.xp || 0, fresh);
  else {
    if (res?.xp) toast(`+${fmt(res.xp)} XP`, 'xp');
    fresh.forEach((a) => toast(`${a.icon} Achievement unlocked: ${a.title}`, 'ach'));
  }
  return { res, gained };
}

function toast(text, kind = '') {
  const el = document.createElement('div');
  el.className = 'toast ' + kind;
  el.textContent = text;
  $toasts.appendChild(el);
  setTimeout(() => el.classList.add('out'), 2600);
  setTimeout(() => el.remove(), 3100);
}

function showLevelUp(ups, xp, fresh) {
  const u = ups[0];
  const scale = G.SCALES[u.scale];
  const to = scale.find((r) => r.id === u.to);
  const calm = isSen() || state.settings.calm;
  openSheet(`
    <div class="levelup ${calm ? 'calm' : ''}">
      ${calm ? '' : '<div class="burst"></div>'}
      <div class="lu-trophy">🏆</div>
      <div class="lu-title">LEVEL UP!</div>
      <div class="lu-who">${h(u.who)}</div>
      <div class="lu-ranks"><span class="rk rk-${u.from}">${u.from}</span><span class="arrow">→</span><span class="rk rk-${u.to} big">${u.to}</span></div>
      <div class="lu-name">${h(to?.name || '')}${to?.ru ? ' · ' + h(to.ru) : ''}</div>
      ${xp ? `<div class="lu-xp">+${fmt(xp)} XP</div>` : ''}
      ${ups.slice(1).map((x) => `<div class="lu-more">${h(x.who)}: ${x.from} → ${x.to}</div>`).join('')}
      ${fresh.map((a) => `<div class="lu-ach">${a.icon} Achievement unlocked: <b>${h(a.title)}</b></div>`).join('')}
      <button class="btn primary wide" data-act="close">Продолжить</button>
    </div>`, 'center');
}

// ---------- шторки ----------
function openSheet(html, kind = 'bottom') {
  ui.sheet = true;
  $overlay.innerHTML = `<div class="backdrop" data-act="close"></div><div class="sheet ${kind}">${kind === 'bottom' ? '<div class="grabber"></div>' : ''}${html}</div>`;
  $overlay.classList.add('show');
}
function closeSheet() { ui.sheet = null; $overlay.classList.remove('show'); $overlay.innerHTML = ''; }

// ---------- общие компоненты ----------
function rankBadge(id, size = '') { return `<span class="rk rk-${id} ${size}">${id}</span>`; }

function bar(p, cls = '') { return `<div class="bar ${cls}"><i style="width:${Math.round(Math.max(0, Math.min(1, p)) * 100)}%"></i></div>`; }

function playerRank() {
  const xp = G.playerXP(state);
  return { xp, vxp: G.playerXP(state, true), ...G.rankFor(xp, G.playerScale(state)) };
}

function questCard(q, { compact = false, rmDay = null } = {}) {
  const locked = G.isLocked(state, q);
  const done = G.isDone(q);
  const st = done ? 'done' : q.status === 'failed' ? 'failed' : q.status === 'pending' ? 'pending' : locked ? 'locked' : (rmDay && q.day > rmDay + 10 ? 'future' : 'open');
  const main = q.awards?.[0];
  const xp = main ? main.xp : 0;
  const extra = (q.awards || []).length - 1;
  const c = main ? cat(main.cat) : cat('growth');
  const verified = G.isVerified(q);
  const icon = done ? '✓' : st === 'failed' ? '✕' : st === 'pending' ? '⏳' : st === 'locked' ? '🔒' : '';
  return `<button class="qcard st-${st} ${q.boss ? 'boss' : ''} ${compact ? 'compact' : ''}" data-act="quest" data-id="${q.id}" style="--c:${c.color}">
    <div class="qtop">${q.boss ? '<span class="bosstag">🔥 BOSS</span>' : `<span class="qcat">${c.emoji}</span>`}${q.branch ? '<span class="branchtag">🔄</span>' : ''}<span class="qstate">${icon}</span></div>
    <div class="qtitle">${h(q.title)}</div>
    <div class="qbottom"><span class="qxp">+${fmt(xp)} ${unit()}</span>${extra > 0 ? `<span class="mtag">🪐+${extra}</span>` : ''}${verified ? '<span class="vtag">✓ verified</span>' : q.custom ? '<span class="ctag">свои</span>' : ''}</div>
  </button>`;
}

// ---------- онбординг ----------
function viewOnboarding() {
  if (ui.ob.step === 0) {
    return `<section class="hero">
      <div class="logo">⚔️</div>
      <h1>LIFE RPG</h1>
      <p class="tagline">Твоя жизнь — твоя игра.<br>Прокачивай себя к легенде.</p>
      <div class="hero-ranks">${RANKS.map((r) => rankBadge(r.id)).join('')}</div>
      <p class="muted">XP начисляется только за реальные результаты — не за время в приложении.</p>
      <button class="btn primary wide" data-act="ob-next">Начать свою игру</button>
      <button class="btn ghost wide" data-act="demo">Посмотреть демо: Айганым · Rank A</button>
      <p class="slogan">You don’t play a character. You build yourself.</p>
    </section>`;
  }
  return `<section class="page">
    <h2>Создай игрока</h2>
    <label class="field"><span>Имя</span><input id="ob-name" placeholder="Например, Айганым" autocomplete="off"></label>
    <div class="row2">
      <label class="field"><span>Возраст</span><input id="ob-age" type="number" inputmode="numeric" placeholder="15"></label>
      <label class="field"><span>Город</span><input id="ob-loc" placeholder="Астана"></label>
    </div>
    <h3>Выбери режим</h3>
    <div class="modes">${Object.entries(MODES).map(([k, m]) => `<button class="mode ${ui.ob.mode === k ? 'on' : ''}" data-act="ob-mode" data-mode="${k}"><b>${m.emoji} ${m.label}</b><small>${m.desc}</small></button>`).join('')}</div>
    <h3>${ui.ob.mode === 'company' ? 'Компания и её большая цель' : 'Твоя главная мечта'}</h3>
    ${ui.ob.mode === 'company' ? '<label class="field"><span>Название компании</span><input id="ob-company" placeholder="MASHSTROY"></label>' : ''}
    <label class="field"><textarea id="ob-dream" rows="3" placeholder="${ui.ob.mode === 'kids' || ui.ob.mode === 'sen' ? 'Например: научиться читать и собрать свой робот' : 'Например: Хочу поступить в топовый университет и стать AI/software engineer'}"></textarea></label>
    <p class="muted">AI Game Master превратит мечту в дорожную карту: квесты, Boss Battles, XP и уровни.</p>
    <button class="btn primary wide" data-act="ob-finish">Создать игру ✨</button>
    <button class="btn ghost wide" data-act="ob-back">Назад</button>
  </section>`;
}

function finishOnboarding() {
  const name = document.getElementById('ob-name').value.trim() || 'Игрок';
  const age = parseInt(document.getElementById('ob-age').value, 10) || null;
  const location = document.getElementById('ob-loc').value.trim();
  const dream = document.getElementById('ob-dream').value.trim();
  const mode = ui.ob.mode;
  const companyName = document.getElementById('ob-company')?.value.trim();
  state = G.emptyState();
  state.profile = { name, age, location, mode, dream, createdAt: Date.now() };
  state.settings.calm = mode === 'sen';
  state.settings.parentConfirm = mode === 'kids';
  const personal = G.addWorld(state, { name: mode === 'kids' || mode === 'sen' ? 'Мой мир' : 'Personal World', type: mode === 'kids' || mode === 'sen' ? 'kids' : 'personal' });
  let main = personal;
  const wt = MODES[mode].world;
  if (wt !== personal.type) main = G.addWorld(state, { name: mode === 'company' ? (companyName || 'Моя компания') : WORLD_TYPES[wt].label, type: wt });
  const text = dream || (mode === 'company' ? `Запустить и масштабировать ${companyName || 'компанию'}` : mode === 'kids' ? 'Большое приключение' : mode === 'sen' ? 'Маленькие шаги' : 'Стать лучшей версией себя за 90 дней');
  const plan = generate(text, { mode });
  const rm = applyPlan(state, plan, { worldId: main.id });
  ui.rmId = rm.id;
  ui.tab = 'map';
  save();
  render();
  toast(`✨ Игра создана: ${plan.quests.length} квестов, ${plan.bosses} Boss Battles`);
}

// ---------- главная ----------
function viewHome() {
  if (isSen()) return viewHomeSen();
  if (isKids()) return viewHomeKids();
  const p = playerRank();
  const cx = G.categoryXP(state);
  const today = G.todayQuests(state, 3);
  const cats = WORLD_TYPES.personal.cats;
  return `<section class="page">
    <div class="profile-card">
      <div class="avatar">${h((state.profile.name || '?')[0])}</div>
      <div class="pc-main">
        <div class="pc-name">${h(state.profile.name)}</div>
        <div class="pc-meta">${[state.profile.age ? `Возраст: ${state.profile.age}` : '', h(state.profile.location || '')].filter(Boolean).join(' · ')}</div>
        <div class="pc-rank">RPG уровень <b class="rkc-${p.rank.id}">${p.rank.id} (${p.rank.name})</b></div>
      </div>
      <button class="shield" data-act="tab" data-tab="ranks">${p.rank.id}</button>
    </div>
    <div class="xp-card">
      <div class="xp-label">Общий XP</div>
      <div class="xp-big">${fmt(p.xp)} <small>XP</small></div>
      ${bar(p.progress, 'gold')}
      <div class="xp-row"><span>${fmt(p.xp)} / ${p.next ? fmt(p.next.min) : '∞'} XP</span><span>${p.next ? `→ ранг ${p.next.id}: ещё ${fmt(p.toNext)}` : 'Максимальный ранг'}</span></div>
      <div class="xp-split"><span>Verified XP <b class="ok">${fmt(p.vxp)} ✓</b></span><span>Без доказательств <b>${fmt(p.xp - p.vxp)}</b></span></div>
    </div>

    <div class="sec-head"><h3>Сегодняшние квесты</h3><button class="link" data-act="tab" data-tab="map">Карта →</button></div>
    ${today.length ? `<div class="qlist">${today.map((q) => questCard(q)).join('')}</div>` : `<div class="empty">Нет активных квестов. <button class="link" data-act="tab" data-tab="gm">Создай цель с AI Game Master →</button></div>`}

    <div class="sec-head"><h3>Направления</h3></div>
    <div class="cats">${cats.map((c) => { const x = cx[c] || 0; const r = G.rankFor(x, 'category'); return `<div class="catrow" style="--c:${cat(c).color}"><span class="ce">${cat(c).emoji}</span><div class="cm"><div class="cl"><span>${cat(c).label}</span><b>${fmt(x)} XP</b></div>${bar(r.progress, 'thin')}</div>${rankBadge(r.rank.id, 'sm')}</div>`; }).join('')}</div>

    <div class="sec-head"><h3>Миры</h3><button class="link" data-act="tab" data-tab="worlds">Все →</button></div>
    <div class="worldchips">${state.worlds.map((w) => { const x = G.worldXP(state, w.id); const r = G.rankFor(x, G.worldScale(w)); return `<button class="wchip" data-act="world" data-id="${w.id}"><span>${w.emoji}</span><b>${h(w.name)}</b><small>${r.rank.id} · ${fmt(x)}</small></button>`; }).join('')}</div>

    <div class="sec-head"><h3>Последние события</h3></div>
    <div class="log">${state.log.slice(0, 6).map((l) => `<div class="logrow"><span>${h(l.text)}</span>${l.xp ? `<b>+${fmt(l.xp)}</b>` : ''}</div>`).join('') || '<div class="muted">Пока пусто</div>'}</div>
  </section>`;
}

function viewHomeKids() {
  const p = playerRank();
  const today = G.todayQuests(state, 3);
  const pending = state.quests.filter((q) => q.status === 'pending');
  const path = G.SCALES.kids.slice(0, 5);
  return `<section class="page kids">
    <div class="kid-hello">Привет, ${h(state.profile.name)}! 👋</div>
    <div class="adventure">${path.map((r, i) => `<div class="stop ${i < p.idx ? 'past' : i === p.idx ? 'here' : ''}"><div class="stop-ic">${r.icon}</div><small>${r.name}</small></div>`).join('<div class="road"></div>')}</div>
    <div class="xp-card kid">
      <div class="xp-big">${fmt(p.xp)} <small>⭐</small></div>
      ${bar(p.progress, 'gold')}
      <div class="xp-row"><span>${p.rank.icon} ${p.rank.name}</span><span>${p.next ? `до ${p.next.icon} ${p.next.name}: ${fmt(p.toNext)} ⭐` : '🏆'}</span></div>
    </div>
    <h3 class="kid-h">Сегодня у меня ${today.length} ${today.length === 1 ? 'маленький квест' : 'маленьких квеста'}</h3>
    <div class="qlist big">${today.map((q) => questCard(q)).join('') || '<div class="empty">Все квесты выполнены! 🎉</div>'}</div>
    ${pending.length ? `<h3 class="kid-h">⏳ Ждут подтверждения родителя</h3><div class="qlist">${pending.map((q) => questCard(q)).join('')}</div>` : ''}
    <div class="sec-head"><h3>Мои награды</h3></div>
    <div class="achgrid">${state.achievements.slice(0, 8).map((a) => `<div class="ach"><div>${a.icon}</div><small>${h(a.title)}</small></div>`).join('') || '<div class="muted">Скоро будут! ⭐</div>'}</div>
  </section>`;
}

function viewHomeSen() {
  const [now, next] = G.todayQuests(state, 2);
  const p = playerRank();
  return `<section class="page sen">
    <div class="sen-h">Привет, ${h(state.profile.name)}</div>
    <div class="sen-label">СЕЙЧАС</div>
    ${now ? `<div class="sen-card">
        <div class="sen-title">${h(now.title)}</div>
        <div class="sen-reward">Награда: ${fmt(G.questXP(now))} ⭐</div>
        <button class="btn primary huge" data-act="complete" data-id="${now.id}">✓ Готово</button>
      </div>` : '<div class="sen-card"><div class="sen-title">Всё сделано ⭐</div></div>'}
    <div class="sen-label">ПОТОМ</div>
    ${next ? `<div class="sen-card next"><div class="sen-title">${h(next.title)}</div></div>` : '<div class="sen-card next"><div class="sen-title">Отдых 🌿</div></div>'}
    <div class="sen-stars">Мои звёзды: <b>${fmt(p.xp)} ⭐</b></div>
    ${bar(p.progress, 'calm')}
  </section>`;
}

// ---------- карта ----------
function viewMap() {
  if (!state.roadmaps.length) return `<section class="page"><div class="empty big">У тебя ещё нет дорожной карты.<br><br><button class="btn primary" data-act="tab" data-tab="gm">✨ Создать с AI Game Master</button></div></section>`;
  const rm = state.roadmaps.find((r) => r.id === ui.rmId) || state.roadmaps[state.roadmaps.length - 1];
  ui.rmId = rm.id;
  const pr = G.roadmapProgress(state, rm);
  const w = worldById(rm.worldId);
  const wx = G.worldXP(state, w.id);
  const wr = G.rankFor(wx, G.worldScale(w));
  const qs = G.roadmapQuests(state, rm);
  const cur = G.currentQuest(state, rm);
  const seg = rm.days <= 120 ? 7 : 30;
  const nSeg = Math.ceil(rm.days / seg);
  const segs = Array.from({ length: nSeg }, (_, i) => ({ i, from: i * seg + 1, to: Math.min(rm.days, (i + 1) * seg), qs: [] }));
  for (const q of qs) segs[Math.min(nSeg - 1, Math.floor(((q.day || 1) - 1) / seg))].qs.push(q);
  const curSeg = Math.min(nSeg - 1, Math.floor((pr.day - 1) / seg));
  const typeLabel = w.type === 'company' ? 'Company XP' : `${w.name} XP`;
  const rankName = wr.rank.name;
  return `<section class="page map">
    ${state.roadmaps.length > 1 ? `<div class="rmchips">${state.roadmaps.map((r) => `<button class="chip ${r.id === rm.id ? 'on' : ''}" data-act="rm" data-id="${r.id}">${h(r.title.length > 28 ? r.title.slice(0, 27) + '…' : r.title)}</button>`).join('')}</div>` : ''}
    <div class="map-head">
      <div class="mh-title">${h(rm.title)}</div>
      <div class="mh-day"><b>DAY ${pr.day}</b> / ${rm.days}<span>${Math.round(pr.timePct * 100)}%</span></div>
      ${bar(pr.timePct, 'gold')}
      <div class="mh-stats">
        <div><small>${h(typeLabel)}</small><b>${fmt(wx)}</b></div>
        <div><small>Rank</small><b>${wr.rank.id} — ${h(rankName)}</b></div>
        <div><small>${wr.next ? `до Rank ${wr.next.id}` : 'Rank'}</small><b>${wr.next ? fmt(wr.toNext) + ' XP' : 'MAX'}</b></div>
      </div>
      <div class="mh-q">Квесты: ${pr.done} / ${pr.total} ${bar(pr.pct, 'thin')}</div>
    </div>
    ${cur ? `<button class="current" data-act="quest" data-id="${cur.id}"><small>▶ ТЕКУЩИЙ КВЕСТ · день ${cur.day || '—'}</small><b>${h(cur.title)}</b><span>+${fmt(cur.awards?.[0]?.xp || 0)} XP</span></button>` : `<div class="current done"><b>🏁 Все квесты пройдены!</b></div>`}
    ${rm.pointA ? `<div class="pointA"><b>ТОЧКА А · День 1</b><p>${h(rm.pointA)}</p></div>` : ''}
    <div class="timeline" id="timeline">
      ${segs.map((s) => `<div class="seg ${s.i === curSeg ? 'now' : s.i < curSeg ? 'past' : ''}" ${s.i === curSeg ? 'id="seg-now"' : ''}>
        <div class="seg-head"><b>${seg === 7 ? 'Неделя' : 'Месяц'} ${s.i + 1}</b><small>Дни ${s.from}–${s.to}</small></div>
        <div class="seg-dot"></div>
        <div class="seg-cards">${s.qs.map((q) => questCard(q, { compact: true, rmDay: pr.day })).join('') || '<div class="seg-empty">—</div>'}</div>
      </div>`).join('')}
      <div class="seg pointB"><div class="seg-head"><b>ТОЧКА Б</b><small>День ${rm.days}</small></div><div class="seg-dot"></div>
        <div class="pb">${Array.isArray(rm.pointB) ? rm.pointB.map((x) => `<div>✓ ${h(x)}</div>`).join('') : `<div>🏆 ${h(rm.dream || rm.title)}</div>`}</div></div>
    </div>
    <p class="muted center">← листай карту → · нажми на карточку, чтобы выполнить квест</p>
    <button class="btn ghost wide" data-act="add-quest" data-rm="${rm.id}">＋ Добавить свой квест в карту</button>
    <button class="btn danger-ghost wide" data-act="del-rm" data-id="${rm.id}">Удалить карту</button>
  </section>`;
}

function questSheet(id) {
  const q = G.questById(state, id);
  if (!q) return;
  const locked = G.isLocked(state, q);
  const done = G.isDone(q);
  const reqs = (q.requires || []).map((r) => G.questById(state, r)).filter(Boolean);
  const tier = G.tierById(q.tier);
  openSheet(`
    <div class="qs ${q.boss ? 'boss' : ''}">
      ${q.boss ? '<div class="boss-banner">🔥 BOSS BATTLE</div>' : ''}
      <h2>${h(q.title)}</h2>
      <div class="qs-meta">${q.phase ? `<span>${h(q.phase)}</span>` : ''}${q.day ? `<span>День ${q.day}</span>` : ''}${tier ? `<span>${h(tier.label)}</span>` : q.custom ? '<span>Свои критерии</span>' : ''}${q.branch ? `<span>🔄 ${h(q.branch)}</span>` : ''}</div>
      <div class="awards">${(q.awards || []).map((a) => { const w = worldById(a.worldId); return `<div class="award"><span>${w?.emoji || ''} ${h(w?.name || a.worldId)} · ${cat(a.cat).emoji} ${h(cat(a.cat).label)}</span><b>+${fmt(a.xp)} XP</b></div>`; }).join('')}</div>
      ${locked ? `<div class="lockbox">🔒 Сначала выполни подготовительные квесты:<ul>${reqs.filter((r) => !G.isDone(r)).map((r) => `<li>${h(r.title)}</li>`).join('')}</ul></div>` : ''}
      ${done ? `<div class="donebox">✓ Выполнено${q.doneAt ? ' · ' + new Date(q.doneAt).toLocaleDateString('ru-RU') : ''}${G.isVerified(q) ? ' · <b class="ok">Verified ✓</b>' : q.custom ? ' · свои критерии (не входят в Verified XP)' : ' · без доказательства'}</div>` : ''}
      ${q.status === 'failed' ? '<div class="failbox">✕ Не получилось — маршрут перестроен. Это не проигрыш.</div>' : ''}
      ${q.status === 'pending' ? '<div class="pendbox">⏳ Ждёт подтверждения родителя</div>' : ''}
      ${!q.custom ? `<label class="field"><span>Доказательство → Verified XP</span><div class="proofrow"><select id="proof-type">${PROOF_TYPES.map((p) => `<option>${p}</option>`).join('')}</select><input id="proof" placeholder="Ссылка / номер сертификата / GitHub" value="${h(q.proof)}"></div></label>` : ''}
      <div class="qs-actions">
        ${!done && q.status !== 'failed' && q.status !== 'pending' && !locked ? `<button class="btn primary wide big" data-act="complete" data-id="${q.id}">✓ Выполнено</button>` : ''}
        ${q.status === 'pending' ? `<button class="btn primary wide" data-act="confirm" data-id="${q.id}">👨‍👩‍👧 Подтвердить (родитель)</button>` : ''}
        ${done && !q.custom ? `<button class="btn wide" data-act="save-proof" data-id="${q.id}">Сохранить доказательство</button>` : ''}
        ${!done && q.status !== 'failed' && q.roadmapId && !isKids() && !isSen() ? `<button class="btn ghost wide" data-act="fail" data-id="${q.id}">✕ Не получилось → перестроить маршрут</button>` : ''}
        ${done ? `<button class="btn ghost wide" data-act="undo" data-id="${q.id}">Отменить выполнение</button>` : ''}
        <button class="btn danger-ghost wide" data-act="del-quest" data-id="${q.id}">Удалить квест</button>
      </div>
    </div>`);
}

function readProof() {
  const v = document.getElementById('proof')?.value.trim();
  if (!v) return '';
  const t = document.getElementById('proof-type')?.value;
  return t && !v.startsWith(t) ? `${t}: ${v}` : v;
}

// ---------- Game Master ----------
const GM_EXAMPLES = [
  'За 90 дней запустить и масштабировать «AIKEN Fashion House»',
  'IELTS 7.0 за 6 месяцев',
  'Мне 15 лет. Я хочу через три года поступить в MIT и создать технологическую компанию',
  'Хочу поступить в топовый университет и стать AI/software engineer',
  'Опубликовать научную статью в Scopus за 8 месяцев',
  'Стать сильным software engineer за полгода',
];

function viewGM() {
  const plan = ui.gm.plan;
  return `<section class="page gm">
    <div class="gm-hero"><div class="gm-orb">✨</div><h2>AI Game Master</h2><p>Напиши мечту обычным языком — получишь игру: главный квест, фазы, квесты, Boss Battles и XP.</p></div>
    <label class="field"><textarea id="gm-text" rows="3" placeholder="Например: IELTS 7.0 за 6 месяцев">${h(ui.gm.text)}</textarea></label>
    <div class="examples">${GM_EXAMPLES.map((e, i) => `<button class="chip" data-act="gm-ex" data-i="${i}">${h(e.length > 40 ? e.slice(0, 39) + '…' : e)}</button>`).join('')}</div>
    <button class="btn primary wide" data-act="gm-gen">Сгенерировать игру</button>
    ${plan ? viewPlan(plan) : ''}
    <p class="muted small">DREAM → AI ROADMAP → QUESTS → ✓ → XP → LEVEL UP → ACHIEVEMENTS → NEXT WORLD</p>
  </section>`;
}

function viewPlan(plan) {
  const suggested = plan.worldName ? state.worlds.find((w) => w.name.toLowerCase() === plan.worldName.toLowerCase()) : null;
  const sameType = state.worlds.find((w) => w.type === plan.worldType);
  const defId = ui.gm.worldId || suggested?.id || (plan.worldName ? 'new' : sameType?.id || state.worlds[0]?.id);
  const phases = [];
  for (const q of plan.quests) { const last = phases[phases.length - 1]; if (last && last.name === q.phase) last.qs.push(q); else phases.push({ name: q.phase, qs: [q] }); }
  return `<div class="plan">
    <div class="plan-head"><small>ГЛАВНЫЙ QUEST</small><h3>${h(plan.title)}</h3>
      <div class="plan-stats"><span>📅 ${plan.days} дней</span><span>⚔️ ${plan.quests.length} квестов</span><span>🔥 ${plan.bosses} боссов</span><span>⭐ ${fmt(plan.totalXP)} XP</span></div></div>
    <label class="field"><span>В каком мире играть</span><select id="gm-world">
      ${state.worlds.map((w) => `<option value="${w.id}" ${w.id === defId ? 'selected' : ''}>${w.emoji} ${h(w.name)}</option>`).join('')}
      <option value="new" ${defId === 'new' ? 'selected' : ''}>＋ Новый мир: ${h(plan.worldName || WORLD_TYPES[plan.worldType].label)}</option>
    </select></label>
    <div class="phases">${phases.map((ph) => `<div class="phase"><div class="ph-name">${h(ph.name)}</div>${ph.qs.map((q) => `<div class="ph-q ${q.boss ? 'boss' : ''}"><span>${q.boss ? '🔥 ' : '☐ '}${h(q.title)}</span><small>д.${q.day} · +${fmt(q.xp)}</small></div>`).join('')}</div>`).join('')}</div>
    <button class="btn primary wide big" data-act="gm-apply">Начать игру ▶</button>
  </div>`;
}

// ---------- миры ----------
function viewWorlds() {
  if (ui.worldId && worldById(ui.worldId)) return viewWorld(worldById(ui.worldId));
  return `<section class="page">
    <h2>Миры</h2>
    <p class="muted">Одно достижение может давать XP сразу нескольким мирам.</p>
    <div class="worlds">${state.worlds.map((w) => { const x = G.worldXP(state, w.id); const vx = G.worldXP(state, w.id, true); const r = G.rankFor(x, G.worldScale(w)); return `<button class="wcard" data-act="world" data-id="${w.id}">
      <div class="wc-top"><span class="wc-e">${w.emoji}</span><div><b>${h(w.name)}</b><small>${h(WORLD_TYPES[w.type]?.label || '')}</small></div>${rankBadge(r.rank.id)}</div>
      <div class="xp-row"><span>${fmt(x)} / ${r.next ? fmt(r.next.min) : '∞'} XP</span><span>${h(r.rank.name)}${r.next ? ' → ' + r.next.id + ' — ' + h(r.next.name) : ''}</span></div>
      ${bar(r.progress, 'gold')}<small class="muted">Verified: ${fmt(vx)} ✓</small></button>`; }).join('')}</div>
    <h3>Новый мир</h3>
    <div class="newworld">
      <input id="nw-name" placeholder="Название (например, MASHSTROY)">
      <select id="nw-type">${Object.entries(WORLD_TYPES).map(([k, t]) => `<option value="${k}">${t.emoji} ${t.label}</option>`).join('')}</select>
      <button class="btn primary" data-act="add-world">Создать</button>
    </div>
  </section>`;
}

function viewWorld(w) {
  const x = G.worldXP(state, w.id);
  const r = G.rankFor(x, G.worldScale(w));
  const cx = G.categoryXP(state, w.id);
  const cats = (WORLD_TYPES[w.type] || WORLD_TYPES.personal).cats;
  const ws = G.weakSpot(state, w.id);
  const openQs = state.quests.filter((q) => !q.roadmapId && !G.isDone(q) && q.status !== 'failed' && q.awards?.[0]?.worldId === w.id);
  const doneQs = state.quests.filter((q) => G.isDone(q) && q.awards?.some((a) => a.worldId === w.id)).slice(0, 30);
  const stageIdx = w.type === 'company' ? Math.min(COMPANY_STAGES.length - 1, Math.round(r.idx * 1.6 + r.progress * 1.6)) : -1;
  return `<section class="page">
    <button class="link back" data-act="world-back">← Все миры</button>
    <div class="world-head"><span class="wh-e">${w.emoji}</span><div><h2>${h(w.name)}</h2><small>${h(WORLD_TYPES[w.type]?.label || '')}</small></div></div>
    <div class="xp-card">
      <div class="xp-label">${w.type === 'company' ? 'Company Level' : 'Rank'}: <b>${r.rank.id} — ${h(r.rank.name)}</b></div>
      <div class="xp-big">${fmt(x)} <small>/ ${r.next ? fmt(r.next.min) : '∞'} XP</small></div>
      ${bar(r.progress, 'gold')}
      <div class="xp-row"><span>Verified ${fmt(G.worldXP(state, w.id, true))} ✓</span><span>${r.next ? `Next level: ${r.next.id} — ${h(r.next.name)}` : 'MAX'}</span></div>
    </div>
    ${stageIdx >= 0 ? `<div class="stages">${COMPANY_STAGES.map((s, i) => `<span class="${i < stageIdx ? 'past' : i === stageIdx ? 'here' : ''}">${s}</span>`).join('<i>→</i>')}</div>` : ''}
    <div class="sec-head"><h3>Дерево развития</h3></div>
    <div class="cats">${cats.map((c) => { const v = cx[c] || 0; const cr = G.rankFor(v, 'category'); return `<div class="catrow ${ws && ws.weak.cat === c ? 'weak' : ''}" style="--c:${cat(c).color}"><span class="ce">${cat(c).emoji}</span><div class="cm"><div class="cl"><span>${h(cat(c).label)}</span><b>${fmt(v)}</b></div>${bar(cr.progress, 'thin')}</div>${rankBadge(cr.rank.id, 'sm')}</div>`; }).join('')}</div>
    ${ws ? `<div class="weakbox"><b>💡 Чтобы перейти на ${r.next ? 'Rank ' + r.next.id : 'следующий уровень'}, слабое место — ${h(cat(ws.weak.cat).label)} (${ws.rank}).</b>
      <p>Выполни 3 следующих квеста:</p>
      ${ws.open.length ? ws.open.map((q) => questCard(q, { compact: true })).join('') : ''}
      ${ws.suggestions.slice(0, 3 - ws.open.length).map((s, i) => `<button class="sugg" data-act="sugg" data-w="${w.id}" data-cat="${ws.weak.cat}" data-i="${i}">＋ ${h(s)}</button>`).join('')}
    </div>` : ''}
    ${openQs.length ? `<div class="sec-head"><h3>Открытые квесты</h3></div><div class="qlist">${openQs.map((q) => questCard(q)).join('')}</div>` : ''}
    <div class="sec-head"><h3>Выполнено</h3></div>
    <div class="log">${doneQs.map((q) => `<button class="logrow" data-act="quest" data-id="${q.id}"><span>${G.isVerified(q) ? '✓' : '·'} ${h(q.title)}</span><b>+${fmt(G.questXP(q, w.id))}</b></button>`).join('') || '<div class="muted">Пока пусто</div>'}</div>
    <button class="btn danger-ghost wide" data-act="del-world" data-id="${w.id}">Удалить мир</button>
  </section>`;
}

// ---------- профиль ----------
function viewProfile() {
  const p = playerRank();
  const cx = G.categoryXP(state);
  const done = state.quests.filter(G.isDone);
  const groups = {};
  for (const q of done) { const c = q.awards?.[0]?.cat || 'growth'; (groups[c] ||= []).push(q); }
  const scale = G.SCALES[G.playerScale(state)];
  return `<section class="page">
    <div class="result-card">
      <div><div class="xp-label">РЕЗУЛЬТАТ · Общий XP</div><div class="xp-big gold">${fmt(p.xp)} <small>XP</small></div><div class="muted">Verified ${fmt(p.vxp)} ✓ · ${done.length} результатов</div></div>
      <div class="trophy">🏆</div>
    </div>
    <div class="sec-head"><h3>Итоговая шкала уровней</h3><button class="link" data-act="tab" data-tab="ranks">Подробно →</button></div>
    <div class="scale">${scale.map((r) => `<div class="sc ${r.id === p.rank.id ? 'on' : ''}"><b>${r.id}</b><small>${fmt(r.min)}+</small></div>`).join('')}</div>
    <div class="nextlvl"><div><small>СЛЕДУЮЩИЙ УРОВЕНЬ</small><b>${p.next ? `До ранга ${p.next.id} (${p.next.name}) осталось` : 'Максимум'}</b></div><div class="xp-big">${p.next ? fmt(p.toNext) : '∞'}<small> XP</small></div></div>
    <div class="sec-head"><h3>Достижения</h3></div>
    <div class="achgrid">${state.achievements.map((a) => `<div class="ach" title="${h(a.desc)}"><div>${a.icon}</div><small>${h(a.title)}</small></div>`).join('') || '<div class="muted">Выполни первый квест</div>'}</div>
    <div class="sec-head"><h3>Результаты по направлениям</h3></div>
    ${Object.entries(groups).sort((a, b) => (cx[b[0]] || 0) - (cx[a[0]] || 0)).map(([c, qs]) => `<details class="group" style="--c:${cat(c).color}"><summary><span>${cat(c).emoji} ${h(cat(c).label)}</span><b>${fmt(qs.reduce((s, q) => s + G.questXP(q), 0))} XP</b></summary>${qs.map((q) => `<button class="logrow" data-act="quest" data-id="${q.id}"><span>${G.isVerified(q) ? '✓' : '·'} ${h(q.title)}</span><b>+${fmt(G.questXP(q))}</b></button>`).join('')}</details>`).join('')}
    <div class="sec-head"><h3>Настройки</h3></div>
    <div class="settings">
      <label class="field"><span>Имя</span><input id="st-name" value="${h(state.profile.name)}"></label>
      <div class="row2"><label class="field"><span>Возраст</span><input id="st-age" type="number" value="${h(state.profile.age || '')}"></label><label class="field"><span>Город</span><input id="st-loc" value="${h(state.profile.location || '')}"></label></div>
      <label class="field"><span>Режим</span><select id="st-mode">${Object.entries(MODES).map(([k, m]) => `<option value="${k}" ${state.profile.mode === k ? 'selected' : ''}>${m.emoji} ${m.label}</option>`).join('')}</select></label>
      <label class="toggle"><input type="checkbox" id="st-calm" ${state.settings.calm ? 'checked' : ''}> Спокойный экран (без анимаций)</label>
      <label class="toggle"><input type="checkbox" id="st-parent" ${parentConfirm() ? 'checked' : ''}> Подтверждение достижений родителем</label>
      <button class="btn wide" data-act="save-settings">Сохранить</button>
      <div class="row2"><button class="btn ghost" data-act="export">⬇ Экспорт</button><button class="btn ghost" data-act="import">⬆ Импорт</button></div>
      <button class="btn danger-ghost wide" data-act="reset">Начать заново</button>
    </div>
    <p class="slogan">You don’t play a character. You build yourself.<br>You don’t build a virtual empire. You build a real one.</p>
  </section>`;
}

function viewRanks() {
  const p = playerRank();
  return `<section class="page">
    <button class="link back" data-act="tab" data-tab="profile">← Профиль</button>
    <h2 class="title-serif">LIFE RPG — ранги</h2>
    <p class="muted">Ранг показывает не «сколько задач выполнено», а насколько далеко ты продвинулась в реальной жизненной траектории.</p>
    ${RANKS.map((r, i) => { const info = RANK_INFO[r.id]; const nx = RANKS[i + 1]; return `<div class="rankcard ${r.id === p.rank.id ? 'on' : ''}" style="--c:${r.color}">
      <div class="rc-top">${rankBadge(r.id, 'lg')}<div><b>${r.name}</b><small>${fmt(r.min)}${nx ? '–' + fmt(nx.min - 1) : '+'} XP</small></div>${r.id === p.rank.id ? '<span class="you">ТЫ ЗДЕСЬ</span>' : ''}</div>
      <div class="rc-goal">Цель: ${h(info.goal)}</div>
      <ul>${info.needs.map((n) => `<li>${h(n)}</li>`).join('')}</ul>
      <div class="rc-motto">${h(info.motto)}</div></div>`; }).join('')}
    <h3>Как получать XP (стандартная шкала)</h3>
    <div class="tiers">${XP_TIERS.map((t) => `<div class="tier"><span>${h(t.label)}</span><b>+${fmt(t.min)}–${fmt(t.max)}</b></div>`).join('')}</div>
    <p class="muted">Свои критерии и веса можно создавать — они входят в Total XP, но не в Verified XP. Verified XP подтверждается сертификатами, GitHub, публикациями, дипломами, ссылками и портфолио.</p>
  </section>`;
}

// ---------- добавить результат ----------
function addSheet({ rmId = null } = {}) {
  const tiers = isKids() || isSen() ? KIDS_TIERS : XP_TIERS;
  const w0 = state.roadmaps.find((r) => r.id === rmId)?.worldId || state.worlds[0].id;
  openSheet(`
    <h2>${rmId ? 'Новый квест в карту' : 'Добавить реальный результат'}</h2>
    <label class="field"><span>Что сделано${rmId ? ' / нужно сделать' : ''}</span><input id="ad-title" placeholder="Например: Сертификат Google Data Analytics"></label>
    <label class="field"><span>Тип результата</span><select id="ad-tier">${tiers.map((t) => `<option value="${t.id}">${h(t.label)} · +${t.min}–${t.max}</option>`).join('')}<option value="custom">⚙️ Свои критерии (не входит в Verified)</option></select></label>
    <label class="field"><span>XP: <b id="ad-xpv"></b></span><input id="ad-xp" type="range"></label>
    <div class="field"><span>Какие миры прокачивает</span>
      ${state.worlds.map((w, i) => `<div class="awrow"><label><input type="checkbox" class="ad-w" data-w="${w.id}" ${w.id === w0 ? 'checked' : ''}> ${w.emoji} ${h(w.name)}</label>
        <select class="ad-c" data-w="${w.id}">${(WORLD_TYPES[w.type] || WORLD_TYPES.personal).cats.map((c) => `<option value="${c}">${cat(c).emoji} ${h(cat(c).label)}</option>`).join('')}</select>
        <input class="ad-x" data-w="${w.id}" type="number" inputmode="numeric" placeholder="XP" ${w.id === w0 ? 'disabled' : ''}></div>`).join('')}
      <small class="muted">Основной мир получает XP со слайдера, остальные — сколько укажешь.</small>
    </div>
    ${rmId ? `<label class="field"><span>День карты</span><input id="ad-day" type="number" value="${G.roadmapProgress(state, state.roadmaps.find((r) => r.id === rmId)).day}"></label><label class="toggle"><input type="checkbox" id="ad-boss"> 🔥 Boss Battle</label>` : `<label class="field"><span>Доказательство → Verified XP</span><div class="proofrow"><select id="proof-type">${PROOF_TYPES.map((p) => `<option>${p}</option>`).join('')}</select><input id="proof" placeholder="Ссылка / номер сертификата"></div></label>`}
    <button class="btn primary wide big" data-act="${rmId ? 'add-quest-save' : 'add-save'}" data-rm="${rmId || ''}" data-w0="${w0}">${rmId ? 'Добавить квест' : '✓ Начислить XP'}</button>`);
  const $tier = document.getElementById('ad-tier');
  const $xp = document.getElementById('ad-xp');
  const $v = document.getElementById('ad-xpv');
  const sync = () => {
    const t = G.tierById($tier.value);
    if (t) { $xp.min = t.min; $xp.max = t.max; $xp.step = t.max - t.min >= 1000 ? 50 : 10; $xp.value = t.def; }
    else { $xp.min = 10; $xp.max = 50000; $xp.step = 10; }
    $v.textContent = `+${fmt($xp.value)}`;
  };
  $tier.addEventListener('change', sync);
  $xp.addEventListener('input', () => { $v.textContent = `+${fmt($xp.value)}`; });
  sync();
}

function readAwards(w0) {
  const xp = parseInt(document.getElementById('ad-xp').value, 10);
  const awards = [];
  document.querySelectorAll('.ad-w').forEach((cb) => {
    if (!cb.checked) return;
    const w = cb.dataset.w;
    const c = document.querySelector(`.ad-c[data-w="${w}"]`).value;
    const v = w === w0 ? xp : parseInt(document.querySelector(`.ad-x[data-w="${w}"]`).value, 10) || Math.round(xp * 0.5);
    awards.push({ worldId: w, cat: c, xp: v });
  });
  awards.sort((a, b) => (a.worldId === w0 ? -1 : b.worldId === w0 ? 1 : 0));
  if (!awards.length) awards.push({ worldId: w0, cat: document.querySelector(`.ad-c[data-w="${w0}"]`).value, xp });
  return awards;
}

// ---------- рендер ----------
const TABS = [
  { id: 'home', icon: '🏠', label: 'Главная' },
  { id: 'map', icon: '🗺', label: 'Карта' },
  { id: 'gm', icon: '✨', label: 'Game Master', center: true },
  { id: 'worlds', icon: '🪐', label: 'Миры' },
  { id: 'profile', icon: '🏆', label: 'Профиль' },
];

function render() {
  document.body.classList.toggle('calm', !!(state.settings.calm || isSen()));
  document.body.classList.toggle('mode-kids', isKids());
  document.body.classList.toggle('mode-sen', isSen());
  if (!state.profile) { $app.innerHTML = viewOnboarding(); return; }
  const views = { home: viewHome, map: viewMap, gm: viewGM, worlds: viewWorlds, profile: viewProfile, ranks: viewRanks };
  const p = playerRank();
  $app.innerHTML = `
    <header class="topbar"><div class="brand">LIFE RPG</div><div class="tb-r"><span class="tb-xp">${fmt(p.xp)} ${unit()}</span>${rankBadge(p.rank.id, 'sm')}</div></header>
    <main>${(views[ui.tab] || viewHome)()}</main>
    ${ui.tab === 'home' || ui.tab === 'worlds' || ui.tab === 'profile' ? '<button class="fab" data-act="add" aria-label="Добавить результат">＋</button>' : ''}
    <nav class="tabbar">${TABS.map((t) => `<button class="tab ${t.center ? 'center' : ''} ${ui.tab === t.id || (t.id === 'profile' && ui.tab === 'ranks') ? 'on' : ''}" data-act="tab" data-tab="${t.id}"><span>${t.icon}</span><small>${t.label}</small></button>`).join('')}</nav>`;
  if (ui.tab === 'map') requestAnimationFrame(() => { const el = document.getElementById('seg-now'); const tl = document.getElementById('timeline'); if (el && tl) tl.scrollLeft += el.getBoundingClientRect().left - tl.getBoundingClientRect().left - 16; });
}

// ---------- действия ----------
const actions = {
  close: closeSheet,
  tab: (d) => { ui.tab = d.tab; if (d.tab === 'worlds') ui.worldId = null; window.scrollTo(0, 0); render(); },
  demo: () => { state = buildDemo(); save(); ui.tab = 'home'; render(); toast('Демо: Айганым · Rank A · 31 750 XP'); },
  'ob-next': () => { ui.ob.step = 1; render(); },
  'ob-back': () => { ui.ob.step = 0; render(); },
  'ob-mode': (d) => {
    const keep = { name: document.getElementById('ob-name')?.value, age: document.getElementById('ob-age')?.value, loc: document.getElementById('ob-loc')?.value, dream: document.getElementById('ob-dream')?.value };
    ui.ob.mode = d.mode; render();
    document.getElementById('ob-name').value = keep.name || ''; document.getElementById('ob-age').value = keep.age || ''; document.getElementById('ob-loc').value = keep.loc || ''; document.getElementById('ob-dream').value = keep.dream || '';
  },
  'ob-finish': finishOnboarding,
  quest: (d) => questSheet(d.id),
  complete: (d) => {
    const proof = readProof();
    const { res } = mutate(() => G.completeQuest(state, d.id, { proof, needsParent: parentConfirm() }));
    if (res?.pending) toast('⏳ Отправлено родителю на подтверждение');
    if (res?.reason === 'locked') toast('🔒 Сначала выполни подготовительные квесты');
    if (!document.querySelector('.levelup')) closeSheet();
  },
  confirm: (d) => { if (!confirm('Подтвердить достижение как родитель?')) return; mutate(() => G.confirmQuest(state, d.id)); if (!document.querySelector('.levelup')) closeSheet(); },
  'save-proof': (d) => { mutate(() => { G.addProof(state, d.id, readProof()); }); closeSheet(); toast('Доказательство сохранено'); },
  fail: (d) => {
    const { res } = mutate(() => G.failQuest(state, d.id));
    closeSheet();
    if (res?.ok) openSheet(`<div class="reroute"><div class="rr-x">❌ Quest failed</div><div class="rr-new">🔄 New route unlocked: <b>${h(res.route)}</b></div>${res.created.map((q) => `<div class="ph-q ${q.boss ? 'boss' : ''}"><span>${q.boss ? '🔥' : '☐'} ${h(q.title)}</span><small>+${fmt(G.questXP(q))} XP</small></div>`).join('')}<p class="muted">Реальная жизнь не идёт строго по плану — игра перестроила карту.</p><button class="btn primary wide" data-act="close">Вперёд</button></div>`, 'center');
  },
  undo: (d) => { mutate(() => G.undoQuest(state, d.id)); closeSheet(); },
  'del-quest': (d) => {
    if (!confirm('Удалить квест?')) return;
    state.quests = state.quests.filter((q) => q.id !== d.id);
    state.roadmaps.forEach((r) => { r.questIds = r.questIds.filter((x) => x !== d.id); });
    state.quests.forEach((q) => { q.requires = (q.requires || []).filter((x) => x !== d.id); });
    save(); closeSheet(); render();
  },
  rm: (d) => { ui.rmId = d.id; render(); },
  'del-rm': (d) => {
    if (!confirm('Удалить карту и её невыполненные квесты? Выполненные результаты и XP останутся.')) return;
    const rm = state.roadmaps.find((r) => r.id === d.id);
    state.quests = state.quests.filter((q) => q.roadmapId !== d.id || G.isDone(q)).map((q) => (q.roadmapId === d.id ? { ...q, roadmapId: null } : q));
    state.roadmaps = state.roadmaps.filter((r) => r !== rm);
    ui.rmId = null; save(); render();
  },
  'gm-ex': (d) => { ui.gm.text = GM_EXAMPLES[+d.i]; ui.gm.plan = null; render(); },
  'gm-gen': () => {
    ui.gm.text = document.getElementById('gm-text').value.trim();
    if (!ui.gm.text) { toast('Напиши свою мечту'); return; }
    ui.gm.plan = generate(ui.gm.text, { mode: state.profile.mode });
    ui.gm.worldId = '';
    render();
    document.querySelector('.plan')?.scrollIntoView({ behavior: 'smooth', block: 'start' });
  },
  'gm-apply': () => {
    const plan = ui.gm.plan;
    let wid = document.getElementById('gm-world').value;
    mutate(() => {
      if (wid === 'new') wid = G.addWorld(state, { name: plan.worldName || WORLD_TYPES[plan.worldType].label, type: plan.worldType }).id;
      const rm = applyPlan(state, plan, { worldId: wid });
      ui.rmId = rm.id;
    });
    ui.gm = { text: '', plan: null, worldId: '' };
    ui.tab = 'map'; render(); window.scrollTo(0, 0);
    toast('▶ Игра началась! День 1');
  },
  world: (d) => { ui.tab = 'worlds'; ui.worldId = d.id; window.scrollTo(0, 0); render(); },
  'world-back': () => { ui.worldId = null; render(); },
  'add-world': () => {
    const name = document.getElementById('nw-name').value.trim();
    const type = document.getElementById('nw-type').value;
    if (!name) { toast('Введи название мира'); return; }
    G.addWorld(state, { name, type }); save(); render(); toast(`🪐 Мир «${name}» создан`);
  },
  'del-world': (d) => {
    if (state.worlds.length <= 1) { toast('Нужен хотя бы один мир'); return; }
    if (!confirm('Удалить мир? XP, начисленный ему, пропадёт.')) return;
    state.worlds = state.worlds.filter((w) => w.id !== d.id);
    state.quests.forEach((q) => { q.awards = (q.awards || []).filter((a) => a.worldId !== d.id); });
    state.roadmaps = state.roadmaps.filter((r) => r.worldId !== d.id);
    ui.worldId = null; save(); render();
  },
  sugg: (d) => {
    const ws = G.weakSpot(state, d.w);
    const title = ws.suggestions[+d.i];
    const w = worldById(d.w);
    state.quests.push(G.makeQuest({ title, tier: w.type === 'kids' ? 'kid_mid' : 'project', awards: [{ worldId: d.w, cat: d.cat, xp: w.type === 'kids' ? 100 : 800 }] }));
    save(); render(); toast('＋ Квест добавлен');
  },
  add: () => addSheet(),
  'add-quest': (d) => addSheet({ rmId: d.rm }),
  'add-save': (d) => {
    const title = document.getElementById('ad-title').value.trim();
    if (!title) { toast('Опиши результат'); return; }
    const tier = document.getElementById('ad-tier').value;
    const awards = readAwards(d.w0);
    const proof = readProof();
    closeSheet();
    mutate(() => { const q = G.addResult(state, { title, tier: tier === 'custom' ? null : tier, custom: tier === 'custom', awards, proof }); return { xp: G.questXP(q) }; });
  },
  'add-quest-save': (d) => {
    const title = document.getElementById('ad-title').value.trim();
    if (!title) { toast('Опиши квест'); return; }
    const tier = document.getElementById('ad-tier').value;
    const rm = state.roadmaps.find((r) => r.id === d.rm);
    const day = Math.max(1, Math.min(rm.days, parseInt(document.getElementById('ad-day').value, 10) || 1));
    const q = G.makeQuest({ title, tier: tier === 'custom' ? null : tier, custom: tier === 'custom', awards: readAwards(d.w0), roadmapId: rm.id, day, boss: document.getElementById('ad-boss').checked, phase: 'Мой квест' });
    state.quests.push(q);
    const qs = G.roadmapQuests(state, rm);
    const idx = qs.findIndex((x) => (x.day || 0) > day);
    if (idx === -1) rm.questIds.push(q.id); else rm.questIds.splice(rm.questIds.indexOf(qs[idx].id), 0, q.id);
    save(); closeSheet(); render(); toast('＋ Квест добавлен в карту');
  },
  'save-settings': () => {
    state.profile.name = document.getElementById('st-name').value.trim() || state.profile.name;
    state.profile.age = parseInt(document.getElementById('st-age').value, 10) || null;
    state.profile.location = document.getElementById('st-loc').value.trim();
    state.profile.mode = document.getElementById('st-mode').value;
    state.settings.calm = document.getElementById('st-calm').checked;
    state.settings.parentConfirm = document.getElementById('st-parent').checked;
    save(); render(); toast('Сохранено');
  },
  export: () => {
    const blob = new Blob([JSON.stringify(state, null, 2)], { type: 'application/json' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = `life-rpg-${new Date().toISOString().slice(0, 10)}.json`;
    a.click();
  },
  import: () => {
    const inp = document.createElement('input');
    inp.type = 'file'; inp.accept = 'application/json,.json';
    inp.onchange = async () => {
      try { const data = JSON.parse(await inp.files[0].text()); if (!data.worlds || !data.quests) throw new Error(); state = { ...G.emptyState(), ...data }; save(); render(); toast('Игра загружена'); } catch { toast('Не удалось прочитать файл'); }
    };
    inp.click();
  },
  reset: () => { if (!confirm('Стереть игру и начать заново?')) return; state = G.emptyState(); ui.ob = { step: 0, mode: 'life' }; ui.tab = 'home'; save(); render(); },
};

document.addEventListener('click', (e) => {
  const el = e.target.closest('[data-act]');
  if (!el) return;
  const fn = actions[el.dataset.act];
  if (fn) { e.preventDefault(); fn(el.dataset); }
});

render();

if ('serviceWorker' in navigator && location.protocol !== 'file:') navigator.serviceWorker.register('./sw.js').catch(() => {});
