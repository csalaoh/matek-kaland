/* =====================================================================
   Matek-kaland – BÖLCSESSÉGEK KÖNYVTÁRA (v1.6)
   Itt vannak a fogalomlapok, a tanulókártyák és A Könyvtáros kérdésbankja.
   A diák-app (index.html) és a tanári felület (tanar.html) is ezt tölti be.
   A kérdések a diák-app ellenőrző motorját is használják (genFel, checkKi …),
   ezeket csak kérdéshúzáskor hívjuk, ezért a tanári felületen nem kellenek.
   ===================================================================== */

/* A vizsga 45 fogalma. A címeket a tanár a tanári felületen bemásolhatja
   (osztálybeállítás: concept_titles); amíg nincs, ezek látszanak. */
const LIB_EXAM_N = 45;
const LIB_DEFAULT_TITLES = {
  8: 'Algebrai kifejezés fogalma, elnevezések, egynemű kifejezések',
  18: 'A műveleti sorrend',
  45: 'JOKER'
};

/* sziget-fogalmak (K) és a kidolgozott vizsgafogalmak; island: 2 = Alkimisták szigete */
const LIB_CONCEPTS = [
 {id:'8', n:8, island:2, title:LIB_DEFAULT_TITLES[8],
  defs:[{own:true, t:'Az algebrai (betűs) kifejezés számokból és betűkből (változókból) épül fel, műveleti jelekkel és zárójelekkel összekapcsolva.'},
        {t:'Az egytagú kifejezések közül azokat, amelyek csak együtthatóikban (számszorzóikban) különböznek, egynemű kifejezéseknek nevezzük.'}],
  expl:'Elnevezések: <b>változó</b> (a betű), <b>tag</b> (a + és − jelekkel elválasztott részek, előjelükkel együtt), <b>együttható</b> (a tag számszorzója), <b>egytagú / többtagú</b> kifejezés. Egyneműek azok a tagok, amelyekben ugyanazok a betűk ugyanazon a kitevőn szerepelnek – a betűk sorrendje nem számít.',
  ex:['3a²b és −7ba² egyneműek (a sorrend nem számít).'],
  counter:['3a²b és 3ab² nem egyneműek, mert a kitevők más betűkön vannak.'],
  keys:['mi az algebrai kifejezés','a négy elnevezés','az egynemű kifejezés meghatározása','egy példa és egy ellenpélda'],
  cards:[['Mi az algebrai kifejezés?','Számokból és betűkből műveleti jelekkel (és zárójelekkel) felépített kifejezés.'],
         ['Mikor egynemű két egytagú kifejezés?','Ha csak az együtthatóikban (számszorzóikban) különböznek.'],
         ['Egynemű-e 2x és 2x²?','Nem, mert különbözik az x kitevője.'],
         ['Egynemű-e 5xy és −yx?','Igen, a betűk sorrendje nem számít.']]},
 {id:'18', n:18, island:2, title:LIB_DEFAULT_TITLES[18],
  defs:[{own:true, t:'A műveletek sorrendje: 1. zárójelek (belülről kifelé), 2. hatványozás, 3. szorzás és osztás balról jobbra, 4. összeadás és kivonás balról jobbra.'}],
  expl:'A szorzás és az osztás egyenrangú, ezeket balról jobbra végezzük. Ugyanígy az összeadás és a kivonás is egyenrangú.',
  ex:['12 − 3 · 2² = 12 − 3 · 4 = 12 − 12 = 0'],
  counter:['2 + 3 · 4 nem 20, hanem 14.','12 : 3 · 2 = 8, nem 2, mert balról jobbra haladunk.'],
  keys:['a négy lépés sorrendje','az egyenrangú műveletek balról jobbra','egy kidolgozott példa'],
  cards:[['Mit végzünk el előbb: a hatványozást vagy a szorzást?','A hatványozást.'],
         ['Mi a sorrend a szorzás és az osztás között?','Egyenrangúak, balról jobbra haladunk.'],
         ['Mennyi 2 + 3 · 4?','14'],
         ['Mennyi 20 − 8 + 2?','14 (balról jobbra, nem 10)']]},
 {id:'K1', island:2, title:'Egytagú, többtagú és egynemű kifejezés',
  defs:[{t:'A betűs kifejezések közül azokat, amelyekben csak szorzás vagy számmal történő osztás szerepel, egytagú kifejezéseknek nevezzük.'},
        {t:'Ha a különböző egytagú kifejezéseket összeadjuk vagy kivonjuk, akkor többtagú kifejezésekről beszélünk.'},
        {t:'Az egytagú kifejezések közül azokat, amelyek csak együtthatóikban (számszorzókban) különböznek, egynemű kifejezéseknek nevezzük.'}],
  expl:'A tag mindig az előtte álló előjellel együtt értendő. A tagok száma szerint egy kifejezés lehet kéttagú, háromtagú stb. Egy szám (pl. 7) is egytagú kifejezés.',
  ex:['Egytagú: 4 · a, 6 · a · a, x : 2. Kéttagú: 2 · a + 2 · b. Háromtagú: a − b − c.'],
  counter:['A −4x²y nem háromtagú, hanem egytagú: a részeit csak szorzás köti össze.'],
  keys:['egytagú kifejezés','többtagú kifejezés és a tagok száma','egynemű kifejezések','példa mindháromra'],
  cards:[['Hány tagú: 3a − 2b + 5?','Háromtagú.'],
         ['Egytagú-e a 7?','Igen, egy szám is egytagú kifejezés.'],
         ['Mik a tagjai a 4x − y kifejezésnek?','4x és −y (a tag előjelével együtt).'],
         ['Egytagú-e az x : 2?','Igen, mert számmal osztunk.']]},
 {id:'K2', island:2, title:'Együttható',
  defs:[{t:'A betűs kifejezésekben található számszorzókat együtthatónak nevezzük.'}],
  expl:'A tag előtti előjel is az együtthatóhoz tartozik: a −5ab² együtthatója −5, a −x-é −1. Ha nincs kiírva szám, az együttható 1 (vagy −1).',
  ex:['−5ab² együtthatója −5. Az a együtthatója 1, a −x együtthatója −1.'],
  counter:['A 2x² együtthatója nem 4, és nem is 2², hanem 2.'],
  keys:['a meghatározás','az előjel is hozzátartozik','a „láthatatlan” 1 és −1'],
  cards:[['Mi az együtthatója a −x-nek?','−1'],['Mi az együtthatója az ab-nek?','1'],['Mi az együtthatója a −3x²y-nak?','−3']]},
 {id:'K3', island:2, title:'Egynemű kifejezések összevonása',
  defs:[{t:'Az egynemű kifejezések egymással összevonhatók úgy, hogy az együtthatókkal elvégezzük az összeadást vagy a kivonást, és az összevonás után a betűs kifejezésnek ez lesz az együtthatója.'}],
  expl:'Csak egynemű tagokat lehet összevonni. A betűs rész változatlan marad. A tag mindig az előtte álló előjellel együtt mozog.',
  ex:['5x + 3x = 8x','4a − 7a = −3a','8x − 5 + 7 + 3y − 8x = 3y + 2'],
  counter:['3x + 2y nem vonható össze.','2x + 3x² sem vonható össze (és semmiképp nem 5x³).'],
  keys:['csak egynemű tagok vonhatók össze','az együtthatókkal számolunk, a betűs rész marad','a tag az előjelével együtt mozog','példa és ellenpélda'],
  cards:[['Összevonható-e 3x és 2y?','Nem, mert nem egyneműek.'],['Mennyi 4a − 7a?','−3a'],['Mennyi x + x?','2x (nem x²)']]},
 {id:'K4', island:2, title:'Helyettesítési érték',
  defs:[{t:'Ha a betűk helyére konkrét számokat helyettesítünk, akkor a kifejezés helyettesítési értékét kapjuk meg.'}],
  expl:'Előbb vond össze a kifejezést, csak utána helyettesíts. A negatív számot mindig zárójelbe tedd.',
  ex:['3a + 2b, ha a = 2 és b = −1: 3 · 2 + 2 · (−1) = 6 − 2 = 4'],
  counter:['Ha x = −3, akkor x² = (−3)² = 9, nem −9.'],
  keys:['a meghatározás','előbb összevonás, aztán helyettesítés','negatív szám zárójelben','kidolgozott példa'],
  cards:[['Mit jelent a helyettesítési érték?','A kifejezés értékét, ha a betűk helyére konkrét számokat írunk.'],['Mennyi x², ha x = −3?','9'],['Mennyi 2a − b, ha a = 3 és b = −2?','8']]},
 {id:'K5', island:2, title:'Zárójelbontás',
  defs:[{t:'Zárójelben szereplő összeg vagy különbség szorzása esetén a zárójel felbontásakor a zárójelben lévő összes tagot meg kell szoroznunk a szorzótényezővel, majd ezeket kell összeadnunk vagy kivonnunk.'}],
  expl:'A szorzó a zárójel minden tagjához „elér”, nem csak az elsőhöz. Ha a szorzó negatív, a zárójelben minden tag előjele megfordul. A zárójel előtti egyetlen mínusz úgy viselkedik, mint a −1-gyel való szorzás.',
  ex:['3(2x − 5) = 6x − 15','−2(a − 4) = −2a + 8','2(x + 3) − 3(x − 1) = 2x + 6 − 3x + 3 = −x + 9'],
  counter:['Rövidkarú Troll: 3(x + 4) = 3x + 4. A 4-et nem szorozta meg, helyesen 3x + 12.','Előjelhiba: −2(a − 4) = −2a − 8. Pedig −2 · (−4) = +8.'],
  keys:['a meghatározás','minden tagot megszorzunk','negatív szorzónál minden előjel megfordul','kidolgozott példa'],
  cards:[['Mit kell tenni a zárójel felbontásakor?','A zárójelben lévő összes tagot megszorozzuk a szorzótényezővel, majd ezeket összeadjuk vagy kivonjuk.'],
         ['Mennyi 4(a + 2)?','4a + 8'],['Mennyi −(x − 5)?','−x + 5'],['Mi a hiba: 3(x + 4) = 3x + 4?','A 4-et nem szorozta meg 3-mal.']]},
 {id:'K6', island:2, title:'Kiemelés',
  defs:[{t:'Ha egy összeg vagy különbség minden tagja osztható egy számmal, akkor ezt az összeget vagy különbséget úgy írhatjuk fel szorzat alakban, hogy a közös osztó lesz az egyik tényező, a visszamaradó hányadosok összege vagy különbsége zárójelbe téve a másik tényező. Ezt az átalakítást kiemelésnek nevezzük.'}],
  expl:'A kiemelés a zárójelbontás fordítottja. A közös osztóval minden tagot elosztunk, a hányadosok kerülnek a zárójelbe. Ellenőrizni visszaszorzással lehet. A legszebb, ha a legnagyobb közös osztót emeljük ki. Betűt is kiemelhetünk, ha az minden tagban szorzótényező: ilyenkor a betűt minden tagból elhagyjuk, és a zárójel elé írjuk. Ha egy tagban csak a kiemelt betű áll, a helyén 1 marad.',
  ex:['6x + 9 = 3(2x + 3)','12a − 8b = 4(3a − 2b)','ab + ac = a(b + c)','6xy − 9x = 3x(2y − 3)','ab + a = a(b + 1)'],
  counter:['Rövidkarú Troll: 6x + 9 = 3(2x + 9). A 9-et nem osztotta el 3-mal.','Félút: 12a + 8 = 2(6a + 4) nem hibás, de nem teljes. A teljes kiemelés 4(3a + 2).'],
  keys:['a meghatározás','minden tagot elosztunk a közös osztóval','ellenőrzés visszaszorzással','a legnagyobb közös osztót emeljük ki','betű is kiemelhető, ha minden tagban szorzótényező'],
  cards:[['Mikor lehet egy összegből kiemelni?','Ha minden tagja osztható egy számmal (vagy egy betű minden tagban szorzótényező).'],
         ['Emeld ki: 5a + 10','5(a + 2)'],['Emeld ki: ab + ac','a(b + c)'],['Emeld ki: x² + 3x','x(x + 3)'],
         ['Hogyan ellenőrzöd a kiemelést?','Visszaszorzással: felbontom a zárójelet.'],['Mi a legnagyobb közös osztó, amit a 8x − 12-ből ki lehet emelni?','4']]}
];
const LIB_BY_ID = Object.fromEntries(LIB_CONCEPTS.map(c => [c.id, c]));
/* a tanári felület ezt használja: a nyitható (kész) fogalmak */
const LIB_READY = LIB_CONCEPTS.map(c => c.id);
const LIB_SEAL_XP = 50, LIB_SEAL_GOLD = 20, LIB_Q_N = 6, LIB_PASS = 5;

