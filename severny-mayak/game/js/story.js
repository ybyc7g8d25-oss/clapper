/* Сюжет: запуск, развязка, три финала и настоящий финал. */

const DESK=[
  {id:'note', ic:'note',  label:()=>L.desk.note,  open:openNote},
  {id:'draw', ic:'folder',label:()=>L.desk.draw,  open:openDrawings},
  {id:'pixel',ic:'pixel', label:()=>state.stage>=3?L.desk.pixelDark:L.desk.pixel, open:openMemory},
  {id:'web',  ic:'web',   label:()=>L.desk.web,   open:openBrowser},
  {id:'mail', ic:'mail',  label:()=>L.desk.mail,  open:openMail},
  {id:'tale', ic:'tale',  label:()=>L.desk.tale,  open:openTale},
  {id:'diary',ic:'diary', label:()=>L.desk.diary, open:openDiary},
  {id:'cam',  ic:'cam',   label:()=>L.desk.cam,   open:openCam},
  {id:'chat', ic:'chat',  label:()=>L.desk.chat,  open:openChat},
  {id:'bin',  ic:'bin',   label:()=>L.desk.bin,   open:openBin},
  {id:'dont', ic:'noteRed',label:()=>L.desk.dont, open:openDont, show:()=>flag('dontShown')&&!flag('dontRead')}
];

/* ---------- запуск ---------- */
function resetRun(){
  T.clear(); resetVisit(); resetVoice(); closeAll();
  Object.assign(state,{stage:0,f:{},shards:[],goal:'',mins:21*60+40,ending:null,momOnline:false,ng:false,inGame:false,sus:0,susMax:0});
  $('#endRetry').hidden=true;
  document.body.dataset.stage=0; delete document.body.dataset.ending; document.body.classList.remove('epi');
  $('#pix').classList.remove('show'); $('#goal').textContent='';
  $('#end').classList.add('hide');
  mailBox='inbox'; mailSel=null; tmSel=null;
  resetChats();
}

function bootSequence(lines,then){
  const boot=$('#boot'); boot.classList.remove('hide','gone');
  $('#bootlog').innerHTML='';
  sfx.resume();
  let i=0;
  const iv=T.every(TEST?40:650,()=>{
    $('#bootlog').insertAdjacentHTML('beforeend',`<div>${esc(lines[i])}</div>`); sfx.tick(); i++;
    if(i>=lines.length){ T.cancel(iv);
      T.after(TEST?40:900,()=>{ boot.classList.add('hide'); then(); });
    }
  });
}

function newGame(){
  resetRun();
  state.ng=Object.keys(Meta.endings).length>0;
  document.body.dataset.ng=state.ng?1:0;
  if(state.ng) achieve('NG');
  Meta.runs++; saveMeta();
  state.inGame=true; clearSave();
  buildDesk(DESK); setStage(0,true); saveGame(); renderSus();
  const lines=L.boot.lines.slice(); if(state.ng) lines[3]=L.boot.ng;
  bootSequence(lines,()=>{
    sfx.chime(); sfx.drone(0); achieve('BOOT');
    T.after(TEST?50:900,()=>{ $('#pix').classList.add('show');
      say(state.ng?L.lines.bootNg:L.lines.boot,()=>goal('note')); });
  });
}

function continueGame(){
  const s=loadGame(); if(!s) return newGame();
  resetRun();
  Object.assign(state,{stage:s.stage,f:s.f||{},shards:s.shards||[],goal:s.goal||'',mins:s.mins||state.mins,ng:!!s.ng,momOnline:false,sus:s.sus||0,susMax:s.susMax||0});
  document.body.dataset.ng=state.ng?1:0;
  state.inGame=true;
  buildDesk(DESK); setStage(state.stage,true); renderSus();
  bootSequence(L.boot.lines,()=>{
    sfx.chime(); sfx.drone(state.stage);
    T.after(TEST?50:700,()=>{ $('#pix').classList.add('show');
      goal(state.goal);
      if(flag('note')) scheduleVisit(30000);
      say(L.lines.welcome[state.stage],()=>{
        if(flag('restored') && !flag('revealed')) reveal();
        else if(flag('revealed')) momOnline();
      });
    });
  });
}

