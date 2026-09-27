/* «Палево»: насколько люди в доме замечают, что компьютер живёт сам.
   Пиксель должен найти Лёву тихо — если шкала дойдёт до 100%, компьютер выключат из розетки. */
const SUS_MAX=100;
function susActive(){ return state.inGame && !state.ending && !state.momOnline; }
function renderSus(){
  const el=$('#sus'); if(!el) return;
  const v=Math.round(state.sus);
  el.classList.toggle('on',susActive());
  el.classList.toggle('hot',v>=50); el.classList.toggle('crit',v>=80);
  el.querySelector('i').style.width=v+'%';
  el.title=`${L.ui.sus}: ${v}%`;
  el.setAttribute('aria-label',el.title);
}
function addSus(n,why){
  if(!susActive()) return;
  const was=state.sus;
  state.sus=Math.max(0,Math.min(SUS_MAX,state.sus+n));
  state.susMax=Math.max(state.susMax,state.sus);
  renderSus();
  if(n>0){
    if(!flag('susIntro')){ setFlag('susIntro'); say(L.lines.susIntro); }
    if(was<50 && state.sus>=50){ say(L.lines.sus50); }
    if(was<80 && state.sus>=80){ glitch(); say(L.lines.sus80); }
    if(state.sus>=SUS_MAX) caught(why);
  }
  saveGame();
}
// медленно остывает, пока Пиксель ведёт себя тихо
T.sys(4000,()=>{ if(susActive() && !camWatching() && state.sus>0) addSus(-1); });
// камера со включённым индикатором, пока мама в комнате
function camWatching(){ return state.stage===2 && W.cam && W.cam.el.style.display!=='none'; }
T.sys(1000,()=>{
  if(!susActive()||!camWatching()) return;
  if(!flag('camLed')){ setFlag('camLed'); say(L.lines.camLed); }
  addSus(2,'cam');
});

function caught(why){
  resetVisit();
  state.ending='caught'; state.inGame=false; resetVoice(); achieve('CAUGHT');
  saveGameForce();   // сохранение остаётся — можно переиграть
  sfx.drone(0); sfx.door();
  flash(1,120);
  $('#screen').style.filter='brightness(0)';
  setTimeout(()=>{
    $('#screen').style.filter='';
    document.body.dataset.ending='caught';
    const c=L.caught;
    $('#endTag').textContent=c.tag;
    $('#endTitle').textContent=c.title;
    $('#endText').textContent=why==='cam'?c.textCam:why==='dima'?c.textDima:why==='visit'?c.textVisit:c.text;
    endButtons(true);
    $('#end').classList.remove('hide');
  },900);
}
function saveGameForce(){ const e=state.ending; state.ending=null; state.inGame=true; saveGame(); state.ending=e; state.inGame=false; }
function retryAfterCaught(){
  const s=loadGame(); if(s){ s.sus=Math.min(s.sus||0,35); Store.set(KEY_SAVE,s); }
  $('#endRetry').hidden=true;
  $('#end').classList.add('hide');
  continueGame();
}