/* ---------- segédek ---------- */
const lbR = (a, b) => a + Math.floor(Math.random() * (b - a + 1));
const lbPick = a => a[Math.floor(Math.random() * a.length)];
const lbShuf = a => { a = a.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]] } return a };
const lbN = n => (n < 0 ? '−' : '') + Math.abs(n);                       // −3
const lbS = (n, first) => first ? lbN(n) : (n < 0 ? ' − ' : ' + ') + Math.abs(n);  // tagelőjel
const lbT = (c, lt, first) => { const a = Math.abs(c); const co = (a === 1 && lt) ? '' : String(a); return (first ? (c < 0 ? '−' : '') : (c < 0 ? ' − ' : ' + ')) + co + lt };
const lbV = () => lbPick([['a','b'],['x','y'],['m','n'],['p','q']]);
const LB_SUP = {'²':'^2','³':'^3','⁴':'^4'};

/* saját, hatványt is értő kifejezés-elemző a Könyvtár „alkoss példát” kérdéseihez:
   "-3x²y + 2xy^2 - 5" -> [{c:-3, m:{x:2,y:1}, k:'x2y1'}, …] */
function lbParse(raw) {
  let s = String(raw || '').replace(/[−–]/g, '-').replace(/[²³⁴]/g, ch => LB_SUP[ch]).replace(/[·*×\s]/g, '').replace(/,/g, '.').toLowerCase();
  if (!s) return { err: 'Üres a válasz.' };
  if (/[()]/.test(s)) return { err: 'Zárójel nélkül írd be.' };
  const parts = s.match(/[+-]?[^+-]+/g);
  if (!parts || parts.join('') !== s) return { err: 'Ezt nem tudom értelmezni.' };
  const terms = [];
  for (const p of parts) {
    const m = p.match(/^([+-]?)(\d*\.?\d*)((?:[a-z](?:\^\d+)?)*)$/);
    if (!m || (!m[2] && !m[3])) return { err: `Ezt a tagot nem értem: „${p}”.` };
    let c = m[2] ? parseFloat(m[2]) : 1; if (isNaN(c)) return { err: `Ezt a számot nem értem: „${m[2]}”.` };
    if (m[1] === '-') c = -c;
    const mm = {}; (m[3].match(/[a-z](?:\^\d+)?/g) || []).forEach(x => { mm[x[0]] = (mm[x[0]] || 0) + (x.length > 1 ? parseInt(x.slice(2), 10) : 1) });
    const k = Object.keys(mm).sort().map(l => l + mm[l]).join('');
    terms.push({ c, m: mm, k });
  }
  return { terms };
}
const lbEval = (terms, vals) => terms.reduce((s, t) => s + t.c * Object.entries(t.m).reduce((p, [l, e]) => p * Math.pow(vals[l], e), 1), 0);
const lbNum = raw => { const s = String(raw || '').replace(/[−–]/g, '-').replace(/\s/g, '').replace(/,/g, '.'); if (!/^[+-]?\d+(\.\d+)?$/.test(s)) return null; return parseFloat(s) };

