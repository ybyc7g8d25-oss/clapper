/* Программы на компьютере Лёвы. */

/* ---------- ПРОЧИТАЙ.txt ---------- */
function openNote(){
  openWin('note',L.note.title,ICON.note,b=>{
    b.innerHTML=`<div class="menu-strip">${L.os.menuStrip.map(s=>`<span>${esc(s)}</span>`).join('')}</div><div class="notepad">${clue(L.note.body)}</div>`;
  },430,340);
  if(!flag('note')){ setFlag('note'); achieve('NOTE');
    say(L.lines.note,()=>{ goal('find'); scheduleVisit(25000); });
  }
}

/* ---------- рисунки ---------- */
const drawings=[
  {svg:()=>wallSVG('d1')},
  {svg:towerSVG, shard:[0,'left:71%;top:9%']},
  {svg:familySVG, shard:[5,'left:88%;top:12%']}
];
function openDrawings(){
  openWin('draw',L.drawings.folder,ICON.folder,b=>{
    b.innerHTML=`<div class="folder">${drawings.map((d,i)=>`<button class="file" data-i="${i}"><div class="th">${d.svg()}</div>${esc(L.drawings.names[i])}</button>`).join('')}</div>`;
    b.querySelectorAll('.file').forEach(f=>f.onclick=()=>openDrawing(+f.dataset.i));
  },440,240);
  if(!flag('draw')){ setFlag('draw'); say(L.lines.draw); }
}
function openDrawing(i){
  const d=drawings[i];
  openWin('img'+i,L.drawings.names[i]+' — '+L.os.viewer,ICON.note,b=>{
    b.innerHTML=`<div class="viewer"><div style="position:relative;max-width:100%;max-height:100%;aspect-ratio:${i?'600/420':'1200/800'};width:100%">${d.svg()}${d.shard?shardBtn(d.shard[0],'position:absolute;'+d.shard[1]):''}</div></div>`;
    const svg=b.querySelector('svg'); svg.style.width='100%'; svg.style.height='100%';
  },560,420);
  if(i===0 && state.stage>=3 && !flag('scare')){ setFlag('scare'); if(scare()) T.after(600,()=>say(L.lines.scare)); }
  if(i===1 && !flag('tower')){ setFlag('tower'); say(L.lines.tower); checkMid(); }
  if(i===2 && !flag('family')){ setFlag('family'); say(L.lines.family); }
}

/* ---------- журнал бесед ---------- */
function msgHTML(w,t){
  const who=w==='l'?L.log.lev:L.log.pix;
  if(w==='gap') return `<div class="msg gap">${esc(t)}</div>`;
  if(w==='sys') return `<div class="msg sys">${esc(t)}</div>`;
  if(w==='ghost') return state.ng?`<div class="msg ghost">${esc(t)}</div>`:'';
  return `<div class="msg ${w}"><b>${esc(who)}:</b> ${clue(t)}</div>`;
}
function openMemory(){
  openWin('pixel',L.log.title,ICON.pixel,b=>{
    b.innerHTML=`<div class="log">${L.log.days.map(([d,ms])=>`<div class="day">${esc(d)}</div>`+ms.map(([w,t])=>msgHTML(w,t)).join('')).join('')}</div>`;
  },460,390);
  if(!flag('mem')){ setFlag('mem'); say(L.lines.mem); checkMid(); }
}

/* ---------- браузер ---------- */
function openBrowser(){
  openWin('web',L.web.title,ICON.web,b=>{
    b.innerHTML=`<div class="browser"><div class="addr">${esc(L.web.addr)} <div>${esc(L.web.url)}</div></div><div class="offline">${esc(L.web.offline)}</div><ul class="hist">${L.web.hist.map(h=>`<li class="${h[2]?'lev':''}"><span>${esc(h[0])}</span>${clue(h[1])}</li>`).join('')}</ul></div>`;
  },540,370);
  if(!flag('web')){ setFlag('web');
    T.after(1200,()=>setStage(1));
    say(L.lines.web,()=>goal('diary')); checkMid(); }
}
function checkMid(){
  if(flag('diary')||flag('midHint')) return;
  if(flag('web') && ((flag('mem') && flag('tower')) || flag('tale3'))){ setFlag('midHint');
    T.after(400,()=>say(L.lines.mid)); }
}

