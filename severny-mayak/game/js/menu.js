/* Главное меню, настройки, пауза, галерея финалов, титры. */

function show(id){ const el=$(id); el.classList.remove('hide','gone'); }
function hide(id){ $(id).classList.add('hide'); }

function renderTitle(){
  const hasSave=!!loadGame(), seen=Object.keys(Meta.endings).length>0;
  $('#title').innerHTML=`<div class="col">${towerSVG().replace('<svg','<svg class="art"')}
<h1>${esc(L.title)}</h1><div class="sub">${esc(L.subtitle)}</div>
<button class="power" id="tCont" ${hasSave?'':'disabled'}>${esc(L.ui.cont)}</button>
<button class="power" id="tNew">${esc(seen?L.ui.newGameNg:L.ui.newGame)}</button>
<button class="power" id="tSet">${esc(L.ui.settings)}</button>
<button class="power" id="tEnds">${esc(L.ui.endings)}</button>
<button class="power" id="tCred">${esc(L.ui.credits)}</button>
${Native.available?`<button class="power" id="tQuit">${esc(L.ui.quit)}</button>`:''}
<div class="hint">${esc(L.ui.hint)}</div></div><div class="ver">Nimbus Kids · ${esc(L.ui.ver)}</div>`;
  $('#tCont').onclick=()=>{ sfx.resume(); hide('#title'); continueGame(); };
  $('#tNew').onclick=()=>{ sfx.resume();
    if(hasSave) return confirmBox(L.ui.confirmNew,()=>{ hide('#title'); newGame(); });
    hide('#title'); newGame(); };
  $('#tSet').onclick=()=>panel(settingsHTML(false),bindSettings);
  $('#tEnds').onclick=()=>panel(endingsHTML());
  $('#tCred').onclick=()=>panel(`<div class="credits">${esc(L.credits)}</div>`);
  if($('#tQuit')) $('#tQuit').onclick=()=>Native.quit();
  setTimeout(()=>($('#tCont').disabled?$('#tNew'):$('#tCont')).focus(),50);
}
function toTitle(){
  resetRun(); state.inGame=false; state.paused=false;
  sfx.drone(0);
  hide('#pause'); hide('#end'); $('#boot').classList.add('hide');
  renderTitle(); show('#title');
}

/* панель поверх титульного экрана */
function panel(html,bind){
  const el=$('#panel'); el.innerHTML=`<div class="panel">${html}<div class="row"><button class="power" id="pBack">${esc(L.ui.back)}</button></div></div>`;
  show('#panel');
  if(bind) bind(el);
  $('#pBack').onclick=()=>{ hide('#panel'); if(!state.inGame) renderTitle(); };
  $('#pBack').focus();
}
function confirmBox(text,yes){
  const el=$('#panel'); el.innerHTML=`<div class="panel"><p style="font:15px/1.6 var(--mono);text-align:center">${esc(text)}</p><div class="row"><button class="power" id="cYes">${esc(L.ui.yes)}</button><button class="power" id="cNo">${esc(L.ui.no)}</button></div></div>`;
  show('#panel');
  $('#cYes').onclick=()=>{ hide('#panel'); yes(); };
  $('#cNo').onclick=()=>hide('#panel');
  $('#cNo').focus();
}

function settingsHTML(inGame){
  const opt=(v,cur,label)=>`<option value="${v}" ${v===cur?'selected':''}>${esc(label)}</option>`;
  return `<h2>${esc(L.ui.settings)}</h2>
<label>${esc(L.ui.sVol)}<input type="range" min="0" max="1" step="0.05" id="sVol" value="${Settings.vol}"></label>
<label>${esc(L.ui.sAmb)}<input type="range" min="0" max="1" step="0.05" id="sAmb" value="${Settings.amb}"></label>
<label>${esc(L.ui.sText)}<select id="sText">${opt('slow',Settings.text,L.ui.tSlow)}${opt('normal',Settings.text,L.ui.tNormal)}${opt('fast',Settings.text,L.ui.tFast)}${opt('instant',Settings.text,L.ui.tInstant)}</select></label>
<label>${esc(L.ui.sAuto)}<input type="checkbox" id="sAuto" ${Settings.auto?'checked':''}></label>
<label>${esc(L.ui.sFx)}<select id="sFx">${opt('full',Settings.fx,L.ui.fxFull)}${opt('low',Settings.fx,L.ui.fxLow)}</select></label>
<label>${esc(L.ui.sScares)}<input type="checkbox" id="sScares" ${Settings.scares?'checked':''}></label>
<label>${esc(L.ui.sFull)}<input type="checkbox" id="sFull" ${Native.isFullscreen()?'checked':''}></label>
<label>${esc(L.ui.sLang)}<select id="sLang" ${inGame?'disabled':''}>${Object.values(SM_LANG).map(l=>opt(l.code,Settings.lang,l.langName)).join('')}</select></label>
<div class="note">${esc(L.ui.sNote)}</div>`;
}
function bindSettings(el){
  const on=(id,ev,fn)=>el.querySelector(id).addEventListener(ev,fn);
  on('#sVol','input',e=>{ Settings.vol=+e.target.value; saveSettings(); });
  on('#sAmb','input',e=>{ Settings.amb=+e.target.value; saveSettings(); });
  on('#sText','change',e=>{ Settings.text=e.target.value; saveSettings(); });
  on('#sAuto','change',e=>{ Settings.auto=e.target.checked; saveSettings(); });
  on('#sFx','change',e=>{ Settings.fx=e.target.value; saveSettings(); });
  on('#sScares','change',e=>{ Settings.scares=e.target.checked; saveSettings(); });
  on('#sFull','change',e=>{ Native.setFullscreen(e.target.checked); });
  on('#sLang','change',e=>{ setLang(e.target.value); if(!state.inGame){ panel(settingsHTML(false),bindSettings); } });
}
function endingsHTML(){
  const n=Meta.endings;
  const row=k=>n[k]?`<div><b>${esc(L.endings[k].title)}</b><small>${esc(L.endings[k].text)}</small></div>`
    :`<div class="no"><b>${esc(L.ui.endLocked)}</b><small>${esc(L.endHint[k])}</small></div>`;
  const achN=Object.keys(L.ach).filter(k=>Meta.ach[k]).length;
  return `<h2>${esc(L.ui.endings)}</h2><div class="ends">${['a','t','b','c'].map(row).join('')}</div>
<div class="note" style="text-align:center;margin-top:14px">${esc(L.ui.achTitle)}: ${achN} / ${Object.keys(L.ach).length}</div>`;
}