/* ---------- kérdéskészítők ---------- */
// mc: egy helyes; multi: több helyes; inp: beírós (check(raw1, raw2) -> {ok, msg})
function lbMC(q, right, wrongs, why, extra) {
  const opts = lbShuf([right, ...wrongs]);
  return Object.assign({ type: 'mc', q, opts, ok: opts.indexOf(right), sol: right, why }, extra || {});
}
function lbMulti(q, items, why, extra) {
  const it = lbShuf(items);
  return Object.assign({ type: 'multi', q, opts: it.map(x => x[0]), ok: it.map((x, i) => x[1] ? i : -1).filter(i => i >= 0),
    sol: it.filter(x => x[1]).map(x => x[0]).join(', '), why }, extra || {});
}
function lbInp(q, check, sol, why, extra) { return Object.assign({ type: 'inp', q, check, sol, why, fields: 1 }, extra || {}) }
function lbNumQ(q, ans, why, extra) {
  return lbInp(q, raw => { const v = lbNum(raw); if (v === null) return { invalid: true, msg: 'Itt egy számot várok.' }; return { ok: Math.abs(v - ans) < 1e-9 } },
    lbN(ans), why, Object.assign({ num: true }, extra || {}));
}
/* a diák-app motorjával ellenőrzött feladat (bontás, kiemelés, összevonás) */
function lbEng(q, task, fn, sol, why, extra) {
  return lbInp(q, (a, b) => { const r = fn(task, a, b); if (r.status === 'invalid') return { invalid: true, msg: r.msg };
      if (r.status === 'correct') return { ok: true, msg: r.note ? r.note.replace(/<[^>]+>/g, '') : '' };
      return { ok: false, msg: ((r.msg || r.explain || '') + '').replace(/<[^>]+>/g, '') } },
    sol, why, extra);
}
const lbTermsHTML = terms => terms.map((t, i) => lbT(t.c, t.lt, i === 0)).join('');
const lbHasEngine = () => typeof genFel === 'function' && typeof checkKi === 'function';

/* a 8. és a K1 „hány tagú?” kérdése */
function lbCountQ() {
  const [u, v] = lbV(); const pool = lbShuf([u, v, u + v, u + '²', '']); const n = lbR(2, 4);
  const ts = pool.slice(0, n).map((lt, i) => ({ c: (i && Math.random() < .5 ? -1 : 1) * lbR(1, 9), lt }));
  return lbNumQ(`Hány tagú ez a kifejezés: <b>${lbTermsHTML(ts)}</b>?`, n, 'A tagokat a + és − jelek választják el, a szorzás nem.');
}

/* ---------- A KÖNYVTÁROS KÉRDÉSBANKJA ----------
   minden bejegyzés egy függvény, ami egy (sablonnál minden hívásra új) kérdést ad vissza.
   def: meghatározás-kérdés (kikérdezésenként legalább 1), hunt: hibavadászat (legalább 1) */
