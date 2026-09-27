/* Рабочий стол Nimbus 2004: окна, значки, меню, голос Пикселя, стадии мрачности. */

/* ---------- голос Пикселя ---------- */
const Voice={Q:[],busy:false,cur:null,tmr:null};
const TEXT_MS={slow:42,normal:24,fast:11,instant:0};
function say(lines,cb){ lines.forEach(l=>Voice.Q.push(l)); if(cb) Voice.Q.push(cb); if(!Voice.busy) nextLine(); }
function sayThen(lines){ return new Promise(r=>say(lines,r)); }
function resetVoice(){ T.cancel(Voice.tmr); Voice.Q=[]; Voice.busy=false; Voice.cur=null; $('#btext').textContent=''; $('#avatar').classList.remove('talk'); }
function nextLine(){
  T.cancel(Voice.tmr);
  if(Voice.hold){ Voice.tmr=T.after(200,nextLine); return; }   // Пиксель молчит, пока в комнате люди
  if(!Voice.Q.length){ Voice.busy=false; Voice.cur=null; $('#avatar').classList.remove('talk'); return; }
  Voice.busy=true;
  const it=Voice.Q.shift();
  if(typeof it==='function'){ it(); nextLine(); return; }
  typeLine(it);
}
// [[...]] — оговорка: видна только во втором прохождении
function segments(text){
  const out=[]; text.split(/\[\[(.+?)\]\]/).forEach((t,i)=>{ if(!t) return; if(i%2){ if(state.ng) out.push({t,slip:1}); } else out.push({t}); });
  return out;
}
function typeLine(text){
  const box=$('#btext'); box.textContent='';
  const segs=segments(text), full=segs.map(s=>s.t).join('');
  let si=0, ci=0, node=null, typed=0;
  const cur=Voice.cur={text:full,done:false};
  $('#avatar').classList.add('talk');
  const speed=TEST?0:TEXT_MS[Settings.text];
  const put=ch=>{
    if(!node){ node=document.createElement('span'); if(segs[si].slip) node.className='slip'; box.appendChild(node); }
    node.textContent+=ch;
  };
  const step=()=>{
    if(Voice.hold){ Voice.tmr=T.after(200,step); return; }
    if(si>=segs.length) return done();
    const s=segs[si];
    if(ci<s.t.length){
      const ch=s.t[ci++]; put(ch); typed++;
      if(typed%2===0) sfx.tick();
      Voice.tmr=T.after('.!?…'.includes(ch)?speed*6:(state.stage>=3?speed*1.6:speed), step);
    } else { si++; ci=0; node=null; step(); }
  };
  const done=()=>{
    cur.done=true; $('#avatar').classList.remove('talk');
    if(Settings.auto||TEST) Voice.tmr=T.after(TEST?300:Math.max(1800,full.length*48), nextLine);
  };
  cur.finish=()=>{ T.cancel(Voice.tmr); box.innerHTML=segs.map(s=>s.slip?`<span class="slip">${esc(s.t)}</span>`:esc(s.t)).join(''); done(); };
  if(!speed) cur.finish(); else step();
}
function advance(){ const c=Voice.cur; if(!c) return; if(!c.done) c.finish(); else nextLine(); }
$('#bubble').addEventListener('click',advance);
$('#bubble').addEventListener('keydown',e=>{ if(e.key==='Enter'||e.key===' '){ e.preventDefault(); advance(); } });
function goal(key){
  state.goal=key||''; saveGame();
  const t=key?(L.goals[key]||key):'';
  $('#goal').textContent=t?L.ui.goal+t:'';
}
function goalText(t){ $('#goal').textContent=t; }