/* ---------- пауза ---------- */
function openPause(direct){
  if(!state.inGame||state.ending) return;
  state.paused=true; sfx.duck(true);
  const el=$('#pause');
  const main=()=>{
    el.innerHTML=`<div class="panel"><h2>${esc(L.ui.paused)}</h2><div class="row" style="flex-direction:column;align-items:center">
<button class="power" id="pRes">${esc(L.ui.resume)}</button><button class="power" id="pSet">${esc(L.ui.settings)}</button><button class="power" id="pMenu">${esc(L.ui.toMenu)}</button>${Native.available?`<button class="power" id="pQuit">${esc(L.ui.quit)}</button>`:''}</div>
<div class="note" style="text-align:center">${esc(L.ui.saved)}</div></div>`;
    $('#pRes').onclick=closePause;
    $('#pSet').onclick=settings;
    $('#pMenu').onclick=()=>{ saveGame(); toTitle(); };
    if($('#pQuit')) $('#pQuit').onclick=()=>{ saveGame(); Native.quit(); };
    $('#pRes').focus();
  };
  const settings=()=>{
    el.innerHTML=`<div class="panel">${settingsHTML(true)}<div class="row"><button class="power" id="pBack2">${esc(L.ui.back)}</button></div></div>`;
    bindSettings(el); $('#pBack2').onclick=direct?closePause:main; $('#pBack2').focus();
  };
  direct?settings():main();
  show('#pause');
}
function closePause(){ hide('#pause'); state.paused=false; sfx.duck(false); }

/* ---------- клавиатура ---------- */
document.addEventListener('keydown',e=>{
  if(e.key==='Escape'){
    if(!$('#panel').classList.contains('hide')){ hide('#panel'); if(!state.inGame) renderTitle(); return; }
    if(state.paused) return closePause();
    if($('#menu').classList.contains('open')) return $('#menu').classList.remove('open');
    return openPause(false);
  }
  if(e.key==='F11'){ e.preventDefault(); Native.setFullscreen(!Native.isFullscreen()); return; }
  if(e.ctrlKey && e.shiftKey && e.key==='Escape'){ if(state.inGame&&!state.ending) openTM(); return; }
  const typing=e.target.closest&&e.target.closest('input,select,textarea');
  if(!typing && state.inGame && !state.paused && (e.key===' '||e.key==='Enter') && !e.target.closest('button')){ e.preventDefault(); advance(); }
});

/* ---------- экран финала ---------- */
$('#endMenu').onclick=toTitle;
$('#endCred').onclick=()=>{ $('#endText').textContent=''; $('#endTitle').textContent=''; $('#endTag').textContent='';
  $('#endText').innerHTML=`<span class="credits">${esc(L.credits)}</span>`; $('#endCred').hidden=true; };
$('#endRetry').onclick=retryAfterCaught;

/* ---------- старт ---------- */
function start(){
  applySettings();
  document.title=L.title;
  $('#boot').classList.add('hide');
  if(!Settings.warned){
    $('#warn').innerHTML=`<h2>${esc(L.ui.warnTitle)}</h2><p>${esc(L.ui.warnText).replace(/\n/g,'<br>')}</p><button class="power" id="wOk">${esc(L.ui.warnOk)}</button>`;
    show('#warn');
    $('#wOk').onclick=()=>{ Settings.warned=true; saveSettings(); hide('#warn'); renderTitle(); show('#title'); };
    $('#wOk').focus();
  } else { renderTitle(); show('#title'); }
}
window.SM={startVisit,Visit,state,T,Meta,Settings,newGame,continueGame,toTitle,openPause,addSus,collectShard,closeAll,get W(){return W;}};
start();
