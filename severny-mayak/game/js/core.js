/* Ядро: утилиты, игровое время (с паузой), настройки, сохранения, достижения, мост к Steam. */
const $=s=>document.querySelector(s);
const $$=s=>[...document.querySelectorAll(s)];
const QS=new URLSearchParams(location.search);
const TEST=QS.has('test');           // автотест: всё ускорено
const coarse=matchMedia('(pointer:coarse)').matches;
const esc=s=>String(s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));

/* ---------- мост к Electron/Steam (в браузере — заглушка) ---------- */
const Native=window.native||{
  available:false,
  achieve(){}, quit(){ location.reload(); },
  setFullscreen(on){ try{ on?document.documentElement.requestFullscreen():document.exitFullscreen(); }catch(e){} },
  isFullscreen(){ return !!document.fullscreenElement; }
};

/* ---------- хранилище (localStorage может быть недоступен) ---------- */
const Store={
  get(k,def){ try{ const v=localStorage.getItem(k); return v?JSON.parse(v):def; }catch(e){ return def; } },
  set(k,v){ try{ localStorage.setItem(k,JSON.stringify(v)); }catch(e){} },
  del(k){ try{ localStorage.removeItem(k); }catch(e){} }
};
const KEY_SET='sm_settings_v1', KEY_META='sm_meta_v1', KEY_SAVE='sm_save_v1';

const Settings=Object.assign({vol:.8,amb:.8,text:'normal',auto:true,fx:'full',scares:true,lang:null,warned:false},Store.get(KEY_SET,{}));
if(!Settings.lang) Settings.lang=(navigator.language||'ru').toLowerCase().startsWith('ru')?'ru':'en';
if(QS.get('lang')) Settings.lang=QS.get('lang');
function saveSettings(){ Store.set(KEY_SET,Settings); applySettings(); }
function applySettings(){
  document.body.dataset.fx=Settings.fx;
  document.documentElement.lang=Settings.lang;
  if(window.sfx) sfx.setVolume(Settings.vol,Settings.amb);
}

const Meta=Object.assign({endings:{},ach:{},runs:0,offTries:0},Store.get(KEY_META,{}));
function saveMeta(){ Store.set(KEY_META,Meta); }

/* ---------- язык ---------- */
let L=SM_LANG[Settings.lang]||SM_LANG.ru;
function setLang(code){ Settings.lang=code; L=SM_LANG[code]||SM_LANG.ru; saveSettings(); }

/* ---------- состояние прохождения ---------- */
const state={stage:0,f:{},shards:[],goal:'',mins:21*60+40,ending:null,momOnline:false,ng:false,paused:false,inGame:false,sus:0,susMax:0};
function saveGame(){
  if(!state.inGame||state.ending) return;
  Store.set(KEY_SAVE,{v:1,stage:state.stage,f:state.f,shards:state.shards,goal:state.goal,mins:state.mins,ng:state.ng,momOnline:state.momOnline,sus:state.sus,susMax:state.susMax});
}
function loadGame(){ const s=Store.get(KEY_SAVE,null); return s&&s.v===1?s:null; }
function clearSave(){ Store.del(KEY_SAVE); }
function flag(k){ return !!state.f[k]; }
function setFlag(k,v=1){ state.f[k]=v; saveGame(); }

/* ---------- игровое время: всё, что должно вставать на паузу, идёт через T ---------- */
const T={
  scale:TEST?25:1, now:0, jobs:[], id:0, last:performance.now(),
  after(ms,fn){ const j={id:++this.id,at:this.now+ms,fn}; this.jobs.push(j); return j.id; },
  every(ms,fn){ const j={id:++this.id,at:this.now+ms,fn,rep:ms}; this.jobs.push(j); return j.id; },
  sys(ms,fn){ const id=this.every(ms,fn); this.jobs[this.jobs.length-1].sys=true; return id; },   // системные: переживают T.clear()
  cancel(id){ this.jobs=this.jobs.filter(j=>j.id!==id); },
  clear(){ this.jobs=this.jobs.filter(j=>j.sys); },
  tick(t){
    const dt=Math.min(250,t-this.last); this.last=t;
    if(!state.paused) this.now+=dt*this.scale;
    let guard=0;
    while(guard++<500){
      let best=null; for(const j of this.jobs) if(j.at<=this.now && (!best||j.at<best.at)) best=j;
      if(!best) break;
      if(best.rep) best.at+=best.rep; else this.jobs.splice(this.jobs.indexOf(best),1);
      try{ best.fn(); }catch(e){ console.error(e); }
    }
    requestAnimationFrame(t2=>this.tick(t2));
  }
};
requestAnimationFrame(t=>{ T.last=t; T.tick(t); });

/* ---------- всплывашка и достижения ---------- */
let toastT=null;
function toast(head,text){
  const el=$('#toast'); el.innerHTML=`<b>${esc(head)}</b><span>${esc(text)}</span>`; el.classList.add('on');
  clearTimeout(toastT); toastT=setTimeout(()=>el.classList.remove('on'),3800);
}
function achieve(id){
  if(Meta.ach[id]) return;
  Meta.ach[id]=Date.now(); saveMeta();
  Native.achieve(id);
  const a=L.ach[id]; if(a) toast(L.ui.achTitle,a[0]);
}

/* ---------- мелочи ---------- */
const rnd=a=>a[Math.floor(Math.random()*a.length)];
const clockStr=m=>`${Math.floor(m/60)%24}:${String(m%60).padStart(2,'0')}`;
// {{улика}} → подсвечиваемый span (видно во втором прохождении)
const clue=s=>esc(s).replace(/\{\{(.+?)\}\}/g,'<span class="clue">$1</span>');
const plain=s=>String(s).replace(/\{\{|\}\}/g,'');