/* ---------- почта ---------- */
let mailBox='inbox', mailSel=null;
function openMail(){
  openWin('mail',L.mail.title,ICON.mail,()=>{},620,420); renderMail();
  if(!flag('mail')){ setFlag('mail'); say(L.lines.mailFirst); }
}
function renderMail(){
  const w=W.mail; if(!w) return;
  const list=L.mail.letters.filter(m=>m.box===mailBox);
  const cur=L.mail.letters.find(m=>m.id===mailSel);
  const boxes=Object.entries(L.mail.boxes).map(([k,v])=>{ const n=L.mail.letters.filter(m=>m.box===k).length;
    return `<button data-b="${k}" class="${k===mailBox?'act':''}">${esc(v)} (${n})</button>`; }).join('');
  const items=list.length?list.map(m=>`<button data-m="${m.id}" class="${m.id===mailSel?'act':''} ${flag('mail_'+m.id)?'':'unread'}"><b>${esc(m.box==='inbox'?m.from.replace(/\s*<.*$/,''):(m.to||''))}</b><small>${esc(m.date.split(' ')[0])}</small><i>${esc(m.subj||L.mail.none)}</i></button>`).join(''):`<div style="padding:10px;color:#889">${esc(L.mail.empty)}</div>`;
  const read=cur?`<div class="mh"><b>${esc(L.mail.subj)}:</b> ${esc(cur.subj||L.mail.none)}<br><b>${esc(L.mail.from)}:</b> ${esc(cur.from)}${cur.to?`<br><b>${esc(L.mail.to)}:</b> ${esc(cur.to)}`:''}<br><b>${esc(L.mail.date)}:</b> ${esc(cur.date)}</div>${clue(cur.body)}${cur.shard!=null?' '+shardBtn(cur.shard):''}`:`<span style="color:#889">${esc(L.mail.pick)}</span>`;
  w.body.innerHTML=`<div class="mail"><div class="boxes">${boxes}</div><div class="right"><div class="list">${items}</div><div class="read">${read}</div></div></div>`;
  w.body.querySelectorAll('[data-b]').forEach(b=>b.onclick=()=>{ mailBox=b.dataset.b; mailSel=null; sfx.click(); renderMail(); });
  w.body.querySelectorAll('[data-m]').forEach(b=>b.onclick=()=>readMail(b.dataset.m));
}
function readMail(id){
  mailSel=id; sfx.click();
  const m=L.mail.letters.find(x=>x.id===id);
  if(!flag('mail_'+id)){ setFlag('mail_'+id); if(m.react) say(m.react);
    if(L.mail.letters.every(x=>flag('mail_'+x.id))) achieve('MAIL'); }
  renderMail();
}

/* ---------- сказка ---------- */
function openTale(){
  openWin('tale',L.tale.folder,ICON.folder,b=>{
    b.innerHTML=`<div class="folder">${L.tale.chapters.map((c,i)=>`<button class="file" data-i="${i}"><span class="fi">${ICON.note}</span>${esc(c.n)}</button>`).join('')}</div>`;
    b.querySelectorAll('.file').forEach(f=>f.onclick=()=>openChapter(+f.dataset.i));
  },440,220);
  if(!flag('tale')){ setFlag('tale'); say(L.lines.taleFirst); }
}
function openChapter(i){
  const c=L.tale.chapters[i];
  openWin('ch'+i,c.n+' — '+L.os.notepad,ICON.note,b=>{
    b.innerHTML=`<div class="tale"><h3>${esc(c.title)}</h3>${c.body.map(([w,t])=>w==='shard'?`<p>${shardBtn(t)}</p>`:`<p class="${w==='l'?'lv':''}">${clue(t)}</p>`).join('')}<div class="meta">${esc(c.meta)}</div></div>`;
  },470,400);
  if(!flag('tale'+i)){ setFlag('tale'+i); say(c.react); if(i===3) checkMid(); }
}

