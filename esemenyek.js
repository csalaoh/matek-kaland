/* =====================================================================
   Matek-kaland – NAPI ESEMÉNYEK (közös lista: diák-app + tanári felület)
   Új esemény: másold le egy sort, adj neki új id-t. Az id-t soha ne írd át,
   mert a szerver ezzel tárolja, mi jött ki aznap.

   r (ritkaság):  c = közönséges (súly 10) · r = ritka (súly 3) · l = legendás (súly 1)
   w:             egyedi súly (ha a ritkaság alapsúlya nem jó)
   ora:           csak matekórán sorsolható (a teremben kell hozzá a tanár)
   kezi:          sosem sorsolódik, csak a tanár választhatja ki (felülírás)
   fx:            hatás az appban
     gold / xp     arany- / XP-szorzó        crit     kritikus esély (alap: 15%)
     ap / arany    egyszeri ajándék aznap    brave    a 3. fokozat XP-szorzója
     weak          az első aréna-ellenfél jutalmának szorzója
     strong        az aréna-ellenfelek életerő-szorzója
     rew           az aréna-ellenfelek jutalmának szorzója
     hp            a szörnyek életerő-szorzója (Küszöbőr is)
     shop          bolti árszorzó            kupon    a kiváltságok AP-árának szorzója
     palca         elrejtett varázspálca a faluban (+30 arany, egyszer)
     bocs          a szörnyek bocsánatot kérnek, amikor megütnek
   ===================================================================== */
var MK_EVENTS = [
  // ---- közönséges, appos hatással ----
  {id:'gold',  r:'c', ic:'💰', n:'Aranyeső',              d:'A kincstár ma bőkezű: minden arany-jutalom másfélszeres.', fx:{gold:1.5}},
  {id:'xp',    r:'c', ic:'📘', n:'A tudás napja',         d:'Ma minden XP másfélszeres.', fx:{xp:1.5}},
  {id:'crit',  r:'c', ic:'⚡', n:'Szerencsecsillag',      d:'Ma kétszer gyakrabban jön kritikus ütés (30%).', fx:{crit:.3}},
  {id:'ap',    r:'c', ic:'🔮', n:'Varázsforrás',          d:'Ma +5 AP-t kapsz ajándékba.', fx:{ap:5}},
  {id:'weak',  r:'c', ic:'🎯', n:'Edzőnap',               d:'{e0}: ma dupla jutalom jár a legyőzéséért.', fx:{weak:2}},
  {id:'strong',r:'c', ic:'🛡️', n:'Megerősödött szörnyek', d:'Az aréna ellenfelei ma 20%-kal erősebbek, de másfélszeres jutalmat adnak.', fx:{strong:1.2,rew:1.5}},
  {id:'brave', r:'c', ic:'🔥', n:'A bátrak napja',        d:'Ma a 3. fokozatú jó válasz másfélszeres XP-t ér.', fx:{brave:1.5}},
  {id:'calm',  r:'c', w:5, ic:'🌙', n:'Csendes nap',      d:'Ma nincs különleges esemény – sima gyakorlás.', fx:{}},
  // ---- közönséges, csak órán (a régi órai lista) ----
  {id:'villam',  r:'c', w:6, ora:1, ic:'⚡', n:'Villámkérdés',       d:'Az első három jó válaszoló +30 XP-t kap.', fx:{}},
  {id:'fordit',  r:'c', w:6, ora:1, ic:'🔄', n:'Fordított szerep',   d:'Ma egy diák vezeti az óra eleji fejtörőt.', fx:{}},
  {id:'tanfelel',r:'c', w:6, ora:1, ic:'🙋', n:'A Mester felel',     d:'Egy diák feltehet a Mesternek egy fejtörőt. Ha a Mester nem tudja megoldani, az osztály minden tagja +20 XP-t kap.', fx:{}},
  {id:'hibavad', r:'c', w:6, ora:1, ic:'🔍', n:'Hibavadászat',       d:'A táblán elrejtett számolási hiba megtalálója +25 XP-t kap.', fx:{}},
  {id:'padsor',  r:'c', w:6, ora:1, ic:'🎲', n:'Szerencsés padsor',  d:'A Mester kisorsol egy padsort, annak minden tagja +15 XP-t kap.', fx:{}},
  {id:'zenes',   r:'c', w:6, ora:1, ic:'🎧', n:'Zenés önálló munka', d:'Ma mindenki hallgathat zenét az önálló feladat alatt.', fx:{}},
  // ---- ritka ----
  {id:'vasar',  r:'r', ic:'🛒', n:'Vásári nap',                    d:'A Boltban ma minden 25%-kal olcsóbb.', fx:{shop:.75}},
  {id:'natha',  r:'r', ic:'🤧', n:'A Szundikáló Sárkány megfázott', d:'Az egész szörnynépség elkapta tőle: ma minden szörny 10%-kal kevesebb életerővel indul. Hapci!', fx:{hp:.9}},
  {id:'bocs',   r:'r', ic:'🙇', n:'Fordított nap',                 d:'A szörnyek ma nagyon udvariasak: minden ütés után bocsánatot kérnek. (Attól még fáj.)', fx:{bocs:1}},
  // ---- legendás (rólam szól) ----
  {id:'palca',  r:'l', ic:'🪄', n:'A Mester elhagyta a varázspálcáját', d:'Valahol a faluban hever. Aki megtalálja és rákoppint, +30 aranyat kap jutalmul.', fx:{palca:30}},
  {id:'kave',   r:'l', ic:'☕', n:'A Mester kávéja kifogyott',          d:'A szörnyek megérezték a gyengeséget: ma 20%-kal erősebbek, de dupla jutalmat adnak.', fx:{strong:1.2,rew:2}},
  {id:'vicc',   r:'l', ora:1, ic:'🤡', n:'A Mester viccet mond',        d:'Az óra elején a Mester elmond egy nagyon rossz viccet. Ha az egész osztály egyszerre felnyög, mindenki +2 AP-t kap fájdalomdíjként.', fx:{ap:2}},
  // ---- csak kézzel (tanári felülírás) ----
  {id:'jokedv', r:'l', kezi:1, ic:'😄', n:'A Mester ma jókedvű',        d:'Ma minden kiváltság fele annyi AP-ba kerül.', fx:{kupon:.5}},
  {id:'suveg',  r:'l', kezi:1, ic:'🎩', n:'Varázslósüveges óra',        d:'A Mester ma varázslósüvegben tanít. Aki nevetés nélkül kibírja az órát, +3 AP-t kap.', fx:{}},
  {id:'wro',    r:'l', kezi:1, ic:'🤖', n:'A Mester robotot épít',      d:'A Mester a robotversenyre készül, a szörnyek kihasználják: ma 20%-kal erősebbek, de másfélszeres jutalmat adnak.', fx:{strong:1.2,rew:1.5}},
  {id:'szulnap',r:'l', kezi:1, ic:'🎂', n:'A Mester születésnapja',     d:'A Mester ma ajándékot oszt: +5 AP és +30 arany mindenkinek.', fx:{ap:5,arany:30}},
  {id:'dolgozat',r:'c',kezi:1, ic:'📝', n:'Csendes készülődés',         d:'Ma nincs különleges esemény – mindenki a dolgozatra figyel.', fx:{}}
];