const LIB_BANK = {
 '8': [
  () => lbMC('Egészítsd ki a meghatározást: „Az egytagú kifejezések közül azokat, amelyek csak ___ különböznek, egynemű kifejezéseknek nevezzük.”',
      'együtthatóikban (számszorzóikban)', ['betűikben', 'kitevőikben', 'előjelükben'], 'Egyneműek: ugyanazok a betűk, ugyanazon a kitevőn – csak a szám lehet más.', { def: true, lbl: 'egynemű – meghatározás' }),
  () => lbMC('Mi az algebrai (betűs) kifejezés?', 'Számokból és betűkből műveleti jelekkel (és zárójelekkel) felépített kifejezés.',
      ['Egy egyenlőség, amelyben betű is szerepel.', 'Csak betűkből álló szorzat.', 'Egy ismeretlen szám, amit ki kell számolni.'], 'Az egyenlőség (pl. 3x + 2 = 8) már egyenlet, nem kifejezés.', { def: true, lbl: 'algebrai kifejezés – meghatározás' }),
  () => { const [u, v] = lbV(), c = lbPick([-1, 1]) * lbR(2, 9), d = lbPick([-1, 1]) * lbR(2, 9);
      return lbMulti(`Melyek egyneműek a <b>${lbN(c)}${u}²${v}</b> taggal? Jelöld mindet!`,
        [[`−${u}²${v}`, true], [`${lbN(d)}${v}${u}²`, true], [`${Math.abs(c)}${u}${v}²`, false], [`${Math.abs(c)}${u}²`, false], [`${u}²${v}²`, false]],
        'Csak az egynemű, ahol ugyanazok a betűk ugyanazon a kitevőn vannak. A sorrend nem számít.', { lbl: 'egynemű tagok kiválogatása' }) },
  () => lbMC('Melyik NEM algebrai kifejezés?', '3x + 2 = 8', ['3x + 2', 'a · b', '5'], 'A 3x + 2 = 8 egyenlet, mert egyenlőségjel van benne.', { lbl: 'mi nem kifejezés' }),
  () => { const [u, v] = lbV(), c = lbR(2, 9);
      return lbInp(`Írj olyan tagot, amely egynemű a <b>${c}${u}²${v}</b> taggal, és <b>negatív</b> az együtthatója!`, raw => {
        const p = lbParse(raw); if (p.err) return { invalid: true, msg: p.err };
        if (p.terms.length !== 1) return { ok: false, msg: 'Egyetlen tagot írj!' };
        const t = p.terms[0], key = [u, v].sort().map(l => l + (l === u ? 2 : 1)).join('');
        if (t.k !== key) return { ok: false, msg: `Ez nem egynemű vele: ${u}²${v} betűrész kell.` };
        if (!(t.c < 0)) return { ok: false, msg: 'Az együttható legyen negatív!' };
        return { ok: true } }, `pl. −5${u}²${v}`, 'Ugyanaz a betűrész kell, és mínusz előjel.', { lbl: 'egynemű tag alkotása', ph: `pl. −2${u}^2${v}` }) },
  () => lbMC('Igaz vagy hamis? „2x és 2x² egynemű, mert egyezik az együtthatójuk.”', 'Hamis, mert az x kitevője különbözik.',
      ['Igaz, mert egyezik az együtthatójuk.', 'Hamis, mert különböző a betűjük.', 'Igaz, mert mindkettőben x van.'], 'Az egyneműségnél a betűs rész dönt, nem az együttható.', { lbl: '2x és 2x² egynemű-e' }),
  () => lbMC('Igaz vagy hamis? „5xy és −yx egynemű.”', 'Igaz: ugyanazok a betűk ugyanazon a kitevőn, a sorrend nem számít.',
      ['Hamis, mert más a betűk sorrendje.', 'Hamis, mert az egyik negatív.', 'Hamis, mert más az együtthatójuk.'], 'Az xy és az yx ugyanaz a szorzat.', { lbl: '5xy és −yx egynemű-e' }),
  () => lbMulti('Melyek a <b>4a − 3b + 7</b> kifejezés tagjai? Jelöld mindet!', [['4a', true], ['−3b', true], ['7', true], ['3b', false], ['4', false]],
      'A tag az előtte álló előjellel együtt tag: −3b.', { lbl: 'tagok felismerése' }),
  () => lbCountQ(),
  () => lbMC('Kétbalkezes Kelemen szerint a 3a²b és a 3ab² egynemű, „mert ugyanazok a betűk vannak bennük”. Mi a hiba?', 'A kitevők nem ugyanazokon a betűkön vannak.',
      ['Semmi, tényleg egyneműek.', 'Az együtthatójuk különbözik.', 'Egynemű csak egybetűs tag lehet.'], 'a²b: az a van négyzeten; ab²: a b van négyzeten.', { hunt: true, lbl: 'hibavadászat: a²b és ab²' })
 ],
 '18': [
  () => lbMC('Mi a műveletek helyes sorrendje?', 'zárójel → hatványozás → szorzás, osztás → összeadás, kivonás',
      ['hatványozás → zárójel → szorzás, osztás → összeadás, kivonás', 'zárójel → szorzás, osztás → hatványozás → összeadás, kivonás', 'balról jobbra, ahogy le van írva'], 'Zárójel, hatvány, szorzás-osztás, összeadás-kivonás.', { def: true, lbl: 'a sorrend' }),
  () => lbMC('Egészítsd ki: „A szorzás és az osztás ___, ezeket balról jobbra végezzük.”', 'egyenrangú műveletek',
      ['közül a szorzás az erősebb', 'közül az osztás az erősebb', 'az összeadás után jön'], 'Ugyanazon a szinten vannak, ezért balról jobbra haladunk.', { def: true, lbl: 'egyenrangú műveletek' }),
  () => { const a = lbR(2, 9), b = lbR(2, 9), c = lbR(2, 9); return lbNumQ(`Számold ki: <b>${a} + ${b} · ${c}</b>`, a + b * c, 'A szorzás előbb jön, mint az összeadás.', { lbl: 'a + b · c' }) },
  () => { const b = lbR(4, 12), a = b + lbR(3, 15), c = lbR(2, 9); return lbNumQ(`Számold ki: <b>${a} − ${b} + ${c}</b>`, a - b + c, 'Az összeadás és a kivonás egyenrangú: balról jobbra haladunk.', { lbl: 'a − b + c' }) },
  () => { const b = lbR(2, 6), q = lbR(2, 6), a = b * q, c = lbR(2, 5); return lbNumQ(`Számold ki: <b>${a} : ${b} · ${c}</b>`, q * c, 'Az osztás és a szorzás egyenrangú: balról jobbra haladunk.', { lbl: 'a : b · c' }) },
  () => { const c = lbR(2, 3), b = lbR(1, 4), a = b * c * c + lbR(0, 10); return lbNumQ(`Számold ki: <b>${a} − ${b} · ${c}²</b>`, a - b * c * c, 'Először hatványozunk, aztán szorzunk, végül kivonunk.', { lbl: 'a − b · c²' }) },
  () => lbInp('Írj egy műveletsort számokkal, amelyben a <b>szorzást</b> kell előbb elvégezni, mint az <b>összeadást</b>! (Zárójel nélkül.)', raw => {
      const s = String(raw || '').replace(/[−–]/g, '-').replace(/[·×x]/g, '*').replace(/\s/g, '');
      if (!s) return { invalid: true, msg: 'Üres a válasz.' };
      if (/[()]/.test(s)) return { invalid: true, msg: 'Zárójel nélkül írd!' };
      if (!/^\d+([+\-*:/]\d+)+$/.test(s)) return { invalid: true, msg: 'Csak számokat és műveleti jeleket írj, pl. 2 + 3 · 4' };
      if (!s.includes('+') || !s.includes('*')) return { ok: false, msg: 'Legyen benne összeadás és szorzás is!' };
      return { ok: true } }, 'pl. 2 + 3 · 4', 'Zárójel nélkül a szorzás mindig megelőzi az összeadást.', { lbl: 'műveletsor alkotása', ph: 'pl. 5 + 2 · 3' }),
  () => lbMC('Igaz vagy hamis? „Az összeadást mindig a kivonás előtt végezzük.”', 'Hamis: egyenrangúak, balról jobbra haladunk.',
      ['Igaz, mert az összeadás az első alapművelet.', 'Igaz, mert a kivonás csak a végén jön.', 'Hamis: a kivonást kell előbb.'], 'Pl. 20 − 8 + 2 = 14, nem 10.', { lbl: 'összeadás-kivonás sorrendje' }),
  () => lbMC('Mit jelent a zárójel a műveleti sorrendben?', 'A benne lévő műveletet végezzük el először.',
      ['A benne lévő műveletet a végén végezzük el.', 'Csak díszítés, nem változtat semmin.', 'A benne lévő számot negatívnak vesszük.'], 'A zárójel mindent megelőz.', { lbl: 'a zárójel szerepe' }),
  () => { const a = lbR(2, 6), b = lbR(2, 6), c = lbR(3, 6);
      return lbMC(`Zsugori Zénó szerint <b>${a} + ${b} · ${c} = ${(a + b) * c}</b>. Hol hibázott?`, `Előbb összeadott, pedig a szorzás az első (helyesen ${a + b * c}).`,
        [`Rosszul szorzott: ${b} · ${c} = ${b * c + 1}.`, `Sehol, ${(a + b) * c} a jó.`, `A ${c}-t is hozzá kellett volna adni.`], 'Zárójel nélkül a szorzás jön előbb.', { hunt: true, lbl: 'hibavadászat: sorrend' }) }
 ],
 'K1': [
  () => lbMC('Egészítsd ki: „A betűs kifejezések közül azokat, amelyekben csak ___ szerepel, egytagú kifejezéseknek nevezzük.”', 'szorzás vagy számmal történő osztás',
      ['összeadás vagy kivonás', 'egyetlen betű', 'szorzás vagy összeadás'], 'Az egytagúban nincs + és − (kivéve az előjelet).', { def: true, lbl: 'egytagú – meghatározás' }),
  () => lbMC('Egészítsd ki: „Ha a különböző egytagú kifejezéseket ___, akkor többtagú kifejezésekről beszélünk.”', 'összeadjuk vagy kivonjuk',
      ['összeszorozzuk', 'elosztjuk egy számmal', 'zárójelbe tesszük'], 'A + és − választja el a tagokat.', { def: true, lbl: 'többtagú – meghatározás' }),
  () => lbCountQ(),
  () => lbMulti('Melyek egytagú kifejezések? Jelöld mindet!', [['−4x²y', true], ['x : 2', true], ['7', true], ['2a + 2b', false], ['a − b', false]],
      'Egytagúban csak szorzás vagy számmal való osztás van. Egy szám is egytagú.', { lbl: 'egytagúak kiválogatása' }),
  () => lbMC('Igaz vagy hamis? „A 7 nem egytagú kifejezés, mert nincs benne betű.”', 'Hamis: egy szám is egytagú kifejezés.',
      ['Igaz: egytagúban betűnek kell lennie.', 'Igaz: a 7 nulla tagú.', 'Hamis: a 7 kéttagú.'], 'A szám tag is tag.', { lbl: 'a 7 egytagú-e' }),
  () => lbMC('Igaz vagy hamis? „Az x : 2 egytagú kifejezés.”', 'Igaz, mert csak számmal osztunk.',
      ['Hamis, mert osztás van benne.', 'Hamis, mert kéttagú: x és 2.', 'Igaz, mert egy betű van benne.'], 'A számmal való osztás belefér az egytagúba.', { lbl: 'x : 2 egytagú-e' }),
  () => lbMulti('Melyek a <b>4x − y</b> kifejezés tagjai? Jelöld mindet!', [['4x', true], ['−y', true], ['y', false], ['4', false], ['x', false]],
      'A tag az előjelével együtt: −y.', { lbl: 'tagok előjellel' }),
  () => lbInp('Írj egy <b>háromtagú</b> kifejezést, amelyben van <b>negatív</b> tag!', raw => {
      const p = lbParse(raw); if (p.err) return { invalid: true, msg: p.err };
      if (p.terms.length !== 3) return { ok: false, msg: `Ez ${p.terms.length} tagú, háromtagút kérek.` };
      if (new Set(p.terms.map(t => t.k)).size < 3) return { ok: false, msg: 'Van benne két egynemű tag, ezeket össze lehetne vonni. Különneműeket írj!' };
      if (!p.terms.some(t => t.c < 0)) return { ok: false, msg: 'Legyen benne negatív tag is!' };
      return { ok: true } }, 'pl. 2a − 3b + 5', 'Három különnemű tag, legalább az egyik mínusz előjellel.', { lbl: 'háromtagú alkotása', ph: 'pl. 4x − y + 1' }),
  () => { const c = lbR(2, 9), d = lbR(2, 9);
      return lbMulti(`Melyek egyneműek a <b>${c}xy</b> taggal? Jelöld mindet!`, [['−xy', true], [`${d}yx`, true], [`${c}x²y`, false], [`${c}x`, false]],
        'Ugyanaz a betűrész kell: x és y, mindkettő első hatványon.', { lbl: 'egynemű xy-nal' }) },
  () => lbMC('Kétbalkezes Kelemen: „A −4x²y háromtagú, mert három része van: −4, x² és y.” Mi a hiba?', 'Egytagú, mert a részeit csak szorzás köti össze.',
      ['Igaza van, háromtagú.', 'Kéttagú: −4 és x²y.', 'Nulla tagú, mert negatív.'], 'Tagokat csak a + és − választ el.', { hunt: true, lbl: 'hibavadászat: −4x²y' })
 ],
 'K2': [
  () => lbMC('Egészítsd ki: „A betűs kifejezésekben található ___ együtthatónak nevezzük.”', 'számszorzókat', ['betűket', 'kitevőket', 'tagokat'],
      'Az együttható a tag számszorzója.', { def: true, lbl: 'együttható – meghatározás' }),
  () => { const c = lbPick([-1, 1]) * lbR(2, 12), [u, v] = lbV(); return lbNumQ(`Mi az együtthatója a <b>${lbN(c)}${u}²${v}</b> tagnak?`, c, 'Az előjel is az együtthatóhoz tartozik.', { lbl: 'együttható leolvasása' }) },
  () => { const u = lbPick(['x', 'a', 'y', 'm']); return lbNumQ(`Mi az együtthatója a <b>−${u}</b> tagnak?`, -1, `A −${u} azt jelenti: −1 · ${u}.`, { lbl: 'láthatatlan −1' }) },
  () => { const [u, v] = lbV(); return lbNumQ(`Mi az együtthatója az <b>${u}${v}</b> tagnak?`, 1, `Az ${u}${v} azt jelenti: 1 · ${u}${v}.`, { lbl: 'láthatatlan 1' }) },
  () => lbMC('Melyik tagnak −3 az együtthatója?', '−3x²', ['3x', '−x³', 'x − 3'], 'A −3x² számszorzója −3. A −x³ együtthatója −1.', { lbl: 'melyiknek −3' }),
  () => lbMC('Igaz vagy hamis? „A 2x² együtthatója 4.”', 'Hamis: az együttható 2, a négyzet csak az x-re vonatkozik.',
      ['Igaz, mert 2² = 4.', 'Hamis: az együttható 2².', 'Hamis: az együttható x².'], 'A kitevő az x-é, nem a számé.', { lbl: '2x² együtthatója' }),
  () => lbMC('Igaz vagy hamis? „A −5ab² együtthatója −5.”', 'Igaz: az előjel is az együtthatóhoz tartozik.',
      ['Hamis: az együttható 5, előjel nélkül.', 'Hamis: az együttható −5b.', 'Hamis: az együttható 2.'], 'Az együttható a számszorzó az előjelével.', { lbl: '−5ab² együtthatója' }),
  () => { const c = lbPick([-1, 1]) * lbR(2, 9);
      return lbInp(`Írj egytagú kifejezést, amelynek az együtthatója <b>${lbN(c)}</b>, és két különböző betű van benne!`, raw => {
        const p = lbParse(raw); if (p.err) return { invalid: true, msg: p.err };
        if (p.terms.length !== 1) return { ok: false, msg: 'Egyetlen tagot írj!' };
        const t = p.terms[0]; if (Math.abs(t.c - c) > 1e-9) return { ok: false, msg: `Az együttható legyen ${lbN(c)}!` };
        if (Object.keys(t.m).length !== 2) return { ok: false, msg: 'Pontosan két különböző betű legyen benne!' };
        return { ok: true } }, `pl. ${lbN(c)}xy`, 'Szám elöl (előjellel), utána két különböző betű.', { lbl: 'tag alkotása adott együtthatóval', ph: 'pl. ' + lbN(c) + 'ab' }) },
  () => { const a = lbR(2, 9), b = lbR(2, 9); return lbNumQ(`A <b>${a}a − ${b}b</b> kifejezésben mi a b-s tag együtthatója?`, -b, 'A tag előtti mínusz is az együtthatóhoz tartozik.', { lbl: 'együttható többtagúban' }) },
  () => lbMC('Kétbalkezes Kelemen: „A 3a − 7b kifejezésben a b együtthatója 7.” Mi a hiba?', 'Lemaradt az előjel: az együttható −7.',
      ['Igaza van.', 'Az együttható 3.', 'Az együttható −7b.'], 'Az előjel is az együtthatóhoz tartozik.', { hunt: true, lbl: 'hibavadászat: lemaradt előjel' })
 ],
 'K3': [
  () => lbMC('Egészítsd ki: „Az egynemű kifejezések egymással összevonhatók úgy, hogy az ___ elvégezzük az összeadást vagy a kivonást…”', 'együtthatókkal',
      ['betűkkel', 'kitevőkkel', 'előjelekkel'], 'Az együtthatókkal számolunk, a betűs rész marad.', { def: true, lbl: 'összevonás – meghatározás' }),
  () => { const u = lbPick(['x', 'a', 'y', 'b']), a = lbR(2, 9), b = lbR(2, 9);
      return lbInp(`Vond össze: <b>${a}${u} + ${b}${u}</b>`, raw => { const p = lbParse(raw); if (p.err) return { invalid: true, msg: p.err };
        return { ok: p.terms.length === 1 && p.terms[0].k === u + '1' && p.terms[0].c === a + b } }, `${a + b}${u}`, 'Az együtthatókat adjuk össze, a betű marad.', { lbl: 'összevonás: összeadás', ph: 'pl. 5' + u }) },
  () => { const u = lbPick(['x', 'a', 'y', 'b']), a = lbR(2, 6), b = a + lbR(1, 6);
      return lbInp(`Vond össze: <b>${a}${u} − ${b}${u}</b>`, raw => { const p = lbParse(raw); if (p.err) return { invalid: true, msg: p.err };
        return { ok: p.terms.length === 1 && p.terms[0].k === u + '1' && p.terms[0].c === a - b } }, `${lbN(a - b)}${u}`, 'Az eredmény negatív is lehet.', { lbl: 'összevonás: negatív eredmény', ph: 'pl. −2' + u }) },
  () => { const t = genL1(); return lbEng(`Vond össze: <b>${exprHTML(t.terms)}</b>`, t, (task, a) => checkSimplify(task, a), exprHTML(mapToTerms(t.target)), 'Az egynemű tagokat vonjuk össze, előjelükkel együtt.', { lbl: 'összevonás: több tag', ph: 'pl. 3a − 2b' }) },
  () => lbMC('Melyik vonható össze egyetlen taggá?', '5ab − 2ba', ['3x + 2y', '2x + 3x²', '4 + 4a'], 'Az ab és a ba egynemű, így 5ab − 2ab = 3ab.', { lbl: 'mi vonható össze' }),
  () => lbMC('Igaz vagy hamis? „x + x = x²”', 'Hamis: x + x = 2x.', ['Igaz.', 'Hamis: x + x = 2.', 'Hamis: nem lehet összevonni.'], 'Összeadáskor az együtthatók adódnak össze: 1x + 1x = 2x.', { lbl: 'x + x' }),
  () => lbMC('Igaz vagy hamis? „3x² + 2x² = 5x⁴”', 'Hamis: a betűs rész változatlan marad, 5x².', ['Igaz.', 'Hamis: 6x².', 'Hamis: nem vonhatók össze.'], 'Összevonáskor a kitevő nem változik.', { lbl: '3x² + 2x²' }),
  () => { const s = lbR(5, 12);
      return lbInp(`Írj két egynemű tagot, amelyek összege <b>${s}ab</b>! (pl. két tag + vagy − jellel)`, raw => {
        const p = lbParse(raw); if (p.err) return { invalid: true, msg: p.err };
        if (p.terms.length !== 2) return { ok: false, msg: 'Pontosan két tagot írj!' };
        if (!p.terms.every(t => t.k === 'a1b1')) return { ok: false, msg: 'Mindkét tag ab-s legyen!' };
        if (p.terms.some(t => t.c === 0)) return { ok: false, msg: 'Nullás tagot ne írj!' };
        if (Math.abs(p.terms[0].c + p.terms[1].c - s) > 1e-9) return { ok: false, msg: `Összevonva nem ${s}ab jön ki.` };
        return { ok: true } }, `pl. 2ab + ${s - 2}ab`, 'Két ab-s tag, amelyek együtthatóinak összege ' + s + '.', { lbl: 'egynemű tagok alkotása', ph: 'pl. 3ab + 4ab' }) },
  () => lbMC('Mi marad változatlan az összevonáskor?', 'A betűs rész (a betűk és a kitevőik).', ['Az együttható.', 'Az előjel.', 'A tagok száma.'], 'Csak az együttható változik.', { lbl: 'mi marad változatlan' }),
  () => lbMC('Kétbalkezes Kelemen: <b>3x + 2y = 5xy</b>. Melyik szabályt sértette meg?', 'Csak egynemű tagokat lehet összevonni, a 3x és a 2y nem egynemű.',
      ['Rosszul adta össze: 3 + 2 = 6.', 'Semmit, ez jó.', 'A betűket is össze kellett volna adni: 5x + y.'], 'A 3x + 2y így marad.', { hunt: true, lbl: 'hibavadászat: különneműek' })
 ],
 'K4': [
  () => lbMC('Egészítsd ki: „Ha a betűk helyére ___ helyettesítünk, akkor a kifejezés helyettesítési értékét kapjuk meg.”', 'konkrét számokat',
      ['más betűket', 'zárójeleket', 'egynemű tagokat'], 'A helyettesítési érték egy szám.', { def: true, lbl: 'helyettesítési érték – meghatározás' }),
  () => { const p = lbR(2, 5), q = lbR(2, 5), u = lbR(1, 5), v = -lbR(1, 5);
      return lbNumQ(`Mennyi <b>${p}a + ${q}b</b>, ha a = ${u} és b = ${lbN(v)}?`, p * u + q * v, `${p} · ${u} + ${q} · (${lbN(v)}) = ${lbN(p * u + q * v)}`, { lbl: 'pa + qb értéke' }) },
  () => { const n = lbR(2, 6); return lbNumQ(`Mennyi <b>x²</b>, ha x = −${n}?`, n * n, `(−${n})² = ${n * n}, mert mínuszszor mínusz plusz.`, { lbl: 'x² negatív x-re' }) },
  () => { const p = lbR(2, 5), u = lbR(1, 6), w = lbR(1, 6);
      return lbNumQ(`Mennyi <b>${p}a − b</b>, ha a = ${u} és b = −${w}?`, p * u + w, `${p} · ${u} − (−${w}) = ${p * u + w}`, { lbl: 'pa − b értéke' }) },
  () => { const p = lbR(2, 6), q = lbR(1, 9), r = lbR(1, 6), s = lbR(1, 9), u = lbPick([-3, -2, -1, 2, 3, 4]);
      const terms = [mk(p, 'x'), mk(-q, ''), mk(r, 'x'), mk(s, '')], target = combine(terms), vals = { x: new Q(u) };
      const t = { level: 3, vars: ['x'], terms, target, vals, value: evalMap(target, vals) };
      return lbInp(`Vond össze, majd számold ki az értékét, ha x = ${lbN(u)}: <b>${exprHTML(terms)}</b>`, (a, b) => {
          const r2 = checkL3(t, a, b); if (r2.status === 'invalid' || r2.status === 'unsimplified') return { invalid: true, msg: (r2.msg || '').replace(/<[^>]+>/g, '') };
          return { ok: r2.status === 'correct', msg: r2.status === 'partial' ? (r2.eOk ? 'Jó az összevonás, de az érték nem stimmel.' : 'Az értéket jól számoltad a saját alakodból, de az összevonás hibás.') : '' } },
        `${exprHTML(mapToTerms(target))}, az értéke ${lbN(t.value.n / t.value.d)}`, 'Előbb összevonás, aztán behelyettesítés – a negatív számot zárójelbe!', { fields: 2, labels: ['Összevont alak', 'Az értéke'], lbl: 'összevonás + helyettesítés' }) },
  () => lbMC('Melyik a helyes behelyettesítés, ha x = −2, és a kifejezés 3x²?', '3 · (−2)²', ['3 · −2²', '(3 · (−2))²', '3 · (−2) · 2'], 'A negatív számot zárójelbe tesszük, és csak az x van négyzeten.', { lbl: 'helyes behelyettesítés' }),
  () => lbMC('Igaz vagy hamis? „Ha x = −3, akkor −x értéke −3.”', 'Hamis: −(−3) = 3.', ['Igaz.', 'Hamis: −x értéke 0.', 'Hamis: −x értéke −6.'], 'A −x az x ellentettje.', { lbl: '−x értéke' }),
  () => lbMC('Igaz vagy hamis? „A negatív számot behelyettesítéskor zárójelbe tesszük.”', 'Igaz, különben elveszhet az előjele.',
      ['Hamis, a zárójel fölösleges.', 'Hamis, csak a pozitívat tesszük zárójelbe.', 'Igaz, de csak ha x² van.'], 'Pl. 3 · (−2), nem 3 · −2.', { lbl: 'negatív szám zárójelben' }),
  () => { const u = lbPick([-2, -1, 2, 3]), v = lbR(4, 15);
      return lbInp(`Írj olyan kifejezést az <b>x</b> betűvel, amelynek az értéke x = ${lbN(u)} esetén <b>${v}</b>!`, raw => {
        const p = lbParse(raw); if (p.err) return { invalid: true, msg: p.err };
        if (p.terms.some(t => Object.keys(t.m).some(l => l !== 'x'))) return { invalid: true, msg: 'Csak az x betűt használd!' };
        if (!p.terms.some(t => t.m.x)) return { ok: false, msg: 'Legyen benne x is!' };
        const val = lbEval(p.terms, { x: u }); return { ok: Math.abs(val - v) < 1e-9, msg: Math.abs(val - v) < 1e-9 ? '' : `Ennek az értéke ${lbN(Math.round(val * 100) / 100)}.` } },
        `pl. x ${v - u < 0 ? '−' : '+'} ${Math.abs(v - u)}`, 'Próbáld ki: helyettesítsd be az x helyére a számot.', { lbl: 'kifejezés alkotása adott értékre', ph: 'pl. 2x + 3' }) },
  () => lbMC('Zsugori Zénó: „Ha x = −3, akkor x² = −9.” Hol hibázott?', 'A −3-at zárójelbe kell tenni: (−3)² = 9.', ['Sehol, ez jó.', 'x² = −6.', 'x² = 6.'], 'Mínuszszor mínusz plusz.', { hunt: true, lbl: 'hibavadászat: (−3)²' })
 ],
 'K5': [
  () => lbMC('Egészítsd ki: „…a zárójel felbontásakor a zárójelben lévő ___ tagot meg kell szoroznunk a szorzótényezővel…”', 'összes', ['első', 'utolsó', 'pozitív'],
      'A szorzó minden taghoz elér.', { def: true, lbl: 'zárójelbontás – meghatározás' }),
  () => { const t = genFel(1); return lbEng(`Bontsd fel a zárójelet: <b>${partsHTML(t.parts)}</b>`, t, (k, a) => checkFel(k, a), exprHTML(mapToTerms(t.target)), 'Minden tagot megszorzunk.', { lbl: 'bontás: pozitív szorzó', ph: 'pl. 3x + 6' }) },
  () => { let t; do { t = genFel(2) } while (t.combine); return lbEng(`Bontsd fel a zárójelet: <b>${partsHTML(t.parts)}</b>`, t, (k, a) => checkFel(k, a), exprHTML(mapToTerms(t.target)), 'Negatív szorzónál minden előjel megfordul.', { lbl: 'bontás: negatív szorzó', ph: 'pl. −2a + 8' }) },
  () => { const x = lbPick(['x', 'a', 'y']), n = lbR(2, 9); const parts = [{ f: mk(-1, ''), inner: [mk(1, x), mk(-n, '')] }];
      const products = expandParts(parts), t = { topic: 'zk', kind: 'fel', level: 2, vars: [x], parts, products, target: combine(products) };
      return lbEng(`Bontsd fel a zárójelet: <b>${partsHTML(parts)}</b>`, t, (k, a) => checkFel(k, a), `−${x} + ${n}`, 'A zárójel előtti mínusz minden előjelet megfordít.', { lbl: 'bontás: mínusz a zárójel előtt', ph: 'pl. −x + 5' }) },
  () => { let t; do { t = genFel(3) } while (!t.two);
      return lbEng(`Bontsd fel, majd vond össze: <b>${partsHTML(t.parts)}</b>`, t, (k, a, b) => checkFel2(k, a, b), exprHTML(mapToTerms(t.target)), 'Előbb minden zárójelet felbontunk, aztán összevonjuk az egyneműeket.', { fields: 2, labels: ['Felbontva (még összevonás nélkül)', 'Összevonva'], lbl: 'két zárójel bontása' }) },
  () => { let k, a; do { k = lbR(2, 6); a = lbR(2, 5) } while (k * a === k + a); const b = lbR(1, 7);
      return lbMC(`Melyik egyenlő a <b>${k}(${a}x − ${b})</b> kifejezéssel?`, `${k * a}x − ${k * b}`, [`${k * a}x − ${b}`, `${k + a}x − ${k * b}`, `${k * a}x + ${k * b}`], 'Minden tagot megszorzunk, az előjel marad.', { lbl: 'melyik a felbontás' }) },
  () => lbMC('Igaz vagy hamis? „−(a + b) = −a + b”', 'Hamis: mindkét tag előjele megfordul, −a − b.', ['Igaz.', 'Hamis: a + b.', 'Hamis: −a + b + 1.'], 'A mínusz a zárójel minden tagjához elér.', { lbl: '−(a + b)' }),
  () => { const k = lbR(2, 6), m = lbR(1, 6); const T = combine([mk(k, 'a'), mk(-k * m, '')]);
      return lbInp(`Írj olyan zárójeles szorzatot, amely felbontva <b>${k}a − ${k * m}</b>!`, raw => {
        const p = parseFactored(raw, ['a']); if (p.nofactor) return { invalid: true, msg: 'Zárójeles szorzatot írj, pl. 2(a − 3).' };
        if (p.err) return { invalid: true, msg: p.err }; if (p.F.c.zero) return { invalid: true, msg: 'Nullát ne írj a zárójel elé!' };
        const prod = combine(p.inner.map(t => mulT(p.F, t)));
        const ok = prod.size === T.size && [...T].every(([kk, c]) => prod.has(kk) && prod.get(kk).eq(c));
        if (ok && p.trivial) return { ok: false, msg: 'A zárójel elé is írj egy számot!' };
        return { ok, msg: ok ? '' : 'Bontsd fel a saját válaszod: nem ez jön ki.' } }, `pl. ${k}(a − ${m})`, 'Ez a kiemelés: a zárójelbontás fordítottja.', { lbl: 'szorzat alkotása', ph: 'pl. 3(a − 2)' }) },
  () => { const k = lbR(2, 9), n = lbR(1, 9); return lbNumQ(`A <b>${k}(x − ${n})</b> kifejezésben mi a szorzótényező?`, k, 'A zárójel előtt álló szám a szorzótényező.', { lbl: 'a szorzótényező' }) },
  () => { const k = lbR(2, 6), n = lbR(2, 9);
      return lbMC(`Rövidkarú Troll: <b>${k}(x + ${n}) = ${k}x + ${n}</b>. Mi a hiba?`, `Csak az első tagot szorozta meg, helyesen ${k}x + ${k * n}.`,
        ['Semmi hiba.', 'Az x-et nem kellett volna megszorozni.', `Össze kellett volna adni: ${k + n}x.`], 'A szorzó minden taghoz elér.', { hunt: true, lbl: 'hibavadászat: Rövidkarú Troll' }) }
 ],
 'K6': [
  () => lbMC('Egészítsd ki: „…a közös osztó lesz az egyik tényező, a visszamaradó ___ összege vagy különbsége zárójelbe téve a másik tényező.”', 'hányadosok',
      ['szorzatok', 'tagok', 'maradékok'], 'Minden tagot elosztunk, a hányadosok mennek a zárójelbe.', { def: true, lbl: 'kiemelés – meghatározás' }),
  () => { const t = genKi(1); return lbEng(`Emeld ki a közös tényezőt: <b>${exprHTML(t.terms)}</b>`, t, (k, a) => checkKi(k, a), factoredHTML(t.F, t.inner), 'A legnagyobb közös osztót emeld ki. Ellenőrizd visszaszorzással!', { lbl: 'kiemelés: szám', ph: 'pl. 3(2x + 5)' }) },
  () => { const t = genKi(2); return lbEng(`Emeld ki a közös tényezőt: <b>${exprHTML(t.terms)}</b>`, t, (k, a) => checkKi(k, a), factoredHTML(t.F, t.inner), 'A legnagyobb közös osztót emeld ki. Ellenőrizd visszaszorzással!', { lbl: 'kiemelés: közepes', ph: 'pl. −4(x − 2)' }) },
  () => { const [u, v] = lbV(), w = lbPick(['c', 'z', 'r']); const F = mk(1, u), inner = [mk(1, v), mk(1, w)], terms = inner.map(t => mulT(F, t));
      const t = { topic: 'zk', kind: 'ki', level: 2, vars: [u, v, w], F, inner, terms, target: combine(terms) };
      return lbEng(`Emeld ki a közös betűt: <b>${exprHTML(terms)}</b>`, t, (k, a) => checkKi(k, a), factoredHTML(F, inner), 'A minden tagban szereplő betűt emeljük ki.', { lbl: 'kiemelés: betű', ph: 'pl. a(b + c)' }) },
  () => { const u = lbPick(['x', 'a', 'y']), n = lbR(2, 9); const F = mk(1, u), inner = [mk(1, u), mk(n, '')], terms = inner.map(t => mulT(F, t));
      const t = { topic: 'zk', kind: 'ki', level: 3, vars: [u], F, inner, terms, target: combine(terms) };
      return lbEng(`Emeld ki a közös betűt: <b>${u}² + ${n}${u}</b>`, t, (k, a) => checkKi(k, a), `${u}(${u} + ${n})`, `Az ${u}² = ${u} · ${u}, ebből egy ${u} kiemelhető.`, { lbl: 'kiemelés: x² + nx', ph: 'pl. x(x + 3)' }) },
  () => { const t = genKi(3); return lbEng(`Emeld ki a közös tényezőt: <b>${exprHTML(t.terms)}</b>`, t, (k, a) => checkKi(k, a), factoredHTML(t.F, t.inner), 'Számot és betűt is kiemelhetsz egyszerre.', { lbl: 'kiemelés: szám és betű', ph: 'pl. 3x(2y − 3)' }) },
  () => { const g = lbR(2, 5); let a, b; do { a = lbR(2, 5); b = lbR(1, 7) } while (gcd(a, b) !== 1 || a === b);
      return lbMC(`Melyik a <b>${g * a}x + ${g * b}</b> helyes kiemelése?`, `${g}(${a}x + ${b})`, [`${g}(${a}x + ${g * b})`, `${g}(${g * a}x + ${g * b})`, `${g * a}(x + ${g * b})`],
        'Minden tagot elosztunk a kiemelt számmal.', { lbl: 'melyik a kiemelés' }) },
  () => lbMC('Melyik a <b>4ab + 6a</b> teljes kiemelése?', '2a(2b + 3)', ['2(2ab + 3a)', 'a(4b + 6)', '2a(2b + 6a)'], 'A 2(2ab + 3a) és az a(4b + 6) helyes, de félút: a zárójelben még van közös tényező.', { lbl: 'teljes kiemelés: 4ab + 6a' }),
  () => lbMC('Igaz vagy hamis? „A 12a + 8 = 2(6a + 4) átalakítás hibás.”', 'Hamis: helyes, csak nem teljes – a 4(3a + 2) a legszebb.',
      ['Igaz: a 8-at nem osztotta el.', 'Igaz: 2-t nem lehet kiemelni.', 'Hamis: ez a teljes kiemelés.'], 'A 6a + 4-ből még 2 kiemelhető.', { lbl: 'félút felismerése' }),
  () => { const g = lbR(2, 6); let p, q; do { p = lbR(1, 5); q = lbR(1, 7) } while (gcd(p, q) !== 1);
      return lbNumQ(`Mi a legnagyobb szám, amit a <b>${g * p}x − ${g * q}</b> kifejezésből ki lehet emelni?`, g, 'A két együttható legnagyobb közös osztója.', { lbl: 'legnagyobb közös osztó' }) },
  () => { const g = lbR(2, 6); return lbInp(`Írj egy <b>kéttagú</b> kifejezést, amelyből <b>${g}</b>-t ki lehet emelni!`, raw => {
      const p = lbParse(raw); if (p.err) return { invalid: true, msg: p.err };
      if (p.terms.length !== 2) return { ok: false, msg: 'Pontosan két tagot írj!' };
      if (p.terms[0].k === p.terms[1].k) return { ok: false, msg: 'A két tag ne legyen egynemű, mert akkor összevonható!' };
      if (!p.terms.every(t => Number.isInteger(t.c) && t.c !== 0 && t.c % g === 0)) return { ok: false, msg: `Mindkét tag együtthatója legyen osztható ${g}-vel!` };
      return { ok: true } }, `pl. ${2 * g}x + ${3 * g}`, `Mindkét együttható legyen ${g} többszöröse.`, { lbl: 'kifejezés alkotása kiemeléshez', ph: `pl. ${g}a + ${2 * g}` }) },
  () => lbMC('Igaz vagy hamis? „A kiemelést visszaszorzással ellenőrizhetjük.”', 'Igaz: a zárójelet felbontva az eredeti kifejezést kapjuk.',
      ['Hamis: csak osztással lehet ellenőrizni.', 'Hamis: a kiemelést nem lehet ellenőrizni.', 'Igaz, de csak ha szám a kiemelt tényező.'], 'A kiemelés és a zárójelbontás egymás fordítottja.', { lbl: 'ellenőrzés visszaszorzással' }),
  () => { const g = lbR(2, 5); let a, b; do { a = lbR(2, 5); b = lbR(2, 7) } while (gcd(a, b) !== 1);
      return lbMC(`Rövidkarú Troll: <b>${g * a}x + ${g * b} = ${g}(${a}x + ${g * b})</b>. Mi a hiba?`, `A ${g * b}-t nem osztotta el ${g}-vel, helyesen ${g}(${a}x + ${b}).`,
        ['Semmi hiba.', `Az ${a}x-et nem kellett volna osztani.`, `${g}-t nem lehet kiemelni.`], 'Minden tagot el kell osztani a kiemelt számmal.', { hunt: true, lbl: 'hibavadászat: Rövidkarú Troll' }) },
  () => lbMC('Kétbalkezes Kelemen: <b>ab + a = a(b + 0)</b>. Mi a hiba?', 'Ahol a tagban csak az a állt, 1 marad a helyén: a(b + 1).',
      ['Semmi hiba.', 'Az a-t nem lehet kiemelni.', 'Helyesen a(b + a).'], 'a : a = 1, nem 0. Visszaszorozva: a(b + 0) = ab, ami nem az eredeti.', { hunt: true, lbl: 'hibavadászat: a(b + 0)' })
 ]
};