/* ---------- стадии ---------- */
function setStage(n,quiet){
  if(n<=state.stage && !quiet) return;
  state.stage=n; document.body.dataset.stage=n;
  $('#avatar').innerHTML=avatarSVG(n);
  sfx.drone(n);
  if(!quiet) glitch();
  const l=document.querySelector('[data-id="pixel"] span'); if(l) l.textContent=n>=3?L.desk.pixelDark:L.desk.pixel;
  if(W.cam) renderCam();
  if(W.tm) renderTM();
  saveGame();
}
function glitch(){
  sfx.glitch();
  if(Settings.fx==='low'||matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  const s=$('#screen'); s.classList.remove('glitch'); void s.offsetWidth; s.classList.add('glitch');
  flash(.18,70);
}
function flash(o,ms){ if(Settings.fx==='low') return; const f=$('#fx .flash'); f.style.opacity=o; setTimeout(()=>f.style.opacity=0,ms); }
function scare(){
  if(!Settings.scares||TEST) return false;
  const el=$('#scare'); el.innerHTML=avatarSVG(3,true); el.classList.add('on'); sfx.scare();
  setTimeout(()=>el.classList.remove('on'),480);
  return true;
}
// шёпот: подписи значков и часы на миг меняются
T.sys(1000,()=>{
  if(!state.inGame||state.ending||state.stage<2) return;
  if(Math.random() < (state.stage===2?.035:.08)){
    glitch();
    const sp=rnd($$('.icon:not(.gone) span')); if(sp){ const old=sp.textContent; sp.textContent=rnd(L.whispers); setTimeout(()=>sp.textContent=old,650); }
    const ck=$('#clock'), o=ck.textContent; ck.textContent='23:58'; setTimeout(()=>ck.textContent=o,650);
  }
});

/* ---------- часы ---------- */
const showClock=()=>{ $('#clock').textContent=clockStr(state.mins); };
T.sys(60000,()=>{ if(state.inGame&&!state.ending){ state.mins++; showClock(); } });

/* ---------- окна ---------- */
let zTop=100, casc=0; const W={};
function openWin(id,title,icon,build,w=460,h=340){
  sfx.click();
  if(W[id]){ W[id].el.style.display='flex'; focusWin(id); return W[id]; }
  const scr=$('#screen'), vw=scr.clientWidth, vh=scr.clientHeight-40;
  const ww=Math.min(w,vw-12), hh=Math.min(h,vh-(vw<700?150:16));
  let x,y;
  if(vw<700){ x=(vw-ww)/2; y=6; }
  else { x=Math.max(8,Math.min(130+casc*28, vw-ww-10)); y=Math.max(6,Math.min(30+casc*24, vh-hh-10)); casc=(casc+1)%6; }
  const el=document.createElement('div'); el.className='win'; el.setAttribute('role','dialog'); el.setAttribute('aria-label',plain(title)); el.dataset.win=id;
  el.style.cssText=`left:${x}px;top:${y}px;width:${ww}px;height:${hh}px`;
  el.innerHTML=`<div class="tb"><span class="ic">${icon}</span><span class="t">${esc(title)}</span><button class="mn" aria-label="${esc(L.os.min)}">_</button><button class="x" aria-label="${esc(L.os.close)}">×</button></div><div class="wb"></div>`;
  $('#windows').appendChild(el);
  const task=document.createElement('button'); task.className='task'; task.innerHTML=`<span class="ic">${icon}</span><span>${esc(title)}</span>`;
  $('#tasks').appendChild(task);
  W[id]={el,task,body:el.querySelector('.wb')};
  el.addEventListener('pointerdown',()=>focusWin(id));
  el.querySelector('.x').onclick=e=>{ e.stopPropagation(); closeWin(id); };
  el.querySelector('.mn').onclick=e=>{ e.stopPropagation(); el.style.display='none'; task.classList.remove('on'); };
  task.onclick=()=>{ task.classList.remove('blink');
    if(el.style.display==='none'){ el.style.display='flex'; focusWin(id); }
    else if(task.classList.contains('on')){ el.style.display='none'; task.classList.remove('on'); }
    else focusWin(id); };
  drag(el, el.querySelector('.tb'));
  build(W[id].body);
  focusWin(id);
  return W[id];
}
function focusWin(id){
  for(const k in W){ W[k].el.classList.toggle('inactive',k!==id); W[k].task.classList.toggle('on',k===id && W[k].el.style.display!=='none'); }
  if(W[id]) W[id].el.style.zIndex=++zTop;
}
function closeWin(id){ const w=W[id]; if(!w) return; if(w.onClose) w.onClose(); w.el.remove(); w.task.remove(); delete W[id]; }
function closeAll(){ Object.keys(W).forEach(closeWin); casc=0; }
function drag(el,h){
  h.addEventListener('pointerdown',e=>{
    if(e.target.closest('button')) return;
    const sx=e.clientX, sy=e.clientY, ox=el.offsetLeft, oy=el.offsetTop;
    h.setPointerCapture(e.pointerId);
    const mv=ev=>{ const s=$('#screen');
      el.style.left=Math.max(80-el.offsetWidth, Math.min(ox+ev.clientX-sx, s.clientWidth-80))+'px';
      el.style.top=Math.max(0, Math.min(oy+ev.clientY-sy, s.clientHeight-70))+'px'; };
    const up=()=>{ h.removeEventListener('pointermove',mv); h.removeEventListener('pointerup',up); };
    h.addEventListener('pointermove',mv); h.addEventListener('pointerup',up);
  });
}
function alertWin(title,html,icon='warn'){
  sfx.err();
  const id='alert'+(++zTop);
  openWin(id,title,ICON[icon],b=>{
    b.innerHTML=`<div class="alertbox">${ICON[icon]}<div class="txt">${html}<div class="row"><button class="btn primary">${esc(L.os.ok)}</button></div></div></div>`;
    b.querySelector('button').onclick=()=>closeWin(id);
    setTimeout(()=>b.querySelector('button').focus(),30);
  },380,180);
  return id;
}

/* ---------- осколки сказки ---------- */
function shardBtn(i,style=''){
  if(state.shards.includes(i)) return '';
  return `<button class="shard${style?'':' inline'}" data-shard="${i}" style="${style}" aria-label="✦">✦</button>`;
}
document.addEventListener('click',e=>{
  const b=e.target.closest('.shard'); if(!b||state.ending) return;
  e.stopPropagation(); collectShard(+b.dataset.shard); b.remove();
});
function collectShard(i){
  if(state.shards.includes(i)) return;
  state.shards.push(i); saveGame(); sfx.shard(); updateShardTray();
  toast(L.ui.shards,`${state.shards.length} / ${L.shards.length} — «${L.shards[i]}»`);
  if(state.shards.length===L.shards.length){ achieve('SHARDS'); say(L.lines.shardsAll); }
  else if(!flag('shard1')){ setFlag('shard1'); say(L.lines.shardFirst); }
  else say(L.lines.shard);
}
function updateShardTray(){
  const el=$('#frag'); const n=state.shards.length;
  el.classList.toggle('has',n>0); el.innerHTML=`${ICON.star}<span>${n}/${L.shards.length}</span>`;
  el.title=L.ui.shards;
}

/* ---------- значки и меню ---------- */
function buildDesk(list){
  $('#wall').innerHTML=wallSVG('w');
  $('#avatar').innerHTML=avatarSVG(state.stage);
  $('#startBtn').innerHTML=ICON.cloud+esc(L.os.start);
  $('#snd').innerHTML=sfx.on?ICON.spk:ICON.mute; $('#snd').setAttribute('aria-label',L.os.sound);
  $('#bubble .who').innerHTML=`<span>${esc(L.log.pix)}</span><i>${esc(L.ui.click)}</i>`;
  $('#icons').innerHTML=list.filter(d=>!d.show||d.show()).map(iconHTML).join('');
  $$('.icon').forEach(bindIcon);
  const lab=document.querySelector('[data-id="pixel"] span'); if(lab && state.stage>=3) lab.textContent=L.desk.pixelDark;
  $('#menu').innerHTML=`<div class="head">${ICON.pixel}${esc(L.os.user)}</div>
<button data-a="draw">${ICON.folder}${esc(L.desk.draw)}</button><button data-a="pixel">${ICON.pixel}${esc(L.desk.pixel)}</button><button data-a="web">${ICON.web}${esc(L.desk.web)}</button><button data-a="mail">${ICON.mail}${esc(L.desk.mail)}</button><button data-a="chat">${ICON.chat}${esc(L.desk.chat)}</button><hr><button data-a="tm">${ICON.tm}${esc(L.os.taskmgr)}</button><button data-a="settings">${ICON.gear}${esc(L.ui.settings)}</button><hr><button data-a="off">${ICON.power}${esc(L.os.off)}</button>`;
  $('#menu').querySelectorAll('button').forEach(b=>b.onclick=()=>{
    $('#menu').classList.remove('open');
    if(state.ending) return;
    const a=b.dataset.a;
    if(a==='off') return tryPowerOff();
    if(a==='tm') return openTM();
    if(a==='settings') return openPause(true);
    DESK.find(x=>x.id===a).open();
  });
  $('#hideAll').title=L.ui.hideAll; $('#hideAll').setAttribute('aria-label',L.ui.hideAll);
  updateShardTray(); showClock();
}
function iconHTML(d){ return `<button class="icon" data-id="${d.id}">${ICON[d.ic]}<span>${esc(d.label())}</span></button>`; }
function bindIcon(b){
  const d=DESK.find(x=>x.id===b.dataset.id);
  b.addEventListener('click',e=>{
    if(state.ending) return;
    $$('.icon').forEach(x=>x.classList.remove('sel')); b.classList.add('sel');
    if(coarse || e.detail===0) d.open();
  });
  b.addEventListener('dblclick',()=>{ if(!coarse && !state.ending) d.open(); });
  b.addEventListener('keydown',e=>{ if(e.key==='Enter'&&!state.ending){ e.preventDefault(); d.open(); } });
}
function addIcon(id){
  if(document.querySelector(`.icon[data-id="${id}"]`)) return;
  const d=DESK.find(x=>x.id===id); const wrap=document.createElement('div'); wrap.innerHTML=iconHTML(d);
  const b=wrap.firstChild; b.classList.add('fresh'); $('#icons').appendChild(b); bindIcon(b);
}
function removeIcon(id){ const b=document.querySelector(`.icon[data-id="${id}"]`); if(b) b.remove(); }

$('#startBtn').onclick=e=>{ e.stopPropagation(); sfx.click(); $('#menu').classList.toggle('open'); };
document.addEventListener('pointerdown',e=>{
  if(!e.target.closest('#menu')&&!e.target.closest('#startBtn')) $('#menu').classList.remove('open');
  if(!e.target.closest('.icon')) $$('.icon').forEach(x=>x.classList.remove('sel'));
});
$('#snd').onclick=()=>{ const on=sfx.toggle(); $('#snd').innerHTML=on?ICON.spk:ICON.mute; };
$('#frag').onclick=()=>{ if(state.inGame&&!state.ending) openShards(); };
