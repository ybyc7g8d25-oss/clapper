/* Прятки: в комнату заходят люди. Услышал шаги — сверни окна и замри.
   Пока человек в комнате, любое движение мыши, клик или клавиша поднимают «палево». */
const Visit={phase:null,who:'',moved:0,openAtArrive:0,last:0,next:null,steps:null,end:null,count:0};

function visitAllowed(){
  return state.inGame && !state.ending && !state.momOnline && state.stage<3 && flag('note')
    && !Visit.phase && !W.rest && !W.dead && !W.dontw && !W.un;
}
function scheduleVisit(ms){
  T.cancel(Visit.next);
  if(TEST && !QS.has('visits')) return;
  Visit.next=T.after(ms??(state.stage===2?45000+Math.random()*45000:80000+Math.random()*70000),()=>startVisit());
}
function visibleWins(){ return Object.values(W).filter(w=>w.el.style.display!=='none').length; }

function startVisit(){
  if(!visitAllowed()){ scheduleVisit(15000); return; }
  const first=!flag('visitTut');
  Visit.phase='warn'; Visit.moved=0; Visit.count++;
  Visit.who=state.stage===2?L.visit.mom:rnd([L.visit.mom,L.visit.dad]);
  document.body.dataset.visit='warn';
  Voice.hold=true;
  $('#visit').innerHTML=`<div class="vbox"><b>${esc(L.visit.stepsTitle)}</b><span>${esc(first?L.visit.tut:rnd(L.visit.warnLines))}</span></div>`;
  $('#visit').classList.add('on');
  let n=0; Visit.steps=T.every(state.stage===2?420:560,()=>{ sfx.step(Math.min(1,.35+n++*.09)); });
  const warn=first?7500:(state.stage===2?3200:4500);
  T.after(warn,arrive);
}
function arrive(){
  if(Visit.phase!=='warn') return;
  T.cancel(Visit.steps);
  Visit.phase='in'; document.body.dataset.visit='in';
  sfx.door();
  Visit.openAtArrive=visibleWins();
  $('#visit').innerHTML=`<div class="vbox in"><b>${esc(L.visit.inTitle.replace('%s',Visit.who.toUpperCase()))}</b><span>${esc(L.visit.freeze)}</span></div>${personSVG()}`;
  if(Visit.openAtArrive) T.after(600,()=>{ if(Visit.phase==='in') addSus(Math.min(30,Visit.openAtArrive*10),'visit'); flashVisit(L.visit.sawWin); });
  // сердцебиение, пока человек в комнате
  Visit.steps=T.every(900,()=>sfx.heart());
  const stay=(state.stage===2?8000:6500)+Math.random()*3500;
  Visit.end=T.after(stay,leave);
}
function leave(){
  if(Visit.phase!=='in') return;
  T.cancel(Visit.steps);
  const clean=!Visit.moved && !Visit.openAtArrive;
  Visit.phase=null; delete document.body.dataset.visit;
  sfx.door(.4);
  $('#visit').classList.remove('on'); $('#visit').innerHTML='';
  Voice.hold=false;
  if(clean){ addSus(-8); }
  if(!flag('visitTut')){ setFlag('visitTut'); say(clean?L.visit.tutGood:L.visit.tutBad); }
  else say([rnd(clean?L.visit.goodLines:L.visit.badLines)]);
  scheduleVisit();
}
function flashVisit(t){
  const el=$('#visit .vbox span'); if(!el) return;
  el.textContent=t; el.parentNode.classList.remove('hit'); void el.offsetWidth; el.parentNode.classList.add('hit');
}
// любое действие, пока человек в комнате, заметно
function visitInput(e){
  if(Visit.phase!=='in' || state.paused) return;
  if(e.type==='keydown' && e.key==='Escape') return;           // пауза разрешена
  if(e.type!=='pointermove'){ e.preventDefault(); e.stopPropagation(); }   // клики «не проходят»
  if(T.now-Visit.last<350) return;
  Visit.last=T.now; Visit.moved++;
  addSus(e.type==='pointermove'?4:7,'visit');
  flashVisit(rnd(L.visit.moveLines));
}
['pointermove','pointerdown','click','dblclick','keydown','wheel'].forEach(t=>window.addEventListener(t,visitInput,{capture:true,passive:false}));

/* «Свернуть всё» — кнопка в панели задач и клавиша D */
function hideAll(){
  for(const k in W){ W[k].el.style.display='none'; W[k].task.classList.remove('on'); }
  $('#menu').classList.remove('open');
  sfx.click();
}
$('#hideAll').onclick=e=>{ e.stopPropagation(); hideAll(); };
document.addEventListener('keydown',e=>{
  if(!state.inGame||state.paused||Visit.phase==='in') return;
  if(e.target.closest&&e.target.closest('input,textarea,select')) return;
  if(e.code==='KeyD' && !e.ctrlKey && !e.altKey && !e.metaKey){ e.preventDefault(); hideAll(); }
});

function personSVG(){
  return `<svg class="person" viewBox="0 0 200 600" aria-hidden="true"><defs><linearGradient id="pg" x1="0" x2="1"><stop offset="0" stop-color="#000" stop-opacity="0"/><stop offset=".5" stop-color="#000" stop-opacity=".85"/></linearGradient></defs><path d="M200 600V120q-20-70-70-70q-44 0-52 52q-4 30 16 52q-54 18-64 90l-20 356z" fill="url(#pg)"/></svg>`;
}
function resetVisit(){
  T.cancel(Visit.steps); T.cancel(Visit.next); T.cancel(Visit.end);
  Visit.phase=null; Voice.hold=false; delete document.body.dataset.visit;
  $('#visit').classList.remove('on'); $('#visit').innerHTML='';
}