/* ---------- дневник ---------- */
function openDiary(){
  openWin('diary',L.diary.title,ICON.diary,b=>{
    if(flag('diary')){ showDiary(b); return; }
    b.innerHTML=`<div class="lock">${ICON.diary}<div><b>${esc(L.diary.locked)}</b></div><div style="color:#667">${esc(L.diary.hint)}</div><input type="text" aria-label="${esc(L.diary.pwLabel)}" autocomplete="off" spellcheck="false"><button class="btn primary">${esc(L.diary.open)}</button><div class="err"></div></div>`;
    const inp=b.querySelector('input'), box=b.querySelector('.lock');
    const tryIt=()=>{
      const v=inp.value.trim().toLowerCase().replace(/ё/g,'е');
      if(v && L.diary.answers.concat(SM_LANG.ru.diary.answers,SM_LANG.en?SM_LANG.en.diary.answers:[]).some(a=>v.includes(a))){
        sfx.click(); setFlag('diary'); showDiary(b); afterDiary();
      } else {
        sfx.err(); b.querySelector('.err').textContent=L.diary.err; box.classList.remove('shake'); void box.offsetWidth; box.classList.add('shake');
        state.f.pwTries=(state.f.pwTries||0)+1;
        if(state.f.pwTries===3 && !flag('midHint')){ setFlag('midHint'); say(L.lines.pwHint); }
      }
    };
    b.querySelector('button').onclick=tryIt;
    inp.addEventListener('keydown',e=>{ if(e.key==='Enter') tryIt(); e.stopPropagation(); });
    setTimeout(()=>inp.focus(),50);
  },450,400);
}
function showDiary(b){
  b.innerHTML=`<div class="diary">${L.diary.entries.map(([d,t])=>`<p><span class="d">${esc(d)}</span> ${clue(t)}</p>`).join('')}<p>${shardBtn(4)}</p></div>`;
}
function afterDiary(){
  achieve('DIARY'); setStage(2);
  say(L.lines.afterDiary,()=>goal('bin'));
  T.after(26000,()=>{ if(state.ending||flag('dontShown')) return; setFlag('dontShown'); addIcon('dont'); sfx.err(); glitch(); say(L.lines.dontAppear); });
}

/* ---------- не_открывай.txt ---------- */
function openDont(){
  if(flag('dontRead')) return;
  const id='dontw';
  openWin(id,L.dontFile.title,ICON.noteRed,b=>{ b.innerHTML=`<div class="notepad typing"></div>`; },400,260);
  const box=W[id].body.querySelector('.notepad'); const txt=L.dontFile.text; let i=0;
  const iv=T.every(TEST?5:90,()=>{
    if(!W[id]){ T.cancel(iv); return; }
    box.textContent+=txt[i++]; sfx.key();
    if(i>=txt.length){ T.cancel(iv);
      T.after(1600,()=>{ glitch(); closeWin(id); removeIcon('dont'); setFlag('dontRead'); say(L.lines.dont); });
    }
  });
}

/* ---------- камера ---------- */
function renderCam(){
  const b=W.cam && W.cam.body; if(!b) return;
  const cap = state.stage>=3 ? L.cam.dark : state.stage===2 ? L.cam.mom : L.cam.empty;
  b.innerHTML=`<div class="cam">${camSVG()}<div class="osd">${esc(L.cam.osd)} ${esc(clockStr(state.mins))}</div><div class="rec">${esc(L.cam.rec)}</div>${state.stage===2?`<div class="osd" style="top:28px;color:#ff8a80">${esc(L.cam.led)}</div>`:''}<div class="cap">${esc(cap)}</div>${state.stage>=1?shardBtn(2,'position:absolute;left:25%;top:24%'):''}</div>`;
}
function openCam(){
  openWin('cam',L.cam.title,ICON.cam,()=>{},480,340); renderCam();
  const key=state.stage>=3?'cam3':state.stage===2?'cam2':'cam0';
  if(flag(key)) return; setFlag(key);
  say(state.stage>=3?L.lines.camDark:state.stage===2?L.lines.camMom:L.lines.camEmpty);
}