/* egy kikérdezés: 6 kérdés – legalább 1 meghatározás és 1 hibavadászat, a többi vegyes */
function libQuiz(id) {
  const bank = LIB_BANK[id] || []; if (!bank.length) return [];
  const probe = bank.map(f => { try { return f() } catch (e) { return null } });
  const idx = bank.map((_, i) => i).filter(i => probe[i]);
  const defs = lbShuf(idx.filter(i => probe[i].def)), hunts = lbShuf(idx.filter(i => probe[i].hunt));
  const chosen = [];
  if (defs.length) chosen.push(defs[0]);
  if (hunts.length) chosen.push(hunts[0]);
  lbShuf(idx.filter(i => !chosen.includes(i))).forEach(i => { if (chosen.length < LIB_Q_N) chosen.push(i) });
  return lbShuf(chosen).map(i => { const q = bank[i](); q.bi = i; return q });   // friss példány (sablonnál új számokkal)
}
/* ellenőrzés: {ok, invalid, msg} */
function libCheck(q, a, b) {
  if (q.type === 'mc') return { ok: a === q.ok };
  if (q.type === 'multi') { const s = [...a].sort((x, y) => x - y); return { ok: s.length === q.ok.length && s.every((x, i) => x === q.ok[i]) } }
  try { return q.check(a, b) || { ok: false } } catch (e) { return { invalid: true, msg: 'Ezt nem tudom értelmezni.' } }
}