/* ---------- развязка ---------- */
function reveal(){
  if(flag('revealed')) return; setFlag('revealed');
  setStage(3);
  say(L.lines.reveal,momOnline);
}
function momOnline(){
  resetVisit();
  state.momOnline=true; CHATS.mama.on=true; chatSel='mama'; sfx.msg(); saveGame(); renderSus();
  goal('mom');
  if(W.chat) renderChat(); else openChat();
  focusWin('chat');
  const t=()=>'06.10 '+clockStr(state.mins);
  T.after(1500,()=>{ sfx.msg(); pushMsg('mama',t(),L.chat.momOn1); });
  T.after(4200,()=>{ sfx.msg(); pushMsg('mama',t(),L.chat.momOn2); });
  T.after(6200,()=>{ choiceShown=true; renderChat(); say(L.lines.choice); });
}
function lockChoice(){ state.ending='pending'; const inp=W.chat&&W.chat.body.querySelector('.in'); if(inp) inp.innerHTML=''; }
// последовательность сообщений: [задержка, функция]
function seq(steps){ let t=0; steps.forEach(([d,fn])=>{ t+=d; T.after(t,fn); }); }
function ensureChat(){ if(!W.chat){ openChat(); } chatSel='mama'; }

/* ---------- Финал А: правда (и настоящий финал) ---------- */
function endingTell(){
  lockChoice(); goal(''); resetVoice(); ensureChat();
  const k='mama', A=L.endA;
  pushMsg(k,'me',A.msg); lockChoice();
  seq([
    [1400,()=>{ pushMsg(k,'st',L.chat.typing); lockChoice(); }],
    [2000,()=>{ CHATS.mama.ms.pop(); sfx.msg(); pushMsg(k,'06.10 '+clockStr(state.mins),A.r1); lockChoice(); }],
    [1200,()=>{ sfx.msg(); pushMsg(k,'06.10 '+clockStr(state.mins),A.r2); lockChoice(); }],
    [1600,()=>{ CHATS.mama.on=false; sfx.door(); pushMsg(k,'st',L.chat.momOff); lockChoice(); say(A.run); }],
    [4800,()=>{ glitch(); state.mins=6*60+15; showClock(); flash(.5,400); }],
    [1500,()=>{ CHATS.mama.on=true; sfx.msg(); pushMsg(k,'07.10 06:15',A.f1); lockChoice(); }],
    [2500,()=>{ sfx.msg(); pushMsg(k,'07.10 06:16',A.f2); lockChoice(); }],
    [2500,()=>{ sfx.msg(); pushMsg(k,'07.10 06:18',A.f3); lockChoice();
      say(A.after,()=>{
        if(state.shards.length===L.shards.length){
          say(A.askShards,()=>{ pushMsg(k,'me',A.shardMsg); lockChoice();
            T.after(2600,()=>{ sfx.msg(); pushMsg(k,'07.10 06:24',A.shardReply); lockChoice(); T.after(1800,()=>uninstall(true)); }); });
        } else uninstall(false);
      }); }]
  ]);
}
function uninstall(full){
  const id='un', A=L.endA;
  openWin(id,A.unTitle,ICON.pixel,b=>{
    b.innerHTML=`<div class="uninst">${esc(A.unProg)}<div class="bar"><i></i></div><div class="uf" style="margin-top:8px;color:#667">${esc(A.parts[0])}</div></div>`;
  },390,160);
  let p=0, li=0; const bar=W[id].body.querySelector('i'), lab=W[id].body.querySelector('.uf');
  const iv=T.every(260,()=>{
    p+=2; bar.style.width=p+'%'; lab.textContent=A.parts[Math.min(A.parts.length-1,Math.floor(p/17))];
    if(p%30===0 && li<A.unLines.length) say([A.unLines[li++]]);
    if(p===60) $('#pix').style.opacity=.6;
    if(p>=100){ T.cancel(iv);
      T.after(2600,()=>{ $('#pix').classList.remove('show'); $('#pix').style.opacity=''; full?trueEpilogue():showEnd('a'); });
    }
  });
}
/* Настоящий финал: компьютер отформатирован, через месяц его включает Лёва. */
function trueEpilogue(){
  state.ending='pending'; closeAll(); resetVoice(); sfx.drone(0);
  $('#screen').style.transition='none';
  bootSequence(L.endT.boot,()=>{
    document.body.dataset.stage=0; document.body.dataset.ng=0; document.body.classList.add('epi');
    $('#wall').innerHTML=newWallSVG();
    $('#tasks').innerHTML='';
    $('#icons').innerHTML=`<button class="icon fresh" data-id="letter">${ICON.note}<span>${esc(L.endT.file)}</span></button>`;
    $('#frag').classList.remove('has');
    state.mins=16*60+5; showClock();
    sfx.softChime();
    const open=()=>{
      if(W.letter) return;
      openWin('letter',L.endT.fileTitle,ICON.note,b=>{ b.innerHTML=`<div class="notepad">${esc(L.endT.text)}</div>`; },460,420);
      W.letter.onClose=()=>T.after(900,()=>showEnd('t'));
      T.after(45000,()=>{ if(!state.ending||state.ending==='pending') showEnd('t'); });
    };
    const ic=$('#icons .icon'); ic.addEventListener('dblclick',open); ic.addEventListener('click',e=>{ if(coarse||e.detail===0) open(); });
    T.after(TEST?100:3500,open);
    setTimeout(()=>{ $('#screen').style.transition=''; },50);
  });
}