/* ---------- корзина ---------- */
function openBin(){
  openWin('bin',L.bin.title,ICON.bin,b=>{
    b.innerHTML=`<div class="bin"><table><thead><tr><th>${esc(L.bin.name)}</th><th>${esc(L.bin.del)}</th><th></th></tr></thead><tbody>${L.bin.files.map((f,i)=>`<tr><td>${ICON[f.ic]}${esc(f.n)}</td><td>${esc(f.s)}</td><td><button class="btn" data-i="${i}">${esc(L.bin.restore)}</button></td></tr>`).join('')}</tbody></table></div>`;
    b.querySelectorAll('button').forEach(btn=>btn.onclick=()=>restore(+btn.dataset.i,btn));
  },500,220);
}
function restore(i,btn){
  const f=L.bin.files[i];
  if(!f.key){ sfx.click(); say([f.line]); return; }
  if(flag('restored')){ openDeadLog(false); return; }
  if(state.stage<2){
    alertWin(L.bin.lockedTitle,L.bin.locked,'stop'); glitch(); addSus(4,'beep');
    if(!flag('binTry')){ setFlag('binTry'); say(L.lines.binLocked); }
    return;
  }
  if(!flag('guardKilled')){
    alertWin(L.bin.lockedTitle,L.bin.lockedGuard,'stop'); glitch(); addSus(8,'beep');
    if(!flag('binGuard')){ setFlag('binGuard'); say(L.lines.binGuard,()=>goal('tm')); }
    return;
  }
  btn.disabled=true;
  say(L.lines.restoreStart);
  const id='rest';
  openWin(id,L.bin.progTitle,ICON.bin,b=>{
    b.innerHTML=`<div class="uninst">${esc(L.bin.prog)}<div class="bar"><i></i></div><div style="margin-top:8px;color:#667">${esc(L.bin.progSub)}</div></div>`;
  },370,150);
  let p=0; const bar=W[id].body.querySelector('i');
  const iv=T.every(220,()=>{ p+=4+Math.random()*9; bar.style.width=Math.min(p,100)+'%'; if(Math.random()<.2) glitch();
    if(p>=100){ T.cancel(iv); T.after(500,()=>{ closeWin(id); setFlag('restored'); achieve('TRUTH'); openDeadLog(true); }); } });
}
function openDeadLog(first){
  openWin('dead',L.dead.title,ICON.pixel,b=>{ b.innerHTML=`<div class="log dead"><div class="day">${esc(L.dead.head)}</div><div class="dl"></div></div>`; },470,420);
  const box=W.dead.body.querySelector('.dl');
  if(!first){ box.innerHTML=L.dead.rows.map(([w,t])=>msgHTML(w,t)).join(''); return; }
  let i=0;
  const iv=T.every(1100,()=>{
    if(!W.dead){ T.cancel(iv); reveal(); return; }
    const [w,t]=L.dead.rows[i];
    box.insertAdjacentHTML('beforeend',msgHTML(w,t));
    W.dead.body.scrollTop=1e5; sfx.tick(); i++;
    if(i>=L.dead.rows.length){ T.cancel(iv); glitch(); T.after(900,reveal); }
  });
}