/* Ünnepi napok: ezeken a napi esemény mellé automatikusan jön egy második.
   A dátumok a 2026/27-es tanév rendje szerint (Mikulás és Pi-nap: a hétvége előtti pénteken). */
var MK_HOLIDAYS = {
  '2026-12-04': {id:'mikulas', ic:'🎅', n:'Mikulás-csomag',          d:'A Mikulás a faluban járt: +30 arany és +5 AP mindenkinek.', fx:{arany:30,ap:5}},
  '2026-12-18': {id:'telszun', ic:'❄️', n:'Utolsó nap a szünet előtt', d:'Ma minden XP dupla – vigyél magaddal egy kis előnyt a szünetre!', fx:{xp:2}},
  '2027-01-04': {id:'ujev',    ic:'🎆', n:'Újévi fogadalom',          d:'Új év, új kaland: ma +5 AP-t kapsz.', fx:{ap:5}},
  '2027-01-22': {id:'felev',   ic:'📜', n:'Félévzáró',                d:'Fél év kaland van mögötted: ma minden arany-jutalom dupla.', fx:{gold:2}},
  '2027-03-12': {id:'pinap',   ic:'🥧', n:'Pi-nap',                   d:'Ma minden arany-jutalom π/2 ≈ 1,57-szeres. Ennél kerekebb nap nincs.', fx:{gold:1.57}},
  '2027-03-24': {id:'tavszun', ic:'🌷', n:'Utolsó nap a tavaszi szünet előtt', d:'Ma minden XP dupla.', fx:{xp:2}},
  '2027-06-18': {id:'tanevzar',ic:'🏆', n:'Tanévzáró',                d:'Az utolsó nap: dupla arany és dupla XP. Hősök vagytok!', fx:{gold:2,xp:2}}
};

var MK_RARITY = {c:{n:'Közönséges',w:10}, r:{n:'Ritka',w:3}, l:{n:'Legendás',w:1}};

function mkEvById(id){
  if(!id)return null;
  for(var i=0;i<MK_EVENTS.length;i++)if(MK_EVENTS[i].id===id)return MK_EVENTS[i];
  for(var k in MK_HOLIDAYS)if(MK_HOLIDAYS[k].id===id)return Object.assign({r:'u'},MK_HOLIDAYS[k]);
  return null;
}
function mkHoliday(day){var h=MK_HOLIDAYS[day];return h?Object.assign({r:'u'},h):null}

/* súlyozott választás. opt: {ora: matekórán nyílik-e, recent: az előző napok id-jei (legfrissebb elöl), rnd: 0..1 függvény} */
function mkPickEvent(opt){
  opt=opt||{};var recent=opt.recent||[],rnd=opt.rnd||Math.random;
  var hadLegend=recent.slice(0,10).some(function(id){var e=mkEvById(id);return e&&e.r==='l'});
  var pool=MK_EVENTS.filter(function(e){
    if(e.kezi)return false;
    if(e.ora&&!opt.ora)return false;
    if(recent.slice(0,5).indexOf(e.id)>=0)return false;
    if(e.r==='l'&&hadLegend)return false;
    return true});
  var tot=0;pool.forEach(function(e){tot+=e.w||MK_RARITY[e.r].w});
  var x=rnd()*tot;for(var i=0;i<pool.length;i++){x-=pool[i].w||MK_RARITY[pool[i].r].w;if(x<0)return pool[i]}
  return pool[pool.length-1];
}
/* kapcsolat nélkül (vendég mód): a dátumból számolt, mindenkinél egyforma választás */
function mkDateRnd(day){var h=7;for(var i=0;i<day.length;i++)h=(h*31+day.charCodeAt(i))%2147483647;return function(){h=(h*16807)%2147483647;return h/2147483647}}
