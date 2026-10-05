import { test } from 'node:test';
import assert from 'node:assert/strict';
import * as G from '../js/core.js';
import { generate, applyPlan, parseDuration, parseName } from '../js/gamemaster.js';
import { buildDemo } from '../js/demo.js';

const fresh = () => { const s = G.emptyState(); s.profile = { name: 'T', mode: 'life' }; G.addWorld(s, { name: 'Personal', type: 'personal' }); return s; };

test('ранги игрока E → SSS по шкале профиля', () => {
  assert.equal(G.rankFor(0).rank.id, 'E');
  assert.equal(G.rankFor(9450).rank.id, 'C');
  assert.equal(G.rankFor(9450).toNext, 5550); // «До ранга B осталось 5 550 XP»
  const a = G.rankFor(31750);
  assert.equal(a.rank.id, 'A');
  assert.equal(a.next.id, 'S');
  assert.equal(a.toNext, 68250); // «До уровня S осталось 68 250 XP»
  assert.equal(G.rankFor(500000).rank.id, 'SSS');
  assert.equal(G.rankFor(18450, 'company').rank.name, 'Growth');
  assert.equal(G.rankFor(18450, 'company').next.min, 30000);
});

test('Verified XP отдельно от своих критериев', () => {
  const s = fresh();
  const w = s.worlds[0].id;
  G.addResult(s, { title: 'Сертификат', tier: 'cert', awards: [{ worldId: w, cat: 'education', xp: 300 }], proof: 'link' });
  G.addResult(s, { title: 'Прочитала книгу', custom: true, awards: [{ worldId: w, cat: 'growth', xp: 50000 }], proof: 'фото' });
  assert.equal(G.playerXP(s), 50300);
  assert.equal(G.playerXP(s, true), 300);
});

test('XP по стандартной шкале ограничен диапазоном тарифа', () => {
  const s = fresh();
  const q = G.addResult(s, { title: 'Задача', tier: 'task', awards: [{ worldId: s.worlds[0].id, cat: 'tech', xp: 99999 }] });
  assert.equal(G.questXP(q), 100);
});

test('Boss Battle закрыт до подготовительных квестов', () => {
  const s = fresh();
  const plan = generate('IELTS 7.0 за 6 месяцев');
  assert.equal(plan.days, 180);
  const rm = applyPlan(s, plan, { worldId: s.worlds[0].id });
  const boss = G.roadmapQuests(s, rm).find((q) => q.boss);
  assert.ok(G.isLocked(s, boss));
  assert.equal(G.completeQuest(s, boss.id).reason, 'locked');
  boss.requires.forEach((id) => G.completeQuest(s, id));
  assert.ok(!G.isLocked(s, boss));
  assert.ok(G.completeQuest(s, boss.id).ok);
});

test('провал перестраивает маршрут (Bootstrap Strategy)', () => {
  const s = fresh();
  const c = G.addWorld(s, { name: 'AIKEN', type: 'company' });
  const rm = applyPlan(s, generate('За 90 дней запустить и масштабировать AIKEN Fashion House'), { worldId: c.id });
  const pitch = G.roadmapQuests(s, rm).find((q) => /питч инвестору/.test(q.title));
  pitch.requires = [];
  const r = G.failQuest(s, pitch.id);
  assert.equal(r.route, 'Bootstrap Strategy');
  assert.equal(r.created.length, 3);
  assert.equal(r.created.reduce((t, q) => t + G.questXP(q, c.id), 0), 1500);
  assert.ok(rm.questIds.includes(r.created[0].id));
});

test('связанные миры: одно достижение — XP нескольким мирам', () => {
  const s = fresh();
  const a = G.addWorld(s, { name: 'Academic', type: 'academic' });
  const m = G.addWorld(s, { name: 'MASHSTROY', type: 'company' });
  G.addResult(s, { title: 'Опубликовала исследование', tier: 'publication', proof: 'doi', awards: [
    { worldId: s.worlds[0].id, cat: 'science', xp: 700 }, { worldId: a.id, cat: 'science', xp: 1000 }, { worldId: m.id, cat: 'rnd', xp: 1200 }] });
  assert.equal(G.worldXP(s, m.id), 1200);
  assert.equal(G.playerXP(s), 1700); // компания прокачивается отдельно
  const ach = G.checkAchievements(s).map((x) => x.id);
  assert.ok(ach.includes('publication'));
  assert.ok(ach.includes('multiworld'));
});

test('Level Up фиксируется при переходе порога', () => {
  const s = fresh();
  const before = G.snapshot(s);
  G.addResult(s, { title: 'Стажировка', tier: 'internship', awards: [{ worldId: s.worlds[0].id, cat: 'career', xp: 1500 }] });
  const ups = G.rankUps(before, G.snapshot(s), s);
  assert.equal(ups[0].from, 'E');
  assert.equal(ups[0].to, 'D');
});

test('детский режим: родитель подтверждает', () => {
  const s = G.emptyState(); s.profile = { name: 'K', mode: 'kids' };
  G.addWorld(s, { name: 'Мой мир', type: 'kids' });
  const rm = applyPlan(s, generate('приключение', { mode: 'kids' }), { worldId: s.worlds[0].id });
  const q = G.roadmapQuests(s, rm)[0];
  assert.ok(G.completeQuest(s, q.id, { needsParent: true }).pending);
  assert.equal(G.playerXP(s), 0);
  G.confirmQuest(s, q.id);
  assert.ok(G.playerXP(s) > 0);
  assert.ok(G.isVerified(q));
});

test('Game Master: разбор сроков и названий', () => {
  assert.equal(parseDuration('IELTS 7.0 за 6 месяцев'), 180);
  assert.equal(parseDuration('Мне 15 лет. Я хочу через три года поступить в MIT'), 1095);
  assert.equal(parseDuration('За 90 дней запустить'), 90);
  assert.equal(parseName('За 90 дней запустить и масштабировать AIKEN Fashion House'), 'AIKEN Fashion House');
  const p = generate('Мне 15 лет. Я хочу через три года поступить в MIT и создать технологическую компанию');
  assert.deepEqual(p.kinds, ['university', 'company']);
  assert.equal(p.days, 1095);
  assert.ok(p.quests.every((q, i, a) => i === 0 || a[i - 1].day <= q.day));
});

test('демо совпадает с профилем: 31 750 XP, Verified 24 500, MASHSTROY C — Growth', () => {
  const s = buildDemo();
  assert.equal(G.playerXP(s), 31750);
  assert.equal(G.playerXP(s, true), 24500);
  assert.equal(G.worldXP(s, 'mashstroy'), 18450);
  assert.equal(G.weakSpot(s, 'mashstroy').weak.cat, 'sales');
  assert.equal(G.roadmapProgress(s, s.roadmaps[0]).day, 37);
});