/* ---------- диспетчер задач ---------- */
let tmSel=null;
function openTM(){
  openWin('tm',L.tm.title,ICON.tm,()=>{},470,340); renderTM();
  if(!flag('tm')){ setFlag('tm'); say(L.lines.tmFirst); }
  if(guardVisible() && !flag('tmGuard')){ setFlag('tmGuard'); say(L.lines.tmGuard); }
}
const guardVisible=()=>state.stage>=2 && !flag('guardKilled');
function tmProcs(){
  const mem=[2140,4870,9310,15020][state.stage];
  const list=L.tm.procs.map(p=>p[0]==='PIKSEL.EXE'?[p[0],p[1],mem]:p);
  if(guardVisible()) list.push(L.tm.guard);
  return list;
}
function renderTM(){
  const w=W.tm; if(!w) return;
  const procs=tmProcs();
  w.body.innerHTML=`<div class="tm"><div class="tabs">${L.tm.tabs.map((t,i)=>`<span style="${i?'opacity:.6':''}">${esc(t)}</span>`).join('')}</div>
<table><thead><tr><th>${esc(L.tm.name)}</th><th>${esc(L.tm.desc)}</th><th>${esc(L.tm.mem)}</th></tr></thead><tbody>${procs.map(p=>`<tr data-p="${esc(p[0])}" class="${p[0]===tmSel?'sel':''} ${p[0]===L.tm.guard[0]?'bad':''}"><td>${esc(p[0])}</td><td>${esc(p[1])}</td><td class="mem">${p[2]} ${esc(L.tm.mb)}</td></tr>`).join('')}</tbody></table>
<div class="foot"><span>${esc(L.tm.cpu)}: ${[12,37,71,99][state.stage]}% ${state.stage>=2?shardBtn(6):''}</span><button class="btn" id="tmEnd">${esc(L.tm.end)}</button></div></div>`;
  w.body.querySelectorAll('tr[data-p]').forEach(r=>r.onclick=()=>{ tmSel=r.dataset.p; sfx.click(); renderTM(); });
  w.body.querySelector('#tmEnd').onclick=endProcess;
}
function endProcess(){
  if(!tmSel){ sfx.err(); return; }
  if(tmSel==='PIKSEL.EXE'){ alertWin(L.tm.title,L.tm.pixErr,'stop'); addSus(5,'beep'); say(L.lines.tmPix); return; }
  if(tmSel!==L.tm.guard[0]){ alertWin(L.tm.title,esc(L.tm.sysErr),'stop'); addSus(5,'beep'); return; }
  const n=state.f.guardTries=(state.f.guardTries||0)+1;
  if(n<3){
    glitch(); sfx.err();
    tmSel=null; renderTM();                            // выделение само слетает
    const btn=W.tm.body.querySelector('#tmEnd');
    btn.style.transform=`translate(${-60-Math.random()*140}px,${-Math.random()*8}px)`;   // кнопка «убегает»
    resetVoice(); say(n===1?L.lines.guard1:L.lines.guard2);
    return;
  }
  resetVoice();
  say(L.lines.guard3,()=>{
    setFlag('guardKilled'); tmSel=null; renderTM(); achieve('GUARD'); sfx.door();
    alertWin(L.tm.title,esc(L.tm.ended),'info');
    say(L.lines.guardDone,()=>goal('restore'));
  });
}

/* ---------- осколки: черновик последней главы ---------- */
function openShards(){
  openWin('shards',L.ui.shards,ICON.tale,b=>{
    b.innerHTML=`<div class="tale"><h3>${esc(L.ui.shards)} — ${state.shards.length}/${L.shards.length}</h3>${L.shards.map((s,i)=>`<p>${state.shards.includes(i)?esc(s):'<span style="color:#bbb">…</span>'}</p>`).join('')}</div>`;
  },460,380);
}

/* ---------- выключение ---------- */
function tryPowerOff(){
  sfx.err();
  const n=state.f.off=(state.f.off||0)+1; saveGame();
  if(n===3){ achieve('OFF'); say(L.lines.offThird); return; }
  say(state.stage>=3?L.lines.offDark:L.lines.off);
}