/* ---------- Финал Б: молчание ---------- */
function endingSilent(){
  lockChoice(); goal(''); resetVoice(); ensureChat();
  const B=L.endB;
  say(B.think);
  seq([
    [3000,()=>{ sfx.msg(); pushMsg('mama','06.10 '+clockStr(state.mins),B.m1); lockChoice(); }],
    [3500,()=>{ CHATS.mama.on=false; pushMsg('mama','st',L.chat.momOff); lockChoice(); }]
  ]);
  passDays(B.days,B.talk,9000,(d)=>goalText(d+B.dayGoal),()=>showEnd('b'));
}
function passDays(days,talk,start,onDay,done){
  days.forEach((d,i)=>T.after(start+i*5200,()=>{
    glitch(); state.mins=(state.mins+997)%(24*60); showClock();
    const icons=$$('.icon:not(.gone)').filter(x=>x.dataset.id!=='pixel'); const kill=icons[icons.length-1]; if(kill) kill.classList.add('gone');
    Object.keys(W).forEach(k=>{ if(k!=='chat' && Math.random()<.6) closeWin(k); });
    onDay(d,i); resetVoice(); say([talk[i]]);
  }));
  T.after(start+days.length*5200+2500,done);
}

/* ---------- Финал В: голос капитана ---------- */
function endingPretend(){
  lockChoice(); goal(''); resetVoice(); ensureChat();
  const C=L.endC, k='mama', t=()=>'06.10 '+clockStr(state.mins);
  const lie=(text,time)=>{ sfx.key(); pushMsg(k,'lie',text,time||t()); lockChoice(); };
  lie(C.lie1);
  seq([
    [1500,()=>say(C.think1)],
    [1800,()=>{ sfx.msg(); pushMsg(k,t(),C.r1); lockChoice(); }],
    [2400,()=>lie(C.lie2)],
    [1800,()=>{ sfx.msg(); pushMsg(k,t(),C.r2); lockChoice(); say(C.think2); }],
    [6500,()=>{ sfx.msg(); glitch(); pushMsg(k,t(),C.r3); lockChoice(); }],
    [1800,()=>{ sfx.msg(); pushMsg(k,t(),C.r4); lockChoice(); }],
    [2200,()=>lie(C.lie3)],
    [1600,()=>{ CHATS.mama.on=false; pushMsg(k,'st',L.chat.momOff); lockChoice(); }],
    [1400,()=>lie(C.lie4)]
  ]);
  passDays(C.days,C.talk,21000,(d)=>{ goalText(d); lie(C.talk[3],d); },()=>showEnd('c'));
}

/* ---------- экран финала ---------- */
function showEnd(k){
  if(state.ending && state.ending!=='pending') return;
  resetVisit();
  state.ending=k; state.inGame=false; document.body.dataset.ending=k;
  Meta.endings[k]=Meta.endings[k]||Date.now(); saveMeta(); clearSave();
  achieve({a:'END_A',b:'END_B',c:'END_C',t:'END_T'}[k]);
  if(k==='t') achieve('END_A');
  if(state.susMax<35) achieve('GHOST');
  resetVoice();
  const e=L.endings[k];
  if(k==='a'||k==='t'){ sfx.sadChime(); sfx.drone(0); } else sfx.drone(3);
  const found=['a','b','c','t'].filter(x=>Meta.endings[x]).length;
  $('#endTag').textContent=`${e.tag} · ${found}/4`;
  $('#endTitle').textContent=e.title;
  $('#endText').textContent=e.text;
  endButtons(false);
  $('#end').classList.remove('hide');
  T.after(200,()=>$('#endMenu').focus());
}

function endButtons(caught){
  $('#endRetry').textContent=L.ui.retry; $('#endRetry').hidden=!caught;
  $('#endCred').textContent=L.ui.credits; $('#endCred').hidden=caught;
  $('#endMenu').textContent=L.ui.again;
}