/* ---------- мессенджер «Шёпот» ---------- */
let CHATS={}, chatSel='mama', choiceShown=false;
function resetChats(){
  const p=L.chat.people;
  CHATS={
    mama:{name:p.mama.name,on:false,ms:p.mama.ms.slice()},
    dima:{name:p.dima.name,on:true,ms:p.dima.ms.slice()},
    papa:{name:p.papa.name,on:false,ms:p.papa.ms.slice()}
  };
  chatSel='mama'; choiceShown=false;
}
function openChat(){
  const w=openWin('chat',L.chat.title,ICON.chat,()=>{},580,410);
  w.task.classList.remove('blink');
  renderChat();
  if(!flag('chat') && state.stage<3){ setFlag('chat'); say(L.lines.chatFirst); }
}
function renderChat(){
  const w=W.chat; if(!w) return;
  const c=CHATS[chatSel];
  const line=m=>m[0]==='me'?`<p class="me"><b>${esc(L.chat.me)}:</b> ${esc(m[1])}</p>`
    : m[0]==='lie'?`<p class="lie"><span>${esc(m[2]||'')}</span><b>${esc(L.chat.lie)}:</b> ${esc(m[1])}</p>`
    : m[0]==='st'?`<p class="st">${esc(m[1])}</p>`
    : `<p class="them"><span>${esc(m[0])}</span><b>${esc(c.name)}:</b> ${esc(m[1])}</p>`;
  w.body.innerHTML=`<div class="chat"><div class="contacts"><div class="grp">${esc(L.chat.contacts)}</div>${Object.entries(CHATS).map(([k,v])=>`<button data-k="${k}" class="${k===chatSel?'act':''}"><span class="dot ${v.on?'on':''}"></span>${esc(v.name)}</button>`).join('')}</div>
<div class="conv"><div class="hd">${esc(c.name)}<small>${esc(c.on?L.chat.online:L.chat.offline)}</small></div><div class="ms">${c.ms.map(line).join('')}</div><div class="in"></div></div></div>`;
  w.body.querySelectorAll('.contacts button').forEach(b=>b.onclick=()=>{ chatSel=b.dataset.k; renderChat(); });
  w.body.querySelector('.ms').scrollTop=1e5;
  const inp=w.body.querySelector('.in');
  if(chatSel==='mama' && state.momOnline && !state.ending && choiceShown){
    inp.innerHTML=`<div class="choice"><button class="btn primary" id="tell">${esc(L.chat.tell)}</button><button class="btn" id="silent">${esc(L.chat.silent)}</button><button class="btn danger" id="pretend">${esc(L.chat.pretend)}</button></div>`;
    inp.querySelector('#tell').onclick=endingTell; inp.querySelector('#silent').onclick=endingSilent; inp.querySelector('#pretend').onclick=endingPretend;
  } else if(state.ending){
    inp.innerHTML='';
  } else if(chatSel==='dima' && state.stage<3 && !flag('dimaAsked')){
    inp.innerHTML=`<div class="choice"><button class="btn danger" id="askDima">${esc(L.chat.askDima)}</button></div>`;
    inp.querySelector('#askDima').onclick=askDima;
  } else {
    inp.innerHTML=`<input type="text" disabled placeholder="${esc(L.chat.disabled)}"><button class="btn" disabled>${esc(L.chat.send)}</button>`;
  }
}
function pushMsg(k,who,text,extra){ CHATS[k].ms.push([who,text,extra]); renderChat(); }

/* Рискованная подсказка: написать Диме от имени Лёвы. Сильно палит компьютер. */
function askDima(){
  if(flag('dimaAsked')) return; setFlag('dimaAsked');
  const D=L.chat.dima;
  pushMsg('dima','lie',D.q,'06.10 '+clockStr(state.mins));
  seq([
    [1600,()=>{ sfx.msg(); pushMsg('dima','06.10 '+clockStr(state.mins),D.a1); }],
    [1500,()=>{ sfx.msg(); pushMsg('dima','06.10 '+clockStr(state.mins),D.a2); }],
    [1500,()=>{ sfx.msg(); pushMsg('dima','06.10 '+clockStr(state.mins),D.a3); addSus(45,'dima'); if(!state.ending) say(D.think); }]
  ]);
}
